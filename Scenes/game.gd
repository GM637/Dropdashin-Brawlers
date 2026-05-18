extends Node2D

class_name Game

@export var picked_map : TileMapLayer :
	set(pm) :
		picked_map = pm
		setup_map()
@onready var cam: Camera2D = $Players/Player/Cam
@onready var local_player: Player = $Players/Player

@onready var options: ActionButton = $GUI/C/Options
@onready var host: ActionButton = $GUI/C/Host

@onready var master: HSlider = $GUI/C/Options/Panel/Master
@onready var music: HSlider = $GUI/C/Options/Panel/Music
@onready var sfx: HSlider = $GUI/C/Options/Panel/SFX

@onready var leave: ActionButton = %Leave

@onready var add_bot: ActionButton = $GUI/C/Host/Panel/AddBot
@onready var skip: ActionButton = $GUI/C/Host/Panel/Skip

@onready var join: ActionButton = %Join

var map_limits: Rect2
var used_tile_coords: Array[Vector2i] = []
var skin_change_tile_coords: Array[Vector2i] = []
var done_ready: bool = false
var respawning: bool = false

const SKINS = ["Bitty", "Bobby", "Jerry", "Pebby", "Rocky", "Timmy"]

func _ready() -> void:
	
	options.pressed.connect(func():
		$GUI/C/Options/Panel.visible = !$GUI/C/Options/Panel.visible
		
		master.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
		music.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music"))
		sfx.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX"))
		
		)
	
	host.pressed.connect(func():
		if host.visible :
			$GUI/C/Host/Panel.visible = !$GUI/C/Host/Panel.visible 
		)
	
	master.value_changed.connect(func(v:float):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"),v)
		)
	music.value_changed.connect(func(v:float):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"),v)
		)
	sfx.value_changed.connect(func(v:float):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"),v)
		)
	
	join.toggled.connect(func(on:bool):
		if on :
			join.text = "Leave match?"
		else :
			join.text = "Join match?"
		)
	
	done_ready = true
	
	add_bot.pressed.connect(func():
		if host.visible :
			Player.Playroom.addBot()
		)
	
	leave.pressed.connect(func():
		$GUI/Trans/Anim.play_backwards("Intro")
		await $GUI/Trans/Anim.animation_finished
		if Player.PR_connected :
			Player.Playroom.myPlayer().leaveRoom()
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		)

# Called when the node enters the scene tree for the first time.
func setup_map() -> void:
	
	if !done_ready :
		await ready
	
	if picked_map:
		var used := picked_map.get_used_rect()
		var tile_size := picked_map.tile_set.tile_size
		var all_cells := picked_map.get_used_cells()
		used_tile_coords.clear()
		skin_change_tile_coords.clear()
		
		for cell in all_cells:
			var atlas_coords = picked_map.get_cell_atlas_coords(cell)
			if atlas_coords != Vector2i(30, 13):
				used_tile_coords.append(cell)
			
			if atlas_coords == Vector2i(29, 9):
				skin_change_tile_coords.append(cell)
		
		var left := used.position.x * tile_size.x + int(picked_map.global_position.x)
		var right := used.end.x * tile_size.x + int(picked_map.global_position.x)
		var top := used.position.y * tile_size.y + int(picked_map.global_position.y)
		var bottom := used.end.y * tile_size.y + int(picked_map.global_position.y)
		
		cam.limit_left = left
		cam.limit_right = right
		cam.limit_top = top + 24
		cam.limit_bottom = bottom + 24
		
		map_limits = Rect2(left, top, right - left, bottom - top)
	
	reset_player_pos(local_player)
	$Players/Player/Cam.reset_smoothing()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	# Show host menu if is host
	if Player.PR_connected :
		host.visible = Player.Playroom.isHost()
	
	if local_player and picked_map:
		if local_player.spectating:
			var margin: float = 32.0
			local_player.global_position.x = clamp(local_player.global_position.x, map_limits.position.x + margin, map_limits.end.x - margin)
			local_player.global_position.y = clamp(local_player.global_position.y, map_limits.position.y + margin, map_limits.end.y - margin)
		elif not map_limits.has_point(local_player.global_position) and !respawning:
			respawning = true
			await get_tree().create_timer(1.0).timeout
			await reset_player_pos(local_player)
			respawning = false
			
			if local_player.lives < 0 :
				local_player.lives = 3
				local_player.spectating = true
				await get_tree().create_timer(5.0).timeout
				local_player.spectating = false
				await reset_player_pos(local_player)
				local_player.vulnerability = 0.0
				local_player.lives = 3
		
		# Skin change logic
		var player_pos = local_player.global_position
		var current_cell = picked_map.local_to_map(picked_map.to_local(player_pos))
		
		# Check current cell and immediate neighbors for proximity to skin change tiles
		var is_near_wardrobe = false
		for offset in [Vector2i(0,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
			if (current_cell + offset) in skin_change_tile_coords:
				is_near_wardrobe = true
				break
				
		if is_near_wardrobe:
			var skin_index = SKINS.find(local_player.skin)
			if Input.is_action_just_pressed("ui_up"):
				skin_index = (skin_index + 1) % SKINS.size()
				local_player.skin = SKINS[skin_index]
			elif Input.is_action_just_pressed("ui_down"):
				skin_index = (skin_index - 1 + SKINS.size()) % SKINS.size()
				local_player.skin = SKINS[skin_index]

func reset_player_pos(player: Player) -> void:
			# Teleport to a random X based on a used tile and Y just below top
			if not used_tile_coords.is_empty():
				var random_cell = used_tile_coords.pick_random()
				# Convert map coordinate to global world position
				var tile_local_pos := picked_map.map_to_local(random_cell)
				local_player.global_position.x = picked_map.to_global(tile_local_pos).x
			else:
				# Fallback to pure random if no tiles found
				local_player.global_position.x = randf_range(map_limits.position.x, map_limits.end.x)
			
			if local_player.join.button_pressed :
				local_player.vulnerability += 50.0
				if local_player.velocity.length() > 750.0 :
					local_player.lives -= 1
					local_player.vulnerability = 0.0
			
			local_player.global_position.y = map_limits.position.y + 64.0 # 32 pixels below top
			local_player.velocity = Vector2.ZERO # Reset velocity to prevent immediate re-exit
			
			local_player.hide()
			await get_tree().create_timer(1.0).timeout
			local_player.show()
			local_player.drop_dash_charge = 0.0
