## Loads and plays a scene's dialogue sequences, delegating to other nodes to display images or text.
class_name ScenePlayer
extends Node

signal scene_finished
signal restart_requested
signal transition_finished
signal scene_event(event_name, args)

const KEY_END_OF_SCENE := -1
const KEY_RESTART_SCENE := -2

## Maps transition keys to a corresponding function to call.
const TRANSITIONS := {
	fade_in = "_appear_async",
	fade_out = "_disappear_async",
}

const CUTSCENE_PLAYER := preload("res://Cutscenes/CutscenePlayer.tscn")
const FACTORY_JAM_SCENE := preload("res://Factory/FactoryJamScene.tscn")
const CARD_GAME_SCENE := preload("res://CardGame/CardGameScene.tscn")
const CINEMATIC_LAYER_SCENE := preload("res://Cinematic/CinematicLayer.tscn")
const COOKING_SCENE := preload("res://Cooking/CookingScene.tscn")

var _scene_data := {}
var _cutscene_player: Control = null
var _minigame_instance: Control = null
var _cinematic_layer: Control = null
var _current_node_index := 0  # Track current position for save/load

@onready var _text_box := $TextBox
@onready var _character_displayer := $CharacterDisplayer
@onready var _anim_player: AnimationPlayer = $FadeAnimationPlayer
@onready var _background := $Background


