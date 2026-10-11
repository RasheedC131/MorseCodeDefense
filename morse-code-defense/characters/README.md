# Character sprites

Every character (player, ally, enemy, and any new ones) has a **Sprite** node using `character_sprite.gd`. It plays the right animation on its own:

| Animation | When it plays | Loops? |
| --- | --- | --- |
| `idle` | standing still | yes |
| `walk` | moving (and it flips to face the way it's going) | yes |
| `attack` | when code calls `play_action("attack")` | no |
| `hurt` | when the character's **Health** loses a heart | no |
| `die` | when Health runs out, or when code calls `die()` | no |

A character only needs the animations it uses. Missing ones are skipped (no `walk` → it just stays on `idle`). Spell the names exactly like this, lowercase.

Until a character has art, it shows the Godot icon (tinted green for allies, red for enemies) so the game still works.

`example/` is a finished example to copy: a sprite sheet and its Sprite Frames with all five animations.

## Adding a character's sprite

### 1. Add the art
Make a folder for the character, e.g. `characters/enemy/`, and drop the art in:
- **one sprite sheet** (all frames in a grid, like `example/example_sheet.png`), or
- **one image per frame** (`walk_1.png`, `walk_2.png`, ...).

Any size works; the game scales it (see step 4).

### 2. Make the Sprite Frames
1. In the **FileSystem** panel, right-click the character's folder → **Create New → Resource...** → pick **SpriteFrames** → save it as e.g. `enemy_frames.tres`.
2. Double-click it. The **SpriteFrames** panel opens at the bottom of the editor.
3. Rename the `default` animation to `idle` (double-click its name).
4. Click **Add Animation** (the page icon) for each of the others you have: `walk`, `attack`, `hurt`, `die`.
5. For each animation, select it, then add its frames:
   - from a sprite sheet: click **Add frames from Sprite Sheet** (the grid icon), pick the sheet, set how many columns and rows it has, click that animation's frames in order, then **Add Frames**;
   - from separate images: drag the images from the FileSystem panel into the frames area.
6. Set the speed (**FPS**) for each animation, and turn **Loop** off for `attack`, `hurt` and `die`. (The game also forces those three to play once.)

### 3. Give it to the character
1. Open the character's scene:
   - player: `Agents/TestLevel/player.tscn`
   - ally: `Agents/Ally/ally.tscn`
   - enemy: `Agents/Enemy/enemy.tscn`
2. Select the **Sprite** node.
3. Drag your `.tres` from the FileSystem panel onto **Sprite Frames** in the Inspector.

The tint goes away automatically once real art is assigned.

### 4. Adjust it in the Inspector (Sprite node)
- **Display Height**: how tall the character is drawn. Your frames are scaled to this, whatever size you drew them. 128 matches the current placeholder.
- **Art Faces Left**: turn on if your art faces left (the default assumes right).
- **Pixel Art**: on = crisp pixels; turn off for smooth, painted art.

### 5. Check it
Open `characters/sprite_preview.tscn` and press **F6**. Every Sprite Frames under `characters/` appears with a button per animation and a flip button.

## A new kind of character
For a new enemy type (or any new character scene): add an **AnimatedSprite2D** child called **Sprite**, attach `characters/character_sprite.gd`, and give it its Sprite Frames as above. If the character has a **Health** child, `hurt` and `die` play automatically.

## From code
```gdscript
$Sprite.play_action("attack")   # one-off, then back to idle/walk
$Sprite.die()                   # plays "die" once and stops idle/walk
$Sprite.death_finished.connect(queue_free)   # e.g. remove an enemy after its death animation
```
