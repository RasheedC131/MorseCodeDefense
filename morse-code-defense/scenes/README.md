# Scenes

All screen changes go through the `Scenes` autoload. It fades to black, swaps the scene, and fades back in.

## Adding your scene (2 steps)

1. **Register it** in [`scene_library.gd`](scene_library.gd) with a name and its path:

   ```gdscript
   const SCENES := {
       "main_menu": "res://Main Menu/MainMenu.tscn",
       "game": "res://Levels/level_1.tscn",   # ← fill in the path
       ...
   }
   ```

   To get the path, right-click the scene in Godot's FileSystem panel and choose **Copy Path**.

2. **Go to it** from any script:

   ```gdscript
   Scenes.go_to("game")
   ```

Names already listed: `main_menu`, `game` (where the menu's Play button goes), `calibration`, `sound_test`. Entries left as `""` are placeholders. Going to one prints a warning and stays on the current screen.

## Buttons on the main menu

The menu buttons use `Main Menu/play.gd`, which has a **Go To Scene** field in the Inspector. Type a scene name there and the button goes to that scene. Leave it empty and the button opens Settings. Play is already set to `game`.

## API

```gdscript
Scenes.go_to("calibration")   # switch scenes with a fade
Scenes.go_back()              # return to the previous scene (e.g. a Back button)
Scenes.reload()               # restart the current scene (e.g. after losing)
Scenes.current                # name of the scene that's showing
Scenes.scene_changed          # signal(scene_name), emitted after each switch
```

Clicks are blocked during the fade, so double-clicking a button won't switch twice. Switching also unpauses the game.
