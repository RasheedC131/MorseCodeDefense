extends Resource
class_name EnemyData

@export_category("Movement")
@export var speed: float = 100.0

@export_category("Attack")
@export var max_health: int = 2
@export var attack_speed: float = 0.5

@export_category("Sprite")
@export var scale: float = 1.0
#@export var sprite_sheet: SpriteFrames

@export_category("Points")
@export var points: int = 500
