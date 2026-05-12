extends CharacterBody2D

class_name Player

@onready var sprite: AnimatedSprite2D = $Sprite

var skin: String = "Bitty"

var speed: float = 180.0
var acceleration: float = 2000.0
var friction: float = 2000.0

var jump_velocity: float = -300.0
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

func _physics_process(delta: float) -> void:
	if not visible:
		return
		
	# Only control the first player instance (index 0)
	if get_index() != 0:
		apply_gravity(delta)
		move_and_slide()
		update_animation()
		return

	apply_gravity(delta)
	handle_jump(delta)
	handle_movement(delta)
	handle_drop_dash(delta)
	
	move_and_slide()
	update_animation()

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
	
	sprite.rotation_degrees += drop_dash_charge * sign(last_direction) * 15.0
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
	if not is_on_floor():
		sprite.play("Jump" + skin)
	elif is_dashing or abs(velocity.x) > 10.0:
		sprite.play("Run" + skin)
	else:
		sprite.play("Idle" + skin)
