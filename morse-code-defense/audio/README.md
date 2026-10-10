# Audio

All game audio goes through the `Audio` autoload. You don't need to add any nodes to your scenes.

## Adding a sound (3 steps)

1. **Drop the file** in the matching folder:

   | Folder | For |
   | --- | --- |
   | `sfx/player/` | player damage, death, abilities |
   | `sfx/enemy/` | enemy spawn, hit, death |
   | `sfx/ally/` | sending allies, ally actions |
   | `sfx/ui/` | menu clicks, Morse input feedback |
   | `music/` | background music (use `.ogg`) |

   Make a new folder if none of these fit. Use `.wav` for short effects and `.ogg` for music.

2. **Register it** in [`sound_library.gd`](sound_library.gd) with a name and a path:

   ```gdscript
   "tower_built": {
       "file": "res://audio/sfx/player/tower_built.wav",
   },
   ```

   Optional settings:

   ```gdscript
   "enemy_hit": {
       "file": [                                  # pick one at random each time
           "res://audio/sfx/enemy/hit_1.wav",
           "res://audio/sfx/enemy/hit_2.wav",
       ],
       "volume_db": -4.0,                         # quieter (0 = as recorded)
       "pitch_range": 0.1,                        # random 0.9x to 1.1x pitch
       "bus": "UI",                               # "SFX" (default) or "UI"
   },
   ```

3. **Play it** from gameplay code:

   ```gdscript
   Audio.play("tower_built")
   ```

You can do step 3 before the file exists. Until it does, the game prints a warning once and stays silent. That way a programmer can hook up `Audio.play("enemy_died")` while someone else is still making the sound.

## API

```gdscript
Audio.play("player_damaged")                       # plain sound effect
Audio.play_at("enemy_died", enemy.global_position) # 2D: pans and fades with distance
Audio.play_music("battle")                         # loops, crossfades from the current track
Audio.stop_music()
Audio.set_volume("SFX", 0.5)                       # 0.0 to 1.0, for a settings menu
Audio.get_volume("Music")
```

Volume buses: `Master`, `Music`, `SFX`, `UI`. They're created automatically if they're not in the project's bus layout.

## Where to hook up sounds

Call `Audio.play(...)` at the moment the event happens, usually in the same function:

```gdscript
func take_damage(amount: int) -> void:
    health -= amount
    Audio.play("player_damaged")
```
