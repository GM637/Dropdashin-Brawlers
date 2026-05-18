extends CharacterBody2D

class_name Player

static var players := []

#Fetch Playroom Kit
static var Playroom = JavaScriptBridge.get_interface("Playroom")
static var PR_connected: bool = false
static var username := "Test"

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox
@onready var game: Node2D = $"../.."
@onready var namelabel: Label = $Username

@onready var dust: CPUParticles2D = $Dust
@onready var stars: CPUParticles2D = $Stars

var skin: String = "Timmy"

var speed: float = 160.0
var acceleration: float = 2000.0
var friction: float = 2000.0

var jump_velocity: float = -275.0
var gravity_scale: float = 1.0
var terminal_velocity: float = 300.0

# Coyote Time & Jump Buffer
const MAX_COYOTE_TIME: float = 0.12
const MAX_JUMP_BUFFER: float = 0.12
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Drop Dash
var min_drop_dash_speed: float = 300.0
var max_drop_dash_speed: float = 5000.0
var drop_dash_charge_rate: float = 250.0
var drop_dash_duration: float = 0.3

var drop_dash_charge: float = 0.0
var is_dashing: bool = false
var can_dash: bool = false
var dash_input_able = false
var cancel = false
var dash_timer: float = 0.0
var last_direction: float = 1.0

# Multiplayer States
var lives: int = 3
var vulnerability: float = 0.0 # this is actually a percentage, as oer traditional arena fighters go
var spectating: bool = false
var talking: bool = false
var is_stunned: bool = false

@onready var join: ActionButton = %Join

func get_unreliable_data() -> Dictionary:
	return {
		"pos": global_position,
		"vel_mag": velocity.length(),
		"dashing": is_dashing,
		"anim": sprite.animation,
		"flip": sprite.flip_h,
		"rot": sprite.rotation_degrees,
		"user": username,
	}

func get_reliable_data() -> Dictionary:
	return {
		"lives": lives,
		"vulnerable": vulnerability,
		"joined" : join.button_pressed,
		"spectating" : spectating,
		"talking" : talking,
		"skin": skin,
	}

func _physics_process(delta: float) -> void:
		
	# Only control the first player instance (index 0)
	if get_index() != 0:
		
		if PR_connected :
			
			update_player_sync()
		
		return
	
	if not visible:
		return

	if is_stunned:
		apply_gravity(delta)
		move_and_slide()
		if velocity.y > 0:
			is_stunned = false
		update_animation()
		if PR_connected:
			update_self_state()
		return
		
	if spectating:
		handle_spectating_movement(delta)
		global_position += velocity * delta
	else:
		apply_gravity(delta)
		handle_jump(delta)
		handle_movement(delta)
		handle_drop_dash(delta)
		move_and_slide()
		check_hitbox()
		
	update_animation()
	
	if PR_connected :
		update_self_state()

func apply_knockback(strength: float, source_pos: Vector2) -> void:
	is_stunned = true
	var knock_dir = sign(global_position.x - source_pos.x)
	if knock_dir == 0: knock_dir = 1.0
	velocity = Vector2(knock_dir * strength, -abs(strength))

func check_hitbox() -> void:
	
	if Input.is_action_just_pressed("slap") :
		apply_knockback(1000, global_position + Vector2(32,0))
	
	for check in hitbox.get_overlapping_bodies():
		if check is Player and check != self:
			if check.is_dashing:
				var other_speed = check.velocity.length()
				var kb_strength = other_speed * vulnerability
				vulnerability += other_speed * 0.5
				apply_knockback(kb_strength, check.global_position)
				break # Only take one hit per frame

func handle_spectating_movement(delta: float) -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_velocity := input_dir * speed * 2.0
	velocity = velocity.lerp(target_velocity, delta * 8.0)
	if input_dir.x != 0:
		sprite.flip_h = input_dir.x < 0

func apply_gravity(delta: float) -> void:
	
	# Fall Faster Mechanic
	var fall_scale := 2.0 if Input.is_action_pressed("ui_down") else 1.0
	
	if not is_on_floor():
		velocity.y += get_gravity().y * gravity_scale * delta * fall_scale
		velocity.y = min(velocity.y, terminal_velocity * fall_scale)
		coyote_timer -= delta
	else:
		coyote_timer = MAX_COYOTE_TIME

func handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") :
		jump_buffer_timer = MAX_JUMP_BUFFER
	
	jump_buffer_timer -= delta
	
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		can_dash = true
		jump_buffer_timer = 0
		coyote_timer = 0

