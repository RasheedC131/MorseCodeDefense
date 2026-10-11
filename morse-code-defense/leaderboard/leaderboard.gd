extends Control
## Leaderboard screen: the top scores, with the score just submitted this
## session highlighted. Scores come from the Leaderboard autoload.

const SHOWN := 10
const HEADER_COLOR := Color(0.85, 0.65, 0.25)
const MINE_COLOR := Color(1, 0.85, 0.3)

@onready var rows: GridContainer = $Panel/Box/Rows
@onready var status: Label = $Panel/Box/Status
@onready var placed: Label = $Panel/Box/Placed
@onready var retry_button: Button = $Panel/Box/Buttons/Retry
@onready var play_button: Button = $Panel/Box/Buttons/Play
@onready var menu_button: Button = $Panel/Box/Buttons/MainMenu


func _ready() -> void:
	retry_button.pressed.connect(_load)
	play_button.pressed.connect(Scenes.go_to.bind("game"))
	menu_button.pressed.connect(Scenes.go_to.bind("main_menu"))
	var rank: int = Leaderboard.last_submitted.get("rank", 0)
	placed.text = "You placed #%d" % rank if rank > 0 else ""
	placed.visible = rank > 0
	_load()


func _load() -> void:
	retry_button.hide()
	for child in rows.get_children():
		child.queue_free()
	status.show()
	status.modulate = Color.WHITE
	status.text = "Loading..."
	var result := await Leaderboard.fetch_top(SHOWN)
	if not result.ok:
		status.modulate = Color(1, 0.5, 0.45)
		status.text = result.error
		retry_button.show()
		return
	if result.scores.is_empty():
		status.text = "No scores yet. Be the first!"
		return
	status.hide()
	_add_row("Rank", "Name", "Score", HEADER_COLOR)
	var mine: Dictionary = Leaderboard.last_submitted
	var found_mine := false
	for i in result.scores.size():
		var entry: Dictionary = result.scores[i]
		var is_mine: bool = not found_mine and not mine.is_empty() \
				and str(entry.name) == mine.name and int(entry.score) == mine.score
		found_mine = found_mine or is_mine
		_add_row("#%d" % (i + 1), str(entry.name), str(int(entry.score)), MINE_COLOR if is_mine else Color.WHITE)


func _add_row(rank: String, player_name: String, score: String, color: Color) -> void:
	for cell in [[rank, 70, HORIZONTAL_ALIGNMENT_LEFT], [player_name, 110, HORIZONTAL_ALIGNMENT_CENTER], [score, 120, HORIZONTAL_ALIGNMENT_RIGHT]]:
		var label := Label.new()
		label.text = cell[0]
		label.custom_minimum_size.x = cell[1]
		label.horizontal_alignment = cell[2]
		label.add_theme_font_size_override("font_size", 22)
		label.modulate = color
		rows.add_child(label)
