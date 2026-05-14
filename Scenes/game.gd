extends Node2D

@export var picked_map : TileMapLayer
@onready var cam: Camera2D = $Players/Player/Cam

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if picked_map:
		var used := picked_map.get_used_rect()
		var tile_size := picked_map.tile_set.tile_size
		
		cam.limit_left = used.position.x * tile_size.x + int(picked_map.global_position.x)
		cam.limit_right = used.end.x * tile_size.x + int(picked_map.global_position.x)
		cam.limit_top = used.position.y * tile_size.y + int(picked_map.global_position.y)
		cam.limit_bottom = used.end.y * tile_size.y + int(picked_map.global_position.y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