func handle_movement(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		velocity.x = last_direction * max(abs(velocity.x), min_drop_dash_speed)
		if is_on_wall() :
			last_direction = get_wall_normal().x
			velocity.y = min_drop_dash_speed * -0.75
			dash_timer *= 0.75
		if dash_timer <= 0:
			is_dashing = false
		return

	var direction := Input.get_axis("ui_left", "ui_right")
	
	last_direction = -1 if sprite.flip_h else 1
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_drop_dash(delta: float) -> void:
	
	sprite.rotation_degrees += (drop_dash_charge * 1.5) * sign(last_direction) * 15.0
	sprite.modulate = Color.WHITE
	if is_dashing :
		sprite.modulate.s = 1.0
		sprite.modulate.h = global_position.x * 0.01
		sprite.modulate *= 5.0
	
	if drop_dash_charge < min_drop_dash_speed :
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, 0.0 , delta * 35.0)
	
	if not is_on_floor():
		
		if Input.is_action_just_pressed("dash") :
			dash_input_able = !dash_input_able
			
		
		# Charge drop dash 
		if dash_input_able :
			last_direction = -1 if sprite.flip_h else 1
			drop_dash_charge = move_toward(drop_dash_charge, max_drop_dash_speed, drop_dash_charge_rate * delta)
		else :
			drop_dash_charge = 0.0
	
	else:
		
		cancel = false
		dash_input_able = false
		
		if drop_dash_charge > 0 and can_dash :
			# Trigger Drop Dash upon landing
			is_dashing = true
			can_dash = false
			dash_timer = drop_dash_duration
			velocity.x = last_direction * max(drop_dash_charge, min_drop_dash_speed)
			sprite.rotation_degrees = 0.0
			drop_dash_charge = 0.0
		
		if not is_dashing:
			drop_dash_charge = 0.0

func update_animation() -> void:
	sprite.modulate.a = 0.5 if spectating else 1.0
	
	if spectating:
		sprite.play("Idle" + skin)
		return
		
	if not is_on_floor():
		sprite.play("Jump" + skin)
	elif is_dashing or abs(velocity.x) > 10.0:
		sprite.play("Run" + skin)
	else:
		sprite.play("Idle" + skin)
	
	dust.emitting = is_dashing
	stars.emitting = abs(sprite.rotation_degrees) > 2

func update_self_state() -> void:
	
	namelabel.text = username
	Playroom.myPlayer().setState("RE_data",var_to_str(get_reliable_data()),true)
	Playroom.myPlayer().setState("UR_data",var_to_str(get_unreliable_data()),false)

func update_player_sync() -> void:
	# Check if theres a player
	if players.size() > get_index() :
		if players[get_index()]:
			show()
			var state = players[get_index()]
			
			if state.isBot() and Playroom.isHost() :
				handle_bot_ai_from_host(state)
			
			if state.getState("RE_data") == null :
				return
			if state.getState("UR_data") == null :
				return
			
			var RE_data = str_to_var(state.getState("RE_data"))
			var UR_data = str_to_var(state.getState("UR_data"))
			
			if RE_data:
				
				#print(RE_data)
				
				lives = RE_data.get("lives", lives)
				vulnerability = RE_data.get("vulnerable", vulnerability)
				spectating = RE_data.get("spectating", spectating)
				talking = RE_data.get("talking", talking)
			
			if UR_data:
				
				#print(UR_data)
				
				if UR_data.has("user"):
					namelabel.text = UR_data["user"]
				
				if UR_data.has("pos"):
					global_position = lerp( global_position, UR_data["pos"], get_physics_process_delta_time() * 35.0 )
					if global_position.distance_to(UR_data["pos"]) > 64 :
						global_position = UR_data["pos"]
				
				if UR_data.has("rot"):
					sprite.rotation_degrees = lerp( sprite.rotation_degrees, UR_data["rot"], get_physics_process_delta_time() * 35.0 )
				
				is_dashing = UR_data.get("dashing", false)
				sprite.flip_h = UR_data.get("flip", false)
				
				if UR_data.has("anim"):
					sprite.play(UR_data["anim"])
				
				# Replicate visual effects for dashing/movement
				sprite.modulate = Color.WHITE
				sprite.modulate.a = 0.5 if spectating else 1.0
				
				if is_dashing:
					sprite.modulate.s = 1.0
					sprite.modulate.h = global_position.x * 0.01
					sprite.modulate *= 5.0
		else:
			hide()
	else:
		hide()

func handle_bot_ai_from_host(state) -> void:
	
	handle_bot_ai()
	
	state.setState("RE_data",var_to_str(get_reliable_data()),true)
	state.setState("UR_data",var_to_str(get_unreliable_data()),false)

func handle_bot_ai() -> void:
	
	pass
