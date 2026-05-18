extends Control

@onready var username: LineEdit = $Username
@onready var show_enter: Label = $Username/Enter
@onready var options: ActionButton = $C/Options
@onready var credits: ActionButton = $C/Credits
@onready var github: ActionButton = $C/Github

@onready var master: HSlider = $C/Options/Panel/Master
@onready var music: HSlider = $C/Options/Panel/Music
@onready var sfx: HSlider = $C/Options/Panel/SFX

@onready var Playroom = Player.Playroom
 
func _ready() -> void:
	
	credits.pressed.connect(func():
		$C/Credits/Panel.visible = !$C/Credits/Panel.visible
		$C/Options/Panel.hide()
		$Username.text = ""
		)
	options.pressed.connect(func():
		$C/Options/Panel.visible = !$C/Options/Panel.visible
		$C/Credits/Panel.hide()
		$Username.text = ""
		
		master.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
		music.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music"))
		sfx.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX"))
		
		)
	github.pressed.connect(func():
		OS.shell_open("https://github.com/GM637/Dropdashin-Brawlers")
		)
	
	username.focus_entered.connect(func():
		$C/Credits/Panel.hide()
		$C/Options/Panel.hide()
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
	
	if !OS.has_feature("web") :
		username.placeholder_text = "Play on web."
	username.editable = OS.has_feature("web")
	
	await username.text_submitted
	Player.username = username.text
	
	$Username.release_focus()
	$Username.hide()
	
	PlayroomJoining.join()
	
	await PlayroomJoining.joined
	
	$Connecting.text = "Game Joined!"
	$Trans/Anim.play_backwards("Intro")
	await $Trans/Anim.animation_finished
	
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _process(delta: float) -> void:
	
	show_enter.visible = username.text != ""
	
 
