# Main menu: building the Figma design in Godot

`ui/main_menu.tscn` is a placeholder layout. It's meant to be rearranged or rebuilt to match
the Figma design. The logic in `main_menu.gd` doesn't depend on the layout, so you can move,
restyle, or replace nodes freely.

## The only rule: keep these node names

The script finds nodes by **unique name** (right-click a node → *Access as Unique Name*,
it shows a `%`). As long as these exist, it works no matter where they are in the tree:

| Unique name | Type | What it does |
|---|---|---|
| `PlayButton` | any Button | starts the game |
| `SettingsButton` | any Button | shows the settings screen |
| `QuitButton` | any Button | quits |
| `Menu` | any Control | the main screen; hidden while settings are open |
| `Settings` | any Control | the settings screen |
| `CalibrateButton` | any Button | opens the blink calibration/test screen |
| `BackButton` | any Button | settings → main screen |
| `SoundCues` *(optional)* | CheckBox / CheckButton | blink sound cues on/off |
| `CalibrationStatus` *(optional)* | Label | "Calibrated ✓" / "Not calibrated yet" |
| `Message` *(optional)* | Label | warnings like "No level yet" |
| `Logo` + `Title` *(optional)* | TextureRect + Label | if `Logo` has a texture, the text title hides |

Buttons can be `TextureButton`s with exported Figma images instead of plain `Button`s.

## Going from Figma to Godot

1. **Screen size:** set Project Settings → Display → Window → Viewport Width/Height to the Figma
   frame size (e.g. 1920×1080) so positions and sizes carry over 1:1. Stretch mode is already
   `canvas_items`, so it scales to any window.
2. **Images:** export from Figma (PNG, or SVG for icons) into `ui/art/`, then drag them into
   `Background`, `Logo`, or TextureButtons.
3. **Colors, fonts, button styles:** put them in `ui/theme/main_theme.tres` rather than on
   individual nodes. Double-click it for the Theme editor with a live preview.
   - Font: set **Default Font** (drop in the .ttf/.otf used in Figma).
   - Buttons: Button → Styles → normal / hover / pressed / focus. Use StyleBoxFlat for flat
     Figma rectangles (bg color, corner radius, border), or StyleBoxTexture for image buttons.
   - Text styles are named so Labels can share them via **Theme Type Variation**:
     `TitleLabel`, `SubtitleLabel`, `HeadingLabel`, `MutedLabel`, `MessageLabel`.
4. **Layout:** containers (VBox/HBox/Margin) are easiest because they keep working at other
   window sizes, but placing nodes freely with anchors is fine too.