func run_scene(start_key: int = 0) -> void:
	# Ensure all @onready variables are initialized
	if not is_node_ready():
		await ready
	
	# If resuming from a saved position, restore background
	if start_key > 0:
		_restore_background_for_position(start_key)
	
	var key = start_key
	_current_node_index = start_key
	while key != KEY_END_OF_SCENE:
		_current_node_index = key  # Update position tracker
		# Проверяем, что key валидный
		if not _scene_data.has(key):
			push_error("Invalid key in scene data: %d (scene has %d nodes). Ending scene." % [key, _scene_data.size()])
			break
		
		var node: SceneTranspiler.BaseNode = _scene_data[key]
		print("Processing node at key %d: type=%s (Script: %s), next=%d" % [key, node.get_class(), node.get_script().resource_path.get_file() if node.get_script() else "Native", node.next])
		
		# Debug for Minigame Node
		if node is SceneTranspiler.MinigameCommandNode:
			print(">>> FOUND MINIGAME NODE! Name: ", node.minigame_name)
			
		var character: Character = null
		if "character" in node and node.character != "":
			if node.character.begins_with("==="):
				# System message or separator, not a real character
				character = null
			else:
				character = ResourceDB.get_character(node.character)
		else:
			character = ResourceDB.get_narrator()
		
		# Проверка на null персонажа
		if not character:
			var char_id = node.character if "character" in node and node.character != "" else "narrator"
			
			# Don't error on system messages
			if not char_id.begins_with("==="):
				push_error("Character not found: " + char_id)
				character = ResourceDB.get_narrator()  # Fallback на narrator
			
			# Если narrator тоже не найден, создаем минимальный fallback
			if not character and not char_id.begins_with("==="):
				push_error("Narrator not found! Creating fallback character.")
				# Создаем минимальный Character ресурс программно
				character = Character.new()
				character.id = "narrator"
				character.display_name = ""
				character.images = {"neutral": null}

		# Emit event if present
		if node.event and not node.event.is_empty():
			var evt_name = node.event.get("name", "")
			var evt_args = node.event.get("args", [])
			if evt_name != "":
				print("ScenePlayer emitting event: ", evt_name, evt_args)
				scene_event.emit(evt_name, evt_args)

		if node is SceneTranspiler.BackgroundCommandNode:
			if node.background == "black":
				if _background:
					_background.texture = null
					# Ensure it looks black (if behind is black)
					# Or we could have a black resource.
					# For now, null texture usually means transparent/black depending on setup.
					print("Background set to black (cleared).")
			else:
				var bg: Background = ResourceDB.get_background(node.background)
				if bg and bg.texture:
					if _background:
						_background.texture = bg.texture
					else:
						push_error("Background node not ready!")
				else:
					push_error("Background not found: " + node.background)
			
			# Handle transition if specified
			if "transition" in node and node.transition != "" and TRANSITIONS.has(node.transition):
				call(TRANSITIONS[node.transition])
				await self.transition_finished

		# Displaying a character.
		# Показываем персонажа только если он явно указан в узле
		if "character" in node and node.character != "" and character:
			var side: String = "left"  # По умолчанию слева
			if "side" in node and node.side != "":
				side = node.side
			var animation: String = node.animation if "animation" in node else ""
			var expression: String = node.expression if "expression" in node else ""
			# Обновляем персонажа, но НЕ скрываем других - они остаются на экране
			_character_displayer.display(character, side, expression, animation)
			if not "line" in node:
				await _character_displayer.display_finished
		# НЕ скрываем персонажей при строках без персонажа - они остаются на экране для диалога

		# Normal text reply.
		if "line" in node:
			# Ensure screen is visible before showing text
			await _ensure_visible()
			
			# Убеждаемся, что text_box видим и готов к отображению
			if not _text_box.visible:
				_text_box.show()
			await get_tree().process_frame
			
			# Для строк без персонажа используем narrator (пустое имя)
			var display_name = ""
			if "character" in node and node.character != "" and character:
				display_name = tr(character.display_name) if character else "Unknown"
			
			var text_to_show = node.line
			if "translation_key" in node and node.translation_key != "":
				var translated = tr(node.translation_key)
				
				# DEBUG LOCALIZATION
				print("LOCALE: ", TranslationServer.get_locale(), " | KEY: ", node.translation_key, " | TR: ", translated)
				
				# Only use translation if it returns something different from the key
				if translated != node.translation_key:
					text_to_show = translated
				else:
					print("MISSING TRANSLATION for: ", node.translation_key)
			
			_text_box.display(text_to_show, display_name)
			await _text_box.next_requested
			key = node.next

		# Transition animation.
		elif node is SceneTranspiler.TransitionCommandNode:
			if node.transition != "":
				call(TRANSITIONS[node.transition])
				await self.transition_finished
			key = node.next

		# Cutscene video playback
		elif node is SceneTranspiler.CutsceneCommandNode:
			await _play_cutscene(node.video_path, node.can_skip, node.auto_continue)
			key = node.next

		# Minigame
		elif node is SceneTranspiler.MinigameCommandNode:
			await _play_minigame(node.minigame_name)
			# После мини-игры переходим к следующему узлу (диалог "Мини-игра завершена.")
			key = node.next
			print("After minigame, next key = ", key)
			# Проверяем, что переменные установлены
			var vars = Variables.get_stored_variables_list()
			print("Variables after minigame: ", vars)
			# Убеждаемся, что UI видим перед переходом к следующему узлу
			if _text_box and not _text_box.visible:
				_text_box.show()
			if _character_displayer and not _character_displayer.visible:
				_character_displayer.show()
			# Небольшая задержка для стабилизации UI
			await get_tree().process_frame

		# Manage variables
		elif node is SceneTranspiler.SetCommandNode:
			Variables.add_variable(node.symbol, node.value)
			key = node.next

		# Change to another scene
		elif node is SceneTranspiler.SceneCommandNode:
			if node.scene_path == "next_scene":
				key = KEY_END_OF_SCENE
			else:
				key = node.next

		# Unlock Card/Dossier
		elif node is SceneTranspiler.UnlockCommandNode:
			GameGlobal.unlock_card(node.card_id)
			key = node.next

		# Cinematic CG
		elif node is SceneTranspiler.CinematicCommandNode:
			await _play_cinematic(node)
			key = node.next

		# Choices.
		elif node is SceneTranspiler.ChoiceTreeNode:
			# Ensure screen is visible before showing choices
			await _ensure_visible()
			
			# Temporary fix for the buttons not showing when there are consecutive choice nodes
			await get_tree().process_frame
			await get_tree().process_frame
			await get_tree().process_frame

			_text_box.display_choice(node.choices)

			key = await _text_box.choice_made

			if key == KEY_RESTART_SCENE:
				restart_requested.emit()
				return
		elif node is SceneTranspiler.ConditionalTreeNode:
			var variables_list: Dictionary = Variables.get_stored_variables_list()
			print("ScenePlayer: Condition Check. factory_jam_final_score = ", variables_list.get("factory_jam_final_score", "NOT_FOUND"))
			print("ScenePlayer: All Variables: ", variables_list)

			# Evaluate the if's condition
			if _evaluate_condition(node.if_block.condition, variables_list):
				key = node.if_block.next
			else:
				# Have to use this flag because we can't `continue` out of the
				# elif loop
				var elif_condition_fulfilled := false

				# Evaluate the elif's conditions
				for block in node.elif_blocks:
					if _evaluate_condition(block.condition, variables_list):
						key = block.next
						elif_condition_fulfilled = true
						break

				if not elif_condition_fulfilled:
					if node.else_block:
						# Go to else
						key = node.else_block.next
					else:
						# Move on
						key = node.next

		# Ensures we don't get stuck in an infinite loop if there's no line to display.
		else:
			key = node.next

	_character_displayer.hide()
	scene_finished.emit()


