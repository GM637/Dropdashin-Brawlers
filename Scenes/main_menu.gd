extends Control

@onready var username: LineEdit = $Username
@onready var show_enter: Label = $Username/Enter
@onready var options: ActionButton = $Options
@onready var credits: ActionButton = $Credits


#Fetch Playroom Kit
var Playroom = JavaScriptBridge.get_interface("Playroom")
 
# Keep a reference to the callback so it doesn't get garbage collected
var jsBridgeReferences = []
func bridgeToJS(cb):
	var jsCallback = JavaScriptBridge.create_callback(cb)
	jsBridgeReferences.push_back(jsCallback)
	return jsCallback
 
func _ready() -> void:
	
	credits.pressed.connect(func():
		$Credits/Panel.visible = !$Credits/Panel.visible
		$Options/Panel.hide()
		$Username.text = ""
		)
	options.pressed.connect(func():
		$Options/Panel.visible = !$Options/Panel.visible
		$Credits/Panel.hide()
		$Username.text = ""
		)
	
	username.focus_entered.connect(func():
		$Credits/Panel.hide()
		$Options/Panel.hide()
		)
	
	if !OS.has_feature("web") :
		username.placeholder_text = "Play on web."
	username.editable = OS.has_feature("web")
	

func _process(delta: float) -> void:
	
	show_enter.visible = username.text != ""
	
 
func join():
	JavaScriptBridge.eval("")
	var initOptions = JavaScriptBridge.create_object("Object");
 
	#Init Options
	initOptions.gameId = "<BdXdXXHfhyvdDA5uweKe>"
 
	#Insert Coin
	Playroom.insertCoin(initOptions, bridgeToJS(onInsertCoin));
 
# Called when the host has started the game
func onInsertCoin(args):
	print("Coin Inserted!")
	Playroom.onPlayerJoin(bridgeToJS(onPlayerJoin))
 
# Called when a new player joins the game
func onPlayerJoin(args):
	var state = args[0]
	print("new player joined: ", state.id)
 
	# Listen to onQuit event
	state.onQuit(bridgeToJS(onPlayerQuit))
 
func onPlayerQuit(args):
	var state = args[0];
	print("player quit: ", state.id)
