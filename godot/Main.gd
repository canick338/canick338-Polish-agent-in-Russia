extends Node


@export var scripts : Array[String]

const SCENE_PLAYER := preload("res://ScenePlayer.tscn")
const SLOT_MACHINE_SCENE := preload("res://Casino/SlotMachineScene.tscn")
const MAIN_MENU_SCENE := preload("res://MainMenu.tscn")

var SCENES := []

const PAUSE_MENU_SCENE := preload("res://PauseMenu.tscn")

var _current_index := -1
var _scene_player: ScenePlayer
var _casino_instance: Control = null
var _main_menu_instance: Control = null
# var _casino_shown: bool = false # Removed unused variable warning if any

var lexer := SceneLexer.new()
var parser := SceneParser.new()
var transpiler := SceneTranspiler.new()


func _ready() -> void:
	# Сначала показываем главное меню
	show_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Toggle pause menu
		if not get_tree().paused:
			# Check if we are in main menu, usually we don't pause inside main menu
			if _main_menu_instance != null:
				return
				
			show_pause_menu()

func show_pause_menu():
	if PAUSE_MENU_SCENE:
		var menu = PAUSE_MENU_SCENE.instantiate()
		add_child(menu)
		# Menu script handles pausing the tree in _ready

func show_main_menu() -> void:
	"""Показать главное меню"""
	if MAIN_MENU_SCENE:
		_main_menu_instance = MAIN_MENU_SCENE.instantiate()
		add_child(_main_menu_instance)
		
		if _main_menu_instance.has_signal("start_game_requested"):
			_main_menu_instance.start_game_requested.connect(_on_main_menu_start_game)
		if _main_menu_instance.has_signal("exit_requested"):
			_main_menu_instance.exit_requested.connect(func(): get_tree().quit())


func show_casino() -> void:
	"""Показать слот-машину в начале игры"""
	if SLOT_MACHINE_SCENE:
		_casino_instance = SLOT_MACHINE_SCENE.instantiate()
		add_child(_casino_instance)
		
		# Подключить сигнал окончания казино
		if _casino_instance.has_signal("casino_finished"):
			_casino_instance.casino_finished.connect(_on_casino_finished)
	# Fallback if slot machine fails to load
	else:
		start_story()

func _on_casino_finished(is_win: bool) -> void:
	"""Казино закончено - переход к сюжету"""
	print("Казино закончено! Выигрыш: ", is_win)
	
	# Удалить казино
	if _casino_instance:
		_casino_instance.queue_free()
		_casino_instance = null
	
	# Загрузить и запустить сюжет
	start_story()


func start_story() -> void:
	"""Запустить сюжет игры"""
	SCENES.clear()
	
	if scripts.is_empty():
		# Fallback for testing if no scripts assigned, though production should have them.
		# Or maybe we want to load specific test file?
		# For now, let's keep the debug load if empty, OR just assume scripts are assigned.
		print("No scripts assigned to Main. Using default Prequel.")
		var loader = JSONDialogueLoader.new()
		var tree = loader.load_scene("res://Story/prequel_danila.json")
		if tree:
			SCENES.append(tree)
	else:
		# Load all assigned scripts as JSON
		var loader = JSONDialogueLoader.new()
		for script_path in scripts:
			# Replace .txt with .json
			# (Assuming script_path is like "res://Story/prologue.txt")
			var json_path = script_path.replace(".txt", ".json")
			
			if not FileAccess.file_exists(json_path):
				print("JSON file not found: " + json_path)
				# Fallback for legacy main_game_loop which might be renamed or missing
				if "main_game_loop" in json_path:
					json_path = "res://Story/master_scenario.json"
					print("Fallback to: " + json_path)
			
			print("Loading scene from: " + json_path)
			
			var tree = loader.load_scene(json_path)
			if tree:
				# Ensure chain continuity handled by Player logic or manual link?
				# The legacy code did: (dialogue.nodes[dialogue.index - 1] as SceneTranspiler.BaseNode).next = -1
				SCENES.append(tree)
			else:
				push_error("Failed to load scene: " + json_path)

	if SCENES.is_empty():
		push_error("No scenes loaded!")
		return

	_play_scene(0)


func _play_scene(index: int, start_node: int = 0) -> void:
	_current_index = int(clamp(index, 0.0, SCENES.size() - 1))

	if _scene_player:
		_scene_player.queue_free()

	_scene_player = SCENE_PLAYER.instantiate()
	add_child(_scene_player)
	_scene_player.load_scene(SCENES[_current_index])
	_scene_player.scene_finished.connect(_on_ScenePlayer_scene_finished)
	_scene_player.restart_requested.connect(_on_ScenePlayer_restart_requested)
	_scene_player.run_scene(start_node)


func get_current_state() -> Dictionary:
	"""Returns current game state for saving."""
	var state = {
		"scene_index": _current_index,
		"node_index": 0
	}
	
	if _scene_player:
		state["node_index"] = _scene_player.get_current_position()
	
	return state


func load_from_state(state: Dictionary) -> void:
	"""Restores game from saved state."""
	# Ensure scenes are loaded
	if SCENES.is_empty():
		start_story()
		await get_tree().process_frame
	
	var scene_idx = state.get("scene_index", 0)
	var node_idx = state.get("node_index", 0)
	
	_play_scene(scene_idx, node_idx)


func _on_main_menu_start_game() -> void:
	"""Начало игры из меню"""
	# Check if there's a pending load from main menu
	var has_pending_load = GameGlobal.save_data.has("pending_load")
	
	if _main_menu_instance:
		_main_menu_instance.queue_free()
		_main_menu_instance = null
	
	# Small delay to ensure menu is cleaned up
	await get_tree().process_frame
	
	if has_pending_load:
		var pending = GameGlobal.save_data["pending_load"]
		GameGlobal.save_data.erase("pending_load")
		
		print("Loading from saved position: scene=%d, node=%d" % [pending["scene_index"], pending["node_index"]])
		
		# Load the game
		start_story()
		await get_tree().process_frame
		load_from_state(pending)
	else:
		# Normal new game start
		show_casino()

func _on_ScenePlayer_scene_finished() -> void:
	# If the scene that ended is the last scene, we're done playing the game.
	if _current_index == SCENES.size() - 1:
		return
	_play_scene(_current_index + 1)


func _on_ScenePlayer_restart_requested() -> void:
	_play_scene(_current_index)
