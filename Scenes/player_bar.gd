extends Panel

@export var player : Player
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var vuln: Label = $Vuln
@onready var talking: Sprite2D = $Talking
@onready var stock: Label = $Stock
@onready var username: Label = $Username

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if !player :
		return
	
	visible = player.visible
	sprite.animation = player.sprite.animation
	sprite.flip_h = player.sprite.flip_h
	sprite.rotation = player.sprite.rotation
	sprite.modulate = player.sprite.modulate
	
	vuln.text = str(int(player.vulnerability)).pad_zeros(3)
	vuln.position = Vector2(23,8) + Vector2(randf_range(-player.vulnerability,player.vulnerability),randf_range(-player.vulnerability,player.vulnerability)) * 0.01
	
	vuln.modulate = Color.WHITE.lerp(Color.RED,player.vulnerability/100.0)
	
	stock.text = "x" + str(player.lives)
	
	username.text = player.namelabel.text
