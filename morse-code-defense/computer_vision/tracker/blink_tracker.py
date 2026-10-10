"""Webcam blink tracker for Morse Code Defense.

Runs MediaPipe Face Landmarker on the webcam and prints one line per event to
stdout, in the same format as the Eye Detection plugin so Godot scripts written
for it keep working:

    TYPE<SEP>CODE<SEP>DETAIL<SEP>EXTRA

Codes:
    STR   started (detail = settings)
    S     per-frame score (detail = closure 0..1, extra = "left,right,ear,face")
    CS    closing started (score just crossed the close threshold; may still turn into NB)
    EC    eyes closed (only sent once the eyes stayed closed for --min-blink seconds)
    EO    eyes opened after an EC
    D     duration of that closure in seconds (extra), always follows EO
    NB    natural blink, too short to count (extra = duration), no EC/EO/D sent
    NFF   no face found (at most once per second)
    CAL   calibration finished (detail = "open"/"closed", extra = "close_th,open_th")
    TH    thresholds changed (extra = "close_th,open_th")
    P     paused state changed (extra = True/False)
    STOP  shutting down
    ERROR something went wrong (detail = message)

Commands read from stdin (one per line):
    PAUSE | RESUME | STOP
    CALIBRATE OPEN | CALIBRATE CLOSED     sample for --calib-seconds
    THRESHOLDS <close> <open>             set thresholds by hand
    MIN_BLINK <seconds>                   shortest closure that counts
    PREVIEW ON | PREVIEW OFF              debug window with landmarks

Run by hand for testing:
    python blink_tracker.py --preview
"""

import argparse
import os
import sys
import threading
import time
from pathlib import Path

# Quiet MediaPipe's C++ logging; it goes to stderr, which nobody reads.
os.environ.setdefault("GLOG_minloglevel", "2")
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

SEP = "<<<SEPARATOR>>>"
_print_lock = threading.Lock()


def emit(message_type: str, code: str, detail: str = "", extra: str = "") -> None:
    with _print_lock:
        print(f"{message_type}{SEP}{code}{SEP}{detail}{SEP}{extra}", flush=True)


try:
    import cv2
    import mediapipe as mp
    import numpy as np
    from mediapipe.tasks import python as mp_python
    from mediapipe.tasks.python import vision
except ImportError as e:
    emit("ERROR", "IE", "Import error, run: pip install -r requirements.txt", str(e))
    sys.exit(1)


# Six landmarks per eye: corner, top, top, corner, bottom, bottom.
LEFT_EYE = [33, 160, 158, 133, 153, 144]
RIGHT_EYE = [362, 385, 387, 263, 373, 380]


def runtime_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(getattr(sys, "_MEIPASS", Path(sys.executable).parent))
    return Path(__file__).resolve().parent


def eye_aspect_ratio(face, idx: list[int], w: int, h: int) -> float:
    """Classic EAR using real 2D distances in pixels, so head tilt doesn't skew it."""
    p = [np.array([face[i].x * w, face[i].y * h]) for i in idx]
    vertical = np.linalg.norm(p[1] - p[5]) + np.linalg.norm(p[2] - p[4])
    horizontal = np.linalg.norm(p[0] - p[3])
    return float(vertical / (2.0 * horizontal)) if horizontal > 0 else 0.0


