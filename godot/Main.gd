extends Node


@export var scripts : Array[String]

const SCENE_PLAYER := preload("res://ScenePlayer.tscn")
const SLOT_MACHINE_SCENE := preload("res://Casino/SlotMachineScene.tscn")
const MAIN_MENU_SCENE := preload("res://MainMenu.tscn")
const PAUSE_MENU_SCENE := preload("res://PauseMenu.tscn")
const WORLD_MAP_SCENE := preload("res://WorldMap.tscn")

var _current_scene_path: String = ""
var _scene_player: ScenePlayer = null
var _casino_instance: Control = null
var _main_menu_instance: Control = null
var _world_map_instance: Control = null


func _ready() -> void:
	# Сначала показываем кинематографическую заставку, потом меню
	_show_splash()

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

func _show_splash() -> void:
	"""Показать заставку студии перед главным меню"""
	var splash_scene = load("res://SplashScreen.tscn")
	if splash_scene:
		var splash = splash_scene.instantiate()
		add_child(splash)
		splash.splash_finished.connect(show_main_menu)
	else:
		show_main_menu()

func show_main_menu() -> void:
	"""Показать главное меню"""
	if MAIN_MENU_SCENE:
		_main_menu_instance = MAIN_MENU_SCENE.instantiate()
		add_child(_main_menu_instance)
		
		if _main_menu_instance.has_signal("start_game_requested"):
			_main_menu_instance.start_game_requested.connect(_on_main_menu_start_game)
		if _main_menu_instance.has_signal("exit_requested"):
			_main_menu_instance.exit_requested.connect(func(): get_tree().quit())


func return_to_main_menu() -> void:
	"""Очищает все активные сцены и возвращает в главное меню"""
	if _scene_player:
		_scene_player.queue_free()
		_scene_player = null
		
	if _world_map_instance:
		_world_map_instance.queue_free()
		_world_map_instance = null
		
	if _casino_instance:
		_casino_instance.queue_free()
		_casino_instance = null
		
	if _main_menu_instance:
		_main_menu_instance.queue_free()
		_main_menu_instance = null
		
	show_main_menu()


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
		show_world_map()

func _on_casino_finished(is_win: bool) -> void:
	"""Казино закончено - переход к сюжету"""
	print("Казино закончено! Выигрыш: ", is_win)
	
	# Удалить казино
	if _casino_instance:
		_casino_instance.queue_free()
		_casino_instance = null
	
	# Загрузить хаб (карту)
	show_world_map()

func show_world_map() -> void:
	"""Показать глобальную карту (Hub) - Варшава (Пролог) или Обоянь"""
	
	if _scene_player:
		_scene_player.queue_free()
		_scene_player = null
		
	if WORLD_MAP_SCENE:
		_world_map_instance = WORLD_MAP_SCENE.instantiate()
		add_child(_world_map_instance)
		_world_map_instance.scene_requested.connect(_on_world_map_scene_requested)
	else:
		push_error("WorldMap scene not found!")

func _on_world_map_scene_requested(path: String) -> void:
	if _world_map_instance:
		_world_map_instance.queue_free()
		_world_map_instance = null
		
	_play_scene_from_path(path)

func _play_scene_from_path(path: String, start_node: int = 0) -> void:
	_current_scene_path = path

	if _scene_player:
		_scene_player.queue_free()

	_scene_player = SCENE_PLAYER.instantiate()
	add_child(_scene_player)
	
	var loader = JSONDialogueLoader.new()
	var tree = loader.load_scene(path)
	if tree:
		_scene_player.load_scene(tree)
		_scene_player.scene_finished.connect(_on_ScenePlayer_scene_finished)
		_scene_player.restart_requested.connect(_on_ScenePlayer_restart_requested)
		_scene_player.run_scene(start_node)
	else:
		push_error("Failed to load scene from path: " + path)
		show_world_map()


func start_story_test(path: String) -> void:
	"""Helper to run a specific scene file directly for testing."""
	_play_scene_from_path(path)


func get_current_state() -> Dictionary:
	"""Returns current game state for saving."""
	var state = {
		"scene_path": _current_scene_path,
		"node_index": 0
	}
	
	if _scene_player:
		state["node_index"] = _scene_player.get_current_position()
	
	return state


func load_from_state(state: Dictionary) -> void:
	"""Восстанавливает игру из сохранённого состояния."""
	var scene_path = state.get("scene_path", "")
	var node_idx = int(state.get("node_index", 0))
	
	# Очищаем все активные сцены перед загрузкой
	if _scene_player:
		_scene_player.queue_free()
		_scene_player = null
	if _world_map_instance:
		_world_map_instance.queue_free()
		_world_map_instance = null
	if _casino_instance:
		_casino_instance.queue_free()
		_casino_instance = null
	if _main_menu_instance:
		_main_menu_instance.queue_free()
		_main_menu_instance = null
	
	if scene_path != "":
		_play_scene_from_path(scene_path, node_idx)
	else:
		show_world_map()


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
		
		print("Loading from saved position: scene=%s, node=%d" % [pending.get("scene_path", ""), pending.get("node_index", 0)])
		
		# Load the game
		await get_tree().process_frame
		load_from_state(pending)
	else:
		# Normal new game start — begin with prologue dialogue, NOT the map
		Variables.clear_all_variables()
		if GameGlobal and GameGlobal.has_method("save_project_state"):
			GameGlobal.save_data.clear()
			GameGlobal.save_project_state()
		# Play the intro streets scene first (orphanage flashback)
		# The map will appear only after this scene finishes via _on_ScenePlayer_scene_finished
		_play_scene_from_path("res://Story/00_Warsaw/01_intro_streets.json")

func _on_ScenePlayer_scene_finished() -> void:
	# === Продвижение времени после завершения сцены (action-based, как в VN) ===
	var time_idx = int(Variables.get_variable("current_time", 0))
	time_idx += 1
	if time_idx > 3:
		time_idx = 0
		var day = int(Variables.get_variable("current_day", 1))
		Variables.add_variable("current_day", day + 1)
	Variables.add_variable("current_time", time_idx)
	
	# Обновить is_night
	if time_idx == 3:
		Variables.add_variable("is_night", 1)
	else:
		Variables.add_variable("is_night", 0)
	
	# Возвращаемся в хаб (Карту)
	show_world_map()

func _on_ScenePlayer_restart_requested() -> void:
	if _current_scene_path != "":
		_play_scene_from_path(_current_scene_path)
