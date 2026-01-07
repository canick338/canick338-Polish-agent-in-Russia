## Loads and plays a scene's dialogue sequences, delegating to other nodes to display images or text.
class_name ScenePlayer
extends Node

signal scene_finished
signal restart_requested
signal transition_finished

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

var _scene_data := {}
var _cutscene_player: Control = null
var _minigame_instance: Control = null

@onready var _text_box := $TextBox
@onready var _character_displayer := $CharacterDisplayer
@onready var _anim_player: AnimationPlayer = $FadeAnimationPlayer
@onready var _background := $Background


func run_scene() -> void:
	var key = 0
	while key != KEY_END_OF_SCENE:
		# Проверяем, что key валидный
		if not _scene_data.has(key):
			push_error("Invalid key in scene data: %d (scene has %d nodes)" % [key, _scene_data.size()])
			break
		
		var node: SceneTranspiler.BaseNode = _scene_data[key]
		print("Processing node at key %d: type=%s, next=%d" % [key, node.get_class(), node.next])
		var character: Character = (
			ResourceDB.get_character(node.character)
			if "character" in node and node.character != ""
			else ResourceDB.get_narrator()
		)
		
		# Проверка на null персонажа
		if not character:
			var char_id = node.character if "character" in node and node.character != "" else "narrator"
			push_error("Character not found: " + char_id)
			character = ResourceDB.get_narrator()  # Fallback на narrator
			# Если narrator тоже не найден, создаем минимальный fallback
			if not character:
				push_error("Narrator not found! Creating fallback character.")
				# Создаем минимальный Character ресурс программно
				character = Character.new()
				character.id = "narrator"
				character.display_name = ""
				character.images = {"neutral": null}

		if node is SceneTranspiler.BackgroundCommandNode:
			var bg: Background = ResourceDB.get_background(node.background)
			if bg and bg.texture:
				_background.texture = bg.texture
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
				display_name = character.display_name if character else "Unknown"
			_text_box.display(node.line, display_name)
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
			await _play_factory_jam_game()
		"card_game", "cards", "карты", "21", "очки":
			await _play_card_game()
		_:
			push_error("Unknown minigame: " + minigame_name)


func _play_factory_jam_game() -> void:
	"""Проиграть мини-игру расфасовки повидла"""
	# Создать экземпляр мини-игры
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
	print("After minigame - factory_jam_labeled = ", vars.get("factory_jam_labeled", "NOT SET"))
	print("All variables after minigame: ", vars)
	
	# Удалить мини-игру
	if _minigame_instance:
		_minigame_instance.queue_free()
		_minigame_instance = null
	
	# Показать UI обратно
	if _text_box:
		_text_box.show()
		# Убеждаемся, что text_box видим и готов к отображению
		await get_tree().process_frame
	if _character_displayer:
		_character_displayer.show()
		await get_tree().process_frame
	
	# Небольшая задержка для плавного перехода
	await get_tree().create_timer(0.2).timeout


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
		await get_tree().process_frame
	if _character_displayer:
		_character_displayer.show()
		await get_tree().process_frame
	
	# Небольшая задержка для плавного перехода
	await get_tree().create_timer(0.2).timeout


func _on_card_game_finished(player_won: bool, player_score: int, dealer_score: int) -> void:
	"""Обработчик окончания карточной игры"""
	print("Card game finished! Player won: ", player_won, " (Player: ", player_score, ", Dealer: ", dealer_score, ")")
	# Можно сохранить результат в переменные, если нужно
	Variables.add_variable("card_game_won", 1 if player_won else 0)
	Variables.add_variable("card_game_player_score", player_score)
	Variables.add_variable("card_game_dealer_score", dealer_score)


func _evaluate_condition(condition: SceneParser.BaseExpression, variables_list: Dictionary) -> bool:
	"""Оценить условие с переменными"""
	if not condition:
		return false
	
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
			# Отладочный вывод
			print("Evaluating condition: ", condition_str)
			# Безопасное выполнение выражения
			var script = GDScript.new()
			var script_code = "func eval():\n\treturn " + condition_str
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
			print("Condition result: ", result, " (type: ", typeof(result), ")")
			return bool(result)
	
	# Если условие - просто переменная (проверка на truthiness)
	# Проверяем тип через строку
	var condition_type = condition.type
	if condition_type == SceneLexer.TOKEN_TYPES.SYMBOL or condition_type == "Symbol":
		if variables_list.has(condition.value):
			var value = variables_list[condition.value]
			# Преобразовать в bool, учитывая числа
			if value is String:
				if value.is_valid_int():
					return int(value) != 0
				elif value.is_valid_float():
					return float(value) != 0.0
			elif value is int or value is float:
				return value != 0
			return bool(value)
		return false
	
	return false

func _on_factory_game_finished(score: int, jars_labeled: int, jars_missed: int) -> void:
	"""Мини-игра закончена"""
	print("Factory Jam Game finished! Score: %d, Labeled: %d, Missed: %d" % [score, jars_labeled, jars_missed])
	# Сохранить результаты в переменные (как числа, не строки!)
	if Variables:
		# Сохраняем как числа для правильного сравнения
		Variables.add_variable("factory_jam_score", score)
		Variables.add_variable("factory_jam_labeled", jars_labeled)
		Variables.add_variable("factory_jam_missed", jars_missed)
		print("Variables saved: factory_jam_labeled = ", jars_labeled)


## Saves a dictionary representing a scene to the disk using `var2str`.
func _store_scene_data(data: Dictionary, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(var_to_str(_scene_data))
	file.close()