func load_scene(dialogue: SceneTranspiler.DialogueTree) -> void:
	# The main script
	_scene_data = dialogue.nodes
	_current_node_index = dialogue.index # Start at the beginning? No, typically 0/start_key

func load_scene_from_file(path: String) -> void:
	var dialogue_tree: SceneTranspiler.DialogueTree = null
	
	if path.ends_with(".json"):
		print("Loading JSON scene: " + path)
		var loader = JSONDialogueLoader.new()
		dialogue_tree = loader.load_scene(path)
	elif path.ends_with(".txt"):
		print("Loading TXT scene: " + path)
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var lexer = SceneLexer.new()
			var parser = SceneParser.new()
			var transpiler = SceneTranspiler.new()
			
			var tokens = lexer.tokenize(content)
			var ast = parser.parse(tokens)
			dialogue_tree = transpiler.transpile(ast, 0)
		else:
			push_error("Failed to open file: " + path)
			return
	
	if dialogue_tree:
		load_scene(dialogue_tree)
	else:
		push_error("Failed to load scene from: " + path)


func get_current_position() -> int:
	"""Returns the current dialogue node index for saving."""
	return _current_node_index


func _restore_background_for_position(start_key: int) -> void:
	"""Finds and applies the most recent background command before the given position."""
	# Scan backwards from start_key to find the last background command
	var key = start_key - 1
	while key >= 0:
		if _scene_data.has(key):
			var node = _scene_data[key]
			if node is SceneTranspiler.BackgroundCommandNode:
				# Found the background! Apply it
				var bg: Background = ResourceDB.get_background(node.background)
				if bg and bg.texture and _background:
					_background.texture = bg.texture
					print("Restored background: ", node.background)
				break
		key -= 1
	
	# If no background found, that's okay - some scenes start without one


func _appear_async() -> void:
	# Убеждаемся, что text_box видим
	if _text_box:
		_text_box.show()
	_anim_player.play("fade_in")
	await _anim_player.animation_finished
	#await _text_box.fade_in_async().completed
	if _text_box:
		await _text_box.fade_in_async()
	transition_finished.emit()


func _ensure_visible() -> void:
	"""Check if the screen is faded out (black) and fade it in if necessary."""
	# Check if the fade overlay is visible/opaque
	var color_rect = $ColorRect
	if color_rect and color_rect.modulate.a > 0.9: # If almost fully opaque
		print("Auto-fading in because screen is black.")
		await _appear_async()


func _disappear_async() -> void:
	#await _text_box.fade_out_async().completed
	if _text_box:
		await _text_box.fade_out_async()
	_anim_player.play("fade_out")
	await _anim_player.animation_finished
	transition_finished.emit()


## Проиграть кат-сцену
func _play_cutscene(video_path: String, can_skip: bool, auto_continue: bool) -> void:
	# Создать плеер если его нет
	if not _cutscene_player:
		_cutscene_player = CUTSCENE_PLAYER.instantiate()
		add_child(_cutscene_player)
	
	# Скрыть UI визуальной новеллы
	_text_box.hide()
	_character_displayer.hide()
	
	# Проиграть видео
	_cutscene_player.play_cutscene(video_path, can_skip, auto_continue)
	await _cutscene_player.cutscene_finished
	
	# Показать UI обратно
	_text_box.show()
	_character_displayer.show()


func _play_minigame(minigame_name: String) -> void:
	"""Проиграть мини-игру"""
	match minigame_name:
		"factory_jam", "jam_factory", "расфасовка":
			print("ScenePlayer: Matched factory_jam")
			await _play_factory_jam_game()
		"card_game", "cards", "карты", "21", "очки":
			print("ScenePlayer: Matched card_game")
			await _play_card_game()
		"cooking", "varka", "варка":
			print("ScenePlayer: Matched cooking")
			await _play_cooking_game()
		_:
			push_error("Unknown minigame: " + minigame_name)
			print("ScenePlayer: Unknown minigame name: ", minigame_name)


