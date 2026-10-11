extends Node2D
class_name Level
## A level built from simple shapes, ready for an artist to paint over.
##
## - Polygon2Ds in the "walkable" group are ground agents can walk on.
## - Polygon2Ds in the "obstacle" group block them (walls, crystals).
## Navigation is baked from those shapes when the level starts, so moving a
## shape in the editor is all it takes to change the paths.
##
## Set `art` to a painted picture of the level to show it instead of the
## placeholder shapes (templates to paint over are in levels/templates/).

@export var art: Texture2D
@export var agent_radius := 16.0
## When off, dying shows "Thanks for playing" with Restart instead of asking
## for a leaderboard name (used by the seeded maps).
@export var use_leaderboard := true

@onready var navigation: NavigationRegion2D = $Navigation
@onready var placeholder: Node2D = $Placeholder
@onready var art_sprite: Sprite2D = $Art


func _ready() -> void:
	if art:
		art_sprite.texture = art
		art_sprite.show()
		placeholder.hide()
	navigation.navigation_polygon = bake()


func bake() -> NavigationPolygon:
	var layout := layout()
	var source := NavigationMeshSourceGeometryData2D.new()
	for outline in layout.ground:
		source.add_traversable_outline(outline)
	for outline in layout.blocked:
		source.add_obstruction_outline(outline)
	var nav := NavigationPolygon.new()
	nav.agent_radius = agent_radius
	NavigationServer2D.bake_from_source_geometry_data(nav, source)
	return nav


## Ground outlines (walkable shapes joined together) and blocked outlines
## (obstacles, plus rock fully enclosed by paths), in level coordinates.
## Works before the level is in the tree, so it can be used in _enter_tree.
func layout() -> Dictionary:
	var walkable: Array[PackedVector2Array] = []
	var blocked: Array[PackedVector2Array] = []
	for poly: Polygon2D in find_children("*", "Polygon2D", true, false):
		if poly.is_in_group("walkable"):
			walkable.append(_in_level(poly))
		elif poly.is_in_group("obstacle"):
			blocked.append(_in_level(poly))
	var merged := _merge(walkable)
	blocked.append_array(merged.holes)
	return {"ground": merged.outer, "blocked": blocked}


func _in_level(poly: Polygon2D) -> PackedVector2Array:
	var xf := Transform2D.IDENTITY
	var node: Node = poly
	while node != self and node is Node2D:
		xf = (node as Node2D).transform * xf
		node = node.get_parent()
	return xf * poly.polygon


# Overlapping walkable shapes have to be joined into one outline, or the baked
# navigation treats each piece as its own island. Rock fully enclosed by
# paths comes back as holes, which are baked as obstructions.
func _merge(shapes: Array[PackedVector2Array]) -> Dictionary:
	var outer: Array[PackedVector2Array] = []
	var holes: Array[PackedVector2Array] = []
	for shape in shapes:
		var current := shape
		var i := 0
		while i < outer.size():
			var result := Geometry2D.merge_polygons(outer[i], current)
			var outlines := result.filter(func(p): return not Geometry2D.is_polygon_clockwise(p))
			if outlines.size() == 1:
				current = outlines[0]
				for p in result:
					if Geometry2D.is_polygon_clockwise(p):
						holes.append(p)
				outer.remove_at(i)
				i = 0
			else:
				i += 1
		outer.append(current)
	# A hole may have been filled in by a shape merged later.
	var open_holes: Array[PackedVector2Array] = []
	for hole in holes:
		var pieces: Array[PackedVector2Array] = [hole]
		for shape in shapes:
			var remaining: Array[PackedVector2Array] = []
			for piece in pieces:
				remaining.append_array(Geometry2D.clip_polygons(piece, shape))
			pieces = remaining
		open_holes.append_array(pieces)
	return {"outer": outer, "holes": open_holes}


## True when every enemy spawn can walk to Lenny. Lays a grid over the level
## and flood-fills open ground from Lenny; obstacles are grown by the agent
## radius so gaps too narrow to walk through count as closed.
func spawns_reach_lenny(bounds: Rect2) -> bool:
	const CELL := 12.0
	var lenny: Vector2 = $Agents/Player.position
	var layout := layout()
	var blocked: Array[PackedVector2Array] = []
	for outline in layout.blocked:
		blocked.append_array(Geometry2D.offset_polygon(outline, agent_radius))
	var open := {}
	var is_open := func(cell: Vector2i) -> bool:
		if not open.has(cell):
			var point := (Vector2(cell) + Vector2(0.5, 0.5)) * CELL
			var inside: bool = layout.ground.any(func(o): return Geometry2D.is_point_in_polygon(point, o))
			open[cell] = inside and not blocked.any(func(o): return Geometry2D.is_point_in_polygon(point, o))
		return open[cell]
	var start := Vector2i(lenny / CELL)
	if not is_open.call(start):
		return false
	var limit := Vector2i(bounds.end / CELL)
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if next.x >= 0 and next.y >= 0 and next.x <= limit.x and next.y <= limit.y \
					and not reached.has(next) and is_open.call(next):
				reached[next] = true
				queue.append(next)
	for marker in spawn_markers():
		var cell := Vector2i(marker.position / CELL)
		var near := false
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				near = near or reached.has(cell + Vector2i(dx, dy))
		if not near:
			return false
	return true


func spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child in $EnemySpawner.get_children():
		if child is Marker2D:
			markers.append(child)
	return markers
