extends Node

var Playroom = JavaScriptBridge.get_interface("Playroom")
signal joined

# Keep a reference to the callback so it doesn't get garbage collected
var jsBridgeReferences = []
func bridgeToJS(cb):
	var jsCallback = JavaScriptBridge.create_callback(cb)
	jsBridgeReferences.push_back(jsCallback)
	return jsCallback

func join():
	JavaScriptBridge.eval("")
	var initOptions = JavaScriptBridge.create_object("Object");
	
	var gamestate = JavaScriptBridge.create_object("Object");
	gamestate.state = {
		"last_winner_id" : "",
		"picked_map" : "Testing",
		"match_state" : "0"
	}
	
	var botOptions = JavaScriptBridge.create_object("Object");
	
	#Init Options
	initOptions.gameId = "<BdXdXXHfhyvdDA5uweKe>"
	initOptions.skipLobby = true
	initOptions.maxPlayersPerRoom = 8
	initOptions.matchmaking = true
	initOptions.defaultStates = gamestate
	initOptions.enableBots = true
	initOptions.botOptions = botOptions
 
	#Insert Coin
	Playroom.insertCoin(initOptions, bridgeToJS(onInsertCoin));
	
 
# Called when the host has started the game
func onInsertCoin(_args):
	print("Coin Inserted!")
	Playroom.onPlayerJoin(bridgeToJS(onPlayerJoin))
	
	Player.players.clear()
	
	joined.emit()
 
# Called when a new player joins the game
func onPlayerJoin(args):
	var state = args[0]
	print("new player joined: ", state.id)
	
	if state.id == Playroom.myPlayer.id :
		Player.players.push_front(state)
	else :
		Player.players.append(state)
	Player.PR_connected = true
 
	# Listen to onQuit event
	state.onQuit(bridgeToJS(onPlayerQuit))
	#print(Player.players)
 
func onPlayerQuit(args):
	var state = args[0];
	print("player quit: ", state.id)
	
	#Player.players.erase(state)
	