func _play_factory_jam_game() -> void:
	"""Проиграть мини-игру расфасовки повидла"""
	# Score reset is handled by the mini-game scene itself.
	
	# Создать экземпляр мини-игры
	# ... instantiation logic stays same ...
	# Just checking if I can use ... to skip lines in replace_file_content? No, I must provide complete chunks.
	if not _minigame_instance and FACTORY_JAM_SCENE:
		_minigame_instance = FACTORY_JAM_SCENE.instantiate()
		if _minigame_instance:
			add_child(_minigame_instance)
	
	if not _minigame_instance:
		push_error("Failed to create FactoryJamScene instance")
		return
	
	# Подключить сигнал окончания (если еще не подключен)
	if _minigame_instance.has_signal("factory_game_finished"):
		# Отключаем предыдущее подключение, если есть
		if _minigame_instance.factory_game_finished.is_connected(_on_factory_game_finished):
			_minigame_instance.factory_game_finished.disconnect(_on_factory_game_finished)
		_minigame_instance.factory_game_finished.connect(_on_factory_game_finished)
	
	# Скрыть UI визуальной новеллы
	if _text_box:
		_text_box.hide()
	if _character_displayer:
		_character_displayer.hide()
	
	# Запустить игру вручную (после того как диалог показан)
	if _minigame_instance.has_method("start_game_manual"):
		_minigame_instance.start_game_manual()
	
	# Ждать окончания игры
	await _minigame_instance.factory_game_finished
	
	# Переменные уже установлены в _on_factory_game_finished
	# Проверяем, что переменные установлены
	var vars = Variables.get_stored_variables_list()
	print("After minigame - factory_jam_final_score = ", vars.get("factory_jam_final_score", "NOT SET"))
	
	# Удалить мини-игру
	if _minigame_instance:
		_minigame_instance.queue_free()
		_minigame_instance = null
	
	# Показать UI обратно
	if _text_box:
		_text_box.show()
		# Убеждаемся, что text_box видим и готов к отображению
		if is_inside_tree():
			await get_tree().process_frame
	if _character_displayer:
		_character_displayer.show()
		if is_inside_tree():
			await get_tree().process_frame
	
	# Небольшая задержка для плавного перехода
	await get_tree().create_timer(0.2).timeout


# ... (card game logic omitted) ...
	# Money is also awarded by the mini-game scene.


func _play_cinematic(node: SceneTranspiler.CinematicCommandNode) -> void:
	"""Plays a cinematic effect on the Cinematic Layer."""
	# 1. Instantiate layer if needed
	if not _cinematic_layer:
		_cinematic_layer = CINEMATIC_LAYER_SCENE.instantiate()
		# Add BEHIND the text box but ABOVE the background
		# Assuming textbox is high in z-index or last in tree.
		# Let's add it before textbox to be safe
		add_child(_cinematic_layer)
		# Move to be before textbox if possible, or just add.
		# TextureRects draw order depends on tree order.
		if _text_box:
			move_child(_cinematic_layer, _text_box.get_index())
	
	if not _cinematic_layer.visible:
		_cinematic_layer.show()
	
	# 2. Show Image
	if node.image_path != "":
		_cinematic_layer.show_image(node.image_path)
	
	# 3. Apply Effect (Idle/Action)
	if node.effect != "":
		# Check if it's a movement command (zoom/pan) or idle
		
		# --- Idle Effects ---
		if node.effect in ["breathing", "shake", "handheld", "heartbeat", "wiggle", "bounce"]:
			_cinematic_layer.start_idle(node.effect)
			
		# --- Camera Moves ---
		elif node.effect == "zoom_in":
			_cinematic_layer.move_camera(1.3, Vector2.ZERO, node.duration)
		elif node.effect == "zoom_out":
			_cinematic_layer.move_camera(1.0, Vector2.ZERO, node.duration)
		elif node.effect == "pan_right":
			_cinematic_layer.move_camera(1.2, Vector2(-100, 0), node.duration)
		elif node.effect == "pan_left":
			_cinematic_layer.move_camera(1.2, Vector2(100, 0), node.duration)
			
		# --- Mood / Atmosphere ---
		elif node.effect in ["sepia", "night", "danger", "bw", "dark", "normal"]:
			_cinematic_layer.apply_mood(node.effect, 1.0)
			
		# --- Flash Effects ---
		elif node.effect.begins_with("flash"):
			var color = "white"
			if "red" in node.effect: color = "red"
			elif "black" in node.effect: color = "black"
			_cinematic_layer.trigger_flash(color, 0.5)

		# --- Action Effects ---
		elif node.effect == "impact":
			_cinematic_layer.trigger_impact(1.0)
			
	# 4. Wait duration if specified (blocking)
	
	# 4. Wait duration if specified (blocking)
	if node.duration > 0.0:
		await get_tree().create_timer(node.duration).timeout