class Tracker:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.running = True
        self.paused = False
        self.preview = args.preview

        self.close_th = args.close
        self.open_th = args.open
        self.min_blink = args.min_blink

        self.smoothed: float | None = None
        self.closed = False          # past the close threshold right now
        self.reported = False        # EC was sent for the current closure
        self.closed_since = 0.0

        self.calib_target: str | None = None
        self.calib_until = 0.0
        self.calib_samples: list[float] = []
        self.calib_open: float | None = None
        self.calib_closed: float | None = None

        self.last_nff = 0.0

    # ---- stdin commands -------------------------------------------------

    def listen_stdin(self) -> None:
        for line in sys.stdin:
            parts = line.strip().split()
            if not parts:
                continue
            cmd = parts[0].upper()
            try:
                if cmd == "PAUSE":
                    self.set_paused(True)
                elif cmd == "RESUME":
                    self.set_paused(False)
                elif cmd == "STOP":
                    break
                elif cmd == "CALIBRATE" and len(parts) > 1 and parts[1].lower() in ("open", "closed"):
                    self.calib_target = parts[1].lower()
                    self.calib_samples = []
                    self.calib_until = time.monotonic() + self.args.calib_seconds
                elif cmd == "THRESHOLDS" and len(parts) == 3:
                    self.set_thresholds(float(parts[1]), float(parts[2]))
                elif cmd == "MIN_BLINK" and len(parts) == 2:
                    self.min_blink = float(parts[1])
                elif cmd == "PREVIEW" and len(parts) == 2:
                    self.preview = parts[1].upper() == "ON"
                else:
                    emit("ERROR", "UC", "Unknown command", line.strip())
            except ValueError:
                emit("ERROR", "UC", "Bad command arguments", line.strip())
        # STOP or Godot closed the pipe.
        self.running = False

    def set_paused(self, value: bool) -> None:
        self.paused = value
        emit("GAME", "P", "Paused", str(value))

    def set_thresholds(self, close_th: float, open_th: float) -> None:
        # Hysteresis needs open below close; keep a small gap.
        self.close_th = close_th
        self.open_th = min(open_th, close_th - 0.02)
        emit("GAME", "TH", "Thresholds", f"{self.close_th:.3f},{self.open_th:.3f}")

    # ---- calibration ----------------------------------------------------

    def feed_calibration(self, score: float, now: float) -> None:
        if self.calib_target is None:
            return
        self.calib_samples.append(score)
        if now < self.calib_until:
            return
        target, samples = self.calib_target, self.calib_samples
        self.calib_target = None
        if len(samples) < 5:
            emit("ERROR", "CALF", "Calibration failed, face not visible", target)
            return
        level = float(np.median(samples))
        if target == "open":
            self.calib_open = level
        else:
            self.calib_closed = level

        if self.calib_open is not None and self.calib_closed is not None:
            span = self.calib_closed - self.calib_open
            if span < 0.1:
                emit("ERROR", "CALF", "Open and closed look the same, try again", f"{span:.3f}")
            else:
                self.close_th = self.calib_open + 0.55 * span
                self.open_th = self.calib_open + 0.35 * span
        emit("GAME", "CAL", target, f"{self.close_th:.3f},{self.open_th:.3f}")

    # ---- blink state machine --------------------------------------------

    def update_state(self, score: float, now: float) -> None:
        if not self.closed and score >= self.close_th:
            self.closed = True
            self.reported = False
            self.closed_since = now
            emit("GAME", "CS", "Closing started")
        elif self.closed and score <= self.open_th:
            self.closed = False
            duration = now - self.closed_since
            if self.reported:
                emit("GAME", "EO", "Eyes opened")
                emit("GAME", "D", "Duration", f"{duration:.3f}")
            else:
                emit("GAME", "NB", "Natural blink ignored", f"{duration:.3f}")

        # Only announce a closure once it is long enough to be deliberate.
        if self.closed and not self.reported and now - self.closed_since >= self.min_blink:
            self.reported = True
            emit("GAME", "EC", "Eyes closed")

    # ---- main loop ------------------------------------------------------

    def open_camera(self):
        backend = cv2.CAP_DSHOW if sys.platform == "win32" else cv2.CAP_ANY
        for _ in range(5):
            cap = cv2.VideoCapture(self.args.camera, backend)
            if cap.isOpened():
                cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                return cap
            time.sleep(1.0)
        return None

    def run(self) -> None:
        model = Path(self.args.model) if self.args.model else runtime_dir() / "face_landmarker.task"
        try:
            landmarker = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
                base_options=mp_python.BaseOptions(model_asset_path=str(model)),
                running_mode=vision.RunningMode.VIDEO,
                num_faces=1,
                output_face_blendshapes=True,
            ))
        except Exception as e:
            emit("ERROR", "MLC", "Model loading failed", str(e))
            return

        cap = self.open_camera()
        if cap is None:
            emit("ERROR", "CNF", "Can't open camera", str(self.args.camera))
            return

        emit("GAME", "STR", "Started",
             f"close={self.close_th},open={self.open_th},min_blink={self.min_blink}")
        threading.Thread(target=self.listen_stdin, daemon=True).start()

        start = time.monotonic()
        last_ts = -1
        try:
            while self.running:
                if self.paused:
                    time.sleep(0.1)
                    continue
                ok, frame = cap.read()
                if not ok:
                    emit("ERROR", "CRF", "Camera frame read failed")
                    time.sleep(0.5)
                    continue

                now = time.monotonic()
                ts = int((now - start) * 1000)
                if ts <= last_ts:  # VIDEO mode needs strictly increasing timestamps
                    ts = last_ts + 1
                last_ts = ts

                h, w = frame.shape[:2]
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                result = landmarker.detect_for_video(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb), ts)

                if not result.face_landmarks:
                    # Freeze the blink state; it resumes when the face comes back.
                    if now - self.last_nff >= 1.0:
                        emit("ERROR", "NFF", "No face found")
                        self.last_nff = now
                    if self.preview:
                        self.show_preview(frame, None, 0.0)
                    continue

                face = result.face_landmarks[0]
                shapes = {c.category_name: c.score for c in result.face_blendshapes[0]}
                left = shapes.get("eyeBlinkLeft", 0.0)
                right = shapes.get("eyeBlinkRight", 0.0)
                ear = (eye_aspect_ratio(face, LEFT_EYE, w, h) + eye_aspect_ratio(face, RIGHT_EYE, w, h)) / 2

                # Both eyes together: winks and squints on one side don't count.
                raw = (left + right) / 2
                a = self.args.smoothing
                self.smoothed = raw if self.smoothed is None else a * raw + (1 - a) * self.smoothed
                score = self.smoothed

                self.feed_calibration(score, now)
                self.update_state(score, now)
                emit("GAME", "S", f"{score:.3f}", f"{left:.3f},{right:.3f},{ear:.3f},1")

                if self.preview:
                    self.show_preview(frame, face, score)
                elif self.args.preview_was_open:
                    cv2.destroyAllWindows()
                    self.args.preview_was_open = False
        finally:
            emit("GAME", "STOP", "Stopping")
            cap.release()
            cv2.destroyAllWindows()

    def show_preview(self, frame, face, score: float) -> None:
        self.args.preview_was_open = True
        frame = cv2.flip(frame, 1)
        h, w = frame.shape[:2]
        if face is not None:
            for i in LEFT_EYE + RIGHT_EYE:
                cv2.circle(frame, (int((1 - face[i].x) * w), int(face[i].y * h)), 2, (0, 255, 0), -1)
        # Score bar with both thresholds marked.
        bar_h = int(score * (h - 40))
        color = (0, 0, 255) if self.closed else (0, 200, 0)
        cv2.rectangle(frame, (10, h - 20 - bar_h), (40, h - 20), color, -1)
        for th, c in ((self.close_th, (0, 0, 255)), (self.open_th, (0, 200, 255))):
            y = h - 20 - int(th * (h - 40))
            cv2.line(frame, (5, y), (45, y), c, 2)
        cv2.putText(frame, f"{score:.2f} {'CLOSED' if self.closed else 'open'}", (55, h - 20),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        cv2.imshow("Blink tracker", frame)
        if cv2.waitKey(1) & 0xFF == 27:  # Esc closes the window
            self.preview = False


def main() -> None:
    global SEP
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--camera", type=int, default=0)
    p.add_argument("--model", default="")
    p.add_argument("--close", type=float, default=0.55, help="score at or above this means closed")
    p.add_argument("--open", type=float, default=0.40, help="score at or below this means open again")
    p.add_argument("--min-blink", type=float, default=0.12, help="seconds; shorter closures are natural blinks")
    p.add_argument("--smoothing", type=float, default=0.6, help="EMA weight of the newest frame (1 = off)")
    p.add_argument("--calib-seconds", type=float, default=2.0)
    p.add_argument("--preview", action="store_true", help="show a debug window")
    p.add_argument("--sep", default=SEP)
    args = p.parse_args()
    args.preview_was_open = False
    SEP = args.sep

    tracker = Tracker(args)
    if args.open >= args.close:
        tracker.set_thresholds(args.close, args.open)
    tracker.run()


if __name__ == "__main__":
    main()
