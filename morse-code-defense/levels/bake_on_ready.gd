extends NavigationRegion2D
## Rebakes the navigation from the tile layers when the level starts, so
## painting or erasing bush tiles in the editor is all it takes to change the
## enemy paths (no need to press "Bake NavigationPolygon" first).


func _ready() -> void:
	bake_navigation_polygon(false)