func _on_factory_game_finished(score: int, jars_labeled: int, jars_missed: int) -> void:
	"""Мини-игра закончена"""
	print("ScenePlayer: Factory Jam Game finished. Score: %d" % score)
	# Variables are now set by the mini-game scene itself to ensure sync.
	# Money is also awarded by the mini-game scene.


func _play_card_game() -> void:
	"""Проиграть карточную игру"""
	# Создать экземпляр мини-игры
	if not _minigame_instance and CARD_GAME_SCENE:
		_minigame_instance = CARD_GAME_SCENE.instantiate()
		if _minigame_instance:
			add_child(_minigame_instance)
	
	if not _minigame_instance:
		push_error("Failed to create CardGameScene instance")
		return
	
	# Подключить сигнал окончания (если еще не подключен)
	if _minigame_instance.has_signal("card_game_finished"):
		# Отключаем предыдущее подключение, если есть
		if _minigame_instance.card_game_finished.is_connected(_on_card_game_finished):
			_minigame_instance.card_game_finished.disconnect(_on_card_game_finished)
		_minigame_instance.card_game_finished.connect(_on_card_game_finished)
	
	# Скрыть UI визуальной новеллы
	if _text_box:
		_text_box.hide()
	if _character_displayer:
		_character_displayer.hide()
	
	# Ждать окончания игры
	await _minigame_instance.card_game_finished
	
	# Удалить мини-игру
	if _minigame_instance:
		_minigame_instance.queue_free()
		_minigame_instance = null
	
	# Показать UI обратно
	if _text_box:
		_text_box.show()
		if is_inside_tree():
			await get_tree().process_frame
	if _character_displayer:
		_character_displayer.show()
		if is_inside_tree():
			await get_tree().process_frame
	
	# Небольшая задержка для плавного перехода
	await get_tree().create_timer(0.2).timeout


func _on_card_game_finished(player_won: bool, player_score: int, dealer_score: int) -> void:
	"""Обработчик окончания карточной игры"""
	print("Card game finished! Player won: ", player_won, " (Player: ", player_score, ", Dealer: ", dealer_score, ")")
	# Можно сохранить результат в переменные, если нужно
	Variables.add_variable("card_game_won", 1 if player_won else 0)
	Variables.add_variable("card_game_player_score", player_score)
	Variables.add_variable("card_game_player_score", player_score)
	Variables.add_variable("card_game_dealer_score", dealer_score)


func _play_cooking_game() -> void:
	"""Проиграть мини-игру ВАРКА"""
	print("ScenePlayer: Starting Cooking Game...")
	if _minigame_instance:
		print("ScenePlayer WARNING: _minigame_instance is not null! Cleaning up...")
		_minigame_instance.queue_free()
		_minigame_instance = null
		
	if not _minigame_instance and COOKING_SCENE:
		print("ScenePlayer: Instantiating Cooking Scene...")
		_minigame_instance = COOKING_SCENE.instantiate()
		if _minigame_instance:
			print("ScenePlayer: Adding Cooking Scene to tree...")
			add_child(_minigame_instance)
			print("ScenePlayer: Cooking Scene added.")
		else:
			push_error("ScenePlayer: Failed to instantiate COOKING_SCENE (null result).")
	
	if not _minigame_instance:
		push_error("Failed to create CookingScene instance. COOKING_SCENE resource: " + str(COOKING_SCENE))
		return
	
	# Connect signal
	if _minigame_instance.has_signal("cooking_finished"):
		if _minigame_instance.cooking_finished.is_connected(_on_cooking_game_finished):
			_minigame_instance.cooking_finished.disconnect(_on_cooking_game_finished)
		_minigame_instance.cooking_finished.connect(_on_cooking_game_finished)
	
	# Hide VN UI
	print("ScenePlayer: Hiding UI...")
	if _text_box: _text_box.hide()
	if _character_displayer: _character_displayer.hide()
	
	# Wait for finish
	print("ScenePlayer: Waiting for cooking_finished signal...")
	await _minigame_instance.cooking_finished
	print("ScenePlayer: Cooking Game Finished Signal Received.")
	
	# Cleanup
	if _minigame_instance:
		_minigame_instance.queue_free()
		_minigame_instance = null
	
	# Restore UI
	if _text_box: 
		_text_box.show()
		await get_tree().process_frame
	if _character_displayer: 
		_character_displayer.show()
		await get_tree().process_frame

