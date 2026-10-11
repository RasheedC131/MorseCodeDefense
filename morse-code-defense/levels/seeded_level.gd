extends Level
class_name SeededLevel
## A big map whose tunnels are generated from a seed. Enemies enter from 3 or
## 4 sides of the map and each tunnel winds its way to Lenny's clearing in the
## middle. The same seed always builds the same map.
##
## Tunnels are built before the rest of the level is ready, so the enemy
## spawner and the navigation bake see the finished map.

## 0 picks a new seed each run; it is printed so a good map can be kept.
@export var map_seed := 0
@export_range(3, 4) var spawn_count := 4
@export var map_size := Vector2(2048, 1152)
## Number of turns each tunnel takes on its way to Lenny.
@export_range(1, 5) var bends := 3
@export var tunnel_width_min := 84.0
@export var tunnel_width_max := 112.0
@export var clearing_radius := 190.0

@export_group("Colours")
@export var rock_color := Color(0.15, 0.1, 0.23)
@export var tunnel_color := Color(0.13, 0.26, 0.28)
@export var clearing_color := Color(0.16, 0.31, 0.32)

## Set before reloading to rebuild a specific map once (Restart uses it).
static var replay_seed := 0
## The seed this map was built from.
var current_seed := 0

var _built := false


func _enter_tree() -> void:
	if _built:
		return
	_built = true
	var base_seed := map_seed if map_seed != 0 else randi()
	if replay_seed != 0:
		base_seed = replay_seed
		replay_seed = 0
	for attempt in 10:
		var this_seed := base_seed + attempt
		_build(this_seed)
		if spawns_reach_lenny(Rect2(Vector2.ZERO, map_size)):
			current_seed = this_seed
			print("Map seed: ", this_seed)
			return
		push_warning("Map seed %d left a spawn cut off; trying the next one." % this_seed)
	push_error("No working map found from seed %d." % base_seed)


func _build(this_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = this_seed
	var ground: Node2D = $Placeholder/Ground
	for child in ground.get_children():
		ground.remove_child(child)
		child.free()
	$Placeholder/Rock.size = map_size
	$Placeholder/Rock.color = rock_color

	var lenny := (map_size / 2.0).round()
	$Agents/Player.position = lenny
	$Camera.position = lenny
	$Camera.limit_right = int(map_size.x)
	$Camera.limit_bottom = int(map_size.y)

	_add_ground(ground, _blob(lenny, clearing_radius * 1.15, clearing_radius * 0.85, rng), tunnel_color)

	var sides := ["left", "top", "right", "bottom"]
	_shuffle(sides, rng)
	sides = sides.slice(0, spawn_count)
	var markers := $EnemySpawner.get_children().filter(func(n): return n is Marker2D)
	for i in markers.size():
		if i >= sides.size():
			$EnemySpawner.remove_child(markers[i]) # fewer spawns than markers
			markers[i].free()
			continue
		var tunnel := _tunnel_points(sides[i], lenny, rng)
		markers[i].position = tunnel[1]
		var width := rng.randf_range(tunnel_width_min, tunnel_width_max)
		for j in tunnel.size() - 1:
			_add_ground(ground, _segment(tunnel[j], tunnel[j + 1], width), tunnel_color)
	# Lighter ground around Lenny, drawn over the tunnel ends.
	_add_ground(ground, _blob(lenny, clearing_radius * 0.8, clearing_radius * 0.6, rng), clearing_color, false)


# Edge -> a few bends -> the clearing. Each tunnel only ever moves forward
# toward Lenny along its main axis and wanders sideways at each bend, so it
# never doubles back on itself. Every leg is horizontal or vertical, like the
# hand-drawn maps.
func _tunnel_points(side: String, lenny: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	# Work in (forward, sideways) coordinates, then map back to x/y.
	var vertical := side == "top" or side == "bottom"
	var flip := side == "right" or side == "bottom"
	var length := map_size.y if vertical else map_size.x
	var width := map_size.x if vertical else map_size.y
	var to_xy := func(forward: float, sideways: float) -> Vector2:
		var f := length - forward if flip else forward
		return Vector2(sideways, f) if vertical else Vector2(f, sideways)
	var goal_forward := length / 2.0 - clearing_radius * 0.6
	var goal_sideways := width / 2.0
	# How far a tunnel may drift sideways per bend; small enough that tunnels
	# from neighbouring sides keep to their own part of the map.
	var wander := minf(width * 0.18, length * 0.2)
	var sideways := rng.randf_range(width * 0.25, width * 0.75)
	var points := PackedVector2Array([to_xy.call(-60.0, sideways), to_xy.call(28.0, sideways)])
	var forward := 28.0
	for k in bends:
		var next_forward := lerpf(28.0, goal_forward, (k + 1.0) / (bends + 1.0)) + rng.randf_range(-30.0, 30.0)
		var next_sideways := clampf(sideways + rng.randf_range(-wander, wander), width * 0.15, width * 0.85)
		points.append(to_xy.call(next_forward, sideways))
		points.append(to_xy.call(next_forward, next_sideways))
		forward = next_forward
		sideways = next_sideways
	points.append(to_xy.call(goal_forward, sideways))
	points.append(to_xy.call(goal_forward, goal_sideways))
	points.append(lenny)
	return points


func _segment(a: Vector2, b: Vector2, width: float) -> PackedVector2Array:
	var half := width / 2.0
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(half, half)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(half, half)
	return PackedVector2Array([lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y)])


func _blob(center: Vector2, rx: float, ry: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	var phase := rng.randf() * TAU
	for i in 28:
		var a := TAU * i / 28.0
		var k := 1.0 + 0.07 * sin(a * 3.0 + phase) * cos(a * 2.0 + phase * 1.7)
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry) * k)
	return points


func _add_ground(parent: Node2D, outline: PackedVector2Array, color: Color, walkable := true) -> void:
	var poly := Polygon2D.new()
	poly.polygon = outline
	poly.color = color
	if walkable:
		poly.add_to_group("walkable")
	parent.add_child(poly)


# RandomNumberGenerator-driven shuffle, so the seed decides which sides spawn.
func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap = items[i]
		items[i] = items[j]
		items[j] = swap
