extends Control
## Hand-drawn wisteria hanging from the top of the screen. Each cluster sways
## from its top edge, and petals drift down from the blossoms.

@export var sway_degrees := 1.8
@export var sway_seconds := 3.6

@onready var clusters: Array[Node] = $Clusters.get_children()
@onready var petals: CPUParticles2D = $Petals

var _time := 0.0


func _ready() -> void:
	resized.connect(_place_petals)
	_place_petals()


func _process(delta: float) -> void:
	_time += delta
	for i in clusters.size():
		var cluster: Control = clusters[i]
		cluster.pivot_offset = Vector2(cluster.size.x / 2.0, 0.0)
		# Offset each cluster's phase so they don't swing in lockstep.
		cluster.rotation = deg_to_rad(sway_degrees) * sin(_time * TAU / sway_seconds + i * 1.7)


# Petals fall from the lower half of each blossom cluster.
func _place_petals() -> void:
	var points := PackedVector2Array()
	for cluster: Control in clusters:
		var rect := cluster.get_rect()
		for step in 6:
			var t := (step + 0.5) / 6.0
			points.append(Vector2(rect.position.x + rect.size.x * t, rect.position.y + rect.size.y * (0.45 + 0.4 * sin(t * PI))))
	petals.emission_points = points
