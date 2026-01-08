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

func _on_main_menu_start_game() -> void:
	"""Начало игры из меню"""
	if _main_menu_instance:
		_main_menu_instance.queue_free()
		_main_menu_instance = null
	
	# Unlock base character when starting story
	# GameGlobal.unlock_card("card_danila_happy")
	
	show_casino() # Или start_story(), если хотите пропустить казино

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
	if not scripts.is_empty():
		for script in scripts:
			var text := lexer.read_file_content(script)

			var tokens: Array = lexer.tokenize(text)

			var tree: SceneParser.SyntaxTree = parser.parse(tokens)

			var dialogue: SceneTranspiler.DialogueTree = transpiler.transpile(tree, 0)

			# Make sure the scene is transitioned properly at the end of the script
			if not dialogue.nodes[dialogue.index - 1] is SceneTranspiler.JumpCommandNode:
				(dialogue.nodes[dialogue.index - 1] as SceneTranspiler.BaseNode).next = -1

			SCENES.append(dialogue)

		_play_scene(0)


func _play_scene(index: int) -> void:
	_current_index = int(clamp(index, 0.0, SCENES.size() - 1))

	if _scene_player:
		_scene_player.queue_free()

	_scene_player = SCENE_PLAYER.instantiate()
	add_child(_scene_player)
	_scene_player.load_scene(SCENES[_current_index])
	_scene_player.scene_finished.connect(_on_ScenePlayer_scene_finished)
	_scene_player.restart_requested.connect(_on_ScenePlayer_restart_requested)
	_scene_player.run_scene()


func _on_ScenePlayer_scene_finished() -> void:
	# If the scene that ended is the last scene, we're done playing the game.
	if _current_index == SCENES.size() - 1:
		return
	_play_scene(_current_index + 1)


func _on_ScenePlayer_restart_requested() -> void:
	_play_scene(_current_index)
