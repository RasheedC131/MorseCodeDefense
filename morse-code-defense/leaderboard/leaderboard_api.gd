extends Node
## Leaderboard client, registered as the "Leaderboard" autoload.
##
##   var top = await Leaderboard.fetch_top(10)
##   # {"ok": true, "scores": [{"name": "ABC", "score": 1200}, ...]}  (highest first)
##   var saved = await Leaderboard.submit("ABC", 1200)
##   # {"ok": true, "rank": 4}
##   # Either one returns {"ok": false, "error": "message to show the player"} on failure.
##
## Talks to the leaderboard server described in leaderboard/API.md. While
## BASE_URL is empty (no server yet), scores are kept in a local file instead,
## so the screens work in the meantime. Local scores only live on this computer.

const BASE_URL := "https://uahdsjltbcatjcflmhjw.supabase.co/functions/v1/api" # the server's address, e.g. "https://example.com/api"; empty = local file
const TIMEOUT := 10.0 # seconds before giving up on the server
const LOCAL_FILE := "user://leaderboard.json"
const NAME_LENGTH := 3

## The server address in use (starts as BASE_URL; tests can point it elsewhere).
var base_url := BASE_URL
## The last score submitted this session, so the leaderboard can highlight it.
var last_submitted := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # requests must finish while the game is paused


## Exactly 3 letters, numbers or symbols (printable ASCII, no spaces).
static func is_valid_name(player_name: String) -> bool:
	if player_name.length() != NAME_LENGTH:
		return false
	for character in player_name:
		var code := character.unicode_at(0)
		if code < 33 or code > 126:
			return false
	return true


func fetch_top(limit := 10) -> Dictionary:
	if base_url == "":
		return _local_top(limit)
	var reply := await _request(HTTPClient.METHOD_GET, "/scores?limit=%d" % limit)
	if not reply.ok:
		return reply
	var scores = reply.body.get("scores") if reply.body is Dictionary else null
	if not scores is Array:
		return _fail("The leaderboard server sent an unexpected reply.")
	return {"ok": true, "scores": scores}


func submit(player_name: String, score: int) -> Dictionary:
	if not is_valid_name(player_name):
		return _fail("Names must be exactly 3 letters, numbers or symbols.")
	var result: Dictionary
	if base_url == "":
		result = _local_submit(player_name, score)
	else:
		var reply := await _request(HTTPClient.METHOD_POST, "/scores", {"name": player_name, "score": score})
		if not reply.ok:
			return reply
		var rank = reply.body.get("rank", 0) if reply.body is Dictionary else 0
		result = {"ok": true, "rank": int(rank)}
	last_submitted = {"name": player_name, "score": score, "rank": result.rank}
	return result


func _request(method: int, path: String, payload = null) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	add_child(http)
	var headers := PackedStringArray(["Accept: application/json"])
	var body := ""
	if payload != null:
		headers.append("Content-Type: application/json")
		body = JSON.stringify(payload)
	if http.request(base_url + path, headers, method, body) != OK:
		http.queue_free()
		return _fail("Couldn't reach the leaderboard server.")
	var response: Array = await http.request_completed # [result, status code, headers, body]
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS:
		return _fail("Couldn't reach the leaderboard server.")
	var text: String = response[3].get_string_from_utf8()
	var parsed = JSON.parse_string(text) if text != "" else {}
	var status: int = response[1]
	if status < 200 or status >= 300:
		var message = parsed.get("error") if parsed is Dictionary else null
		return _fail(message if message is String else "The leaderboard server returned an error (%d)." % status)
	return {"ok": true, "body": parsed}


func _fail(message: String) -> Dictionary:
	return {"ok": false, "error": message}


# --- Local file, used until the server exists ---

func _local_load() -> Array:
	if not FileAccess.file_exists(LOCAL_FILE):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(LOCAL_FILE))
	return data if data is Array else []


func _local_top(limit: int) -> Dictionary:
	var scores := _local_load()
	scores.sort_custom(func(a, b): return a.score > b.score)
	return {"ok": true, "scores": scores.slice(0, limit)}


func _local_submit(player_name: String, score: int) -> Dictionary:
	var scores := _local_load()
	var rank := 1 + scores.filter(func(entry): return entry.score > score).size()
	scores.append({"name": player_name, "score": score})
	var file := FileAccess.open(LOCAL_FILE, FileAccess.WRITE)
	if file == null:
		return _fail("Couldn't save the score on this computer.")
	file.store_string(JSON.stringify(scores))
	return {"ok": true, "rank": rank}