func _on_cooking_game_finished(score: int) -> void:
	print("Cooking game finished! Score: ", score)
	Variables.add_variable("cooking_score", score)


func _evaluate_condition(condition: SceneParser.BaseExpression, variables_list: Dictionary) -> bool:
	"""Оценить условие с переменными"""
	if not condition:
		return false
	
	# RAW STRING CONDITION (from JSON)
	if condition.type == "RAW_STRING":
		var condition_str = str(condition.value)
		
		# OPTIMIZED EXPRESSION EVALUATION
		var expression = Expression.new()
		var input_names = variables_list.keys()
		var input_values = variables_list.values()
		
		var error = expression.parse(condition_str, input_names)
		if error != OK:
			push_error("Expression parse error: " + expression.get_error_text() + " in " + condition_str)
			return false
			
		var result = expression.execute(input_values, self)
		if expression.has_execute_failed():
			push_error("Expression execution failed: " + condition_str)
			return false
			
		print("ScenePlayer EVAL RESULT (Optimized): ", result)
		return bool(result)

	# Если условие - массив выражений (например, ["factory_jam_labeled", ">=", "15"])
	if condition.value is Array:
		var expressions = condition.value
		if expressions.size() == 0:
			return false
		
		# Собираем строку условия
		var condition_str = ""
		for expr in expressions:
			if expr is SceneParser.BaseExpression:
				# Проверяем тип через строку, так как это может быть TOKEN_TYPES
				var expr_type = expr.type
				if expr_type == SceneLexer.TOKEN_TYPES.SYMBOL or expr_type == "Symbol":
					# Это переменная или оператор
					var val = str(expr.value)  # Преобразуем в строку для безопасности
					if variables_list.has(val):
						# Заменяем переменную на её значение
						var var_value = variables_list[val]
						# Преобразуем в строку для безопасной конкатенации
						if var_value is String:
							# Если это строка-число, используем как есть (без кавычек)
							if var_value.is_valid_int() or var_value.is_valid_float():
								condition_str += var_value
							else:
								condition_str += '"' + var_value + '"'
						elif var_value is int or var_value is float:
							# Число преобразуем в строку
							condition_str += str(var_value)
						else:
							# Другие типы тоже в строку
							condition_str += str(var_value)
					else:
						# Это оператор или число - добавляем как строку
						condition_str += val
				elif expr_type == SceneLexer.TOKEN_TYPES.STRING_LITERAL or expr_type == "String":
					condition_str += '"' + str(expr.value) + '"'
				else:
					condition_str += str(expr.value)
			else:
				condition_str += str(expr)
		
		# Выполняем выражение
		if condition_str != "":
			print("ScenePlayer: Evaluating condition array: ", condition_str)
			# Безопасное выполнение выражения
			var script = GDScript.new()
			var script_code = "func eval():\n\treturn " + condition_str
			
			print("ScenePlayer EVAL DEBUG: condition_str='%s'" % condition_str)
			
			script.set_source_code(script_code)
			var parse_result = script.reload()
			if parse_result != OK:
				push_error("Failed to parse condition: " + condition_str)
				return false
			var obj = RefCounted.new()
			obj.set_script(script)
			if not obj.has_method("eval"):
				push_error("Script does not have eval method")
				return false
			var result = obj.eval()
			print("ScenePlayer EVAL RESULT: ", result, " (type: ", typeof(result), ")")
			return bool(result)
	
	# Если условие - просто переменная (проверка на truthiness)
	# Проверяем тип через строку
	var condition_type = condition.type
	if condition_type == SceneLexer.TOKEN_TYPES.SYMBOL or condition_type == "Symbol":
		if variables_list.has(condition.value):
			var value = variables_list[condition.value]
			print("ScenePlayer: Checking single variable ", condition.value, " = ", value)
			# Преобразовать в bool, учитывая числа
			if value is String:
				if value.is_valid_int():
					return int(value) != 0
				elif value.is_valid_float():
					return float(value) != 0.0
			elif value is int or value is float:
				return value != 0
			return bool(value)
		else:
			print("ScenePlayer: Variable not found for condition: ", condition.value)
		return false
	
	return false




## Saves a dictionary representing a scene to the disk using `var2str`.
func _store_scene_data(data: Dictionary, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(var_to_str(_scene_data))
	file.close()
