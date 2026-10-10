# MorseCodeDefense

## Computer vision setup (blink tracking)

Blink detection runs in a small Python helper (`morse-code-defense/computer_vision/tracker/blink_tracker.py`)
that Godot starts automatically. One-time setup, from this folder:

```
python -m venv .venv
.venv\Scripts\python -m pip install -r morse-code-defense/computer_vision/tracker/requirements.txt
```

Then open `res://computer_vision/blink_test.tscn` in Godot and press F6. Click **Calibrate**, then
blink: short closures are dots, long ones are dashes. Use the sliders to tune the timing.

To use it in a game scene, add a `BlinkTracker` node and connect its signals
(`eyes_closed`, `eye_opened(duration)`, `telemetry_received`, `score_updated`, ...).
`morse_parser.gd` connects to `telemetry_received` the same way it did with the Eye Detection plugin.

To test the tracker without Godot: `.venv\Scripts\python morse-code-defense/computer_vision/tracker/blink_tracker.py --preview`
