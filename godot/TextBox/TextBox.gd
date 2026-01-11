## Displays character replies in a dialogue
extends Control

## Emitted when all the text finished displaying.
signal display_finished
## Emitted when the next line was requested
signal next_requested
signal choice_made(target_id)

## Speed at which the characters appear in the text body in characters per second.
@export var display_speed := 20.0
@export var text := "": set = set_bbcode_text

@onready var _skip_button : Button = $MarginContainer/SkipButton

@onready var _name_label: Label = $NameBackground/NameLabel
@onready var _name_background: TextureRect = $NameBackground
@onready var _rich_text_label: RichTextLabel = $RichTextLabel
@onready var _choice_selector: ChoiceSelector = $ChoiceSelector

var _tween: Tween
@onready var _blinking_arrow: Control = $RichTextLabel/BlinkingArrow

@onready var _anim_player: AnimationPlayer = $FadeAnimationPlayer



func _ready() -> void:
	hide()
	_blinking_arrow.hide()

	_name_label.text = ""
	_rich_text_label.text = ""
	_rich_text_label.visible_characters = 0
	
	_choice_selector.choice_made.connect(_on_ChoiceSelector_choice_made)
	_skip_button.timer_ticked.connect(_on_SkipButton_timer_ticked)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if visible:
			advance_dialogue()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		visible = not visible


# Either complete the current line or show the next dialogue line
func advance_dialogue() -> void:
	if _blinking_arrow.visible:
		next_requested.emit()
	elif _tween:
		_tween.custom_step(100.0)


func display(_text: String, character_name := "", speed := display_speed) -> void:
	# Substitute variables: [variable_name]
	var final_text = _substitute_variables(_text)
	set_bbcode_text(final_text)

	if speed != display_speed:
		display_speed = speed

	if character_name == ResourceDB.get_narrator().display_name:
		_name_background.hide()
	elif character_name != "":
		_name_background.show()
		var was_empty = _name_label.text == ""
		_name_label.text = character_name
		
		if was_empty:
			_name_label.appear()


func display_choice(choices: Array) -> void:
	_skip_button.hide()
	_name_background.disappear()
	_rich_text_label.hide()
	_blinking_arrow.hide()

	_choice_selector.display(choices)


func set_bbcode_text(_text: String) -> void:
	text = _text
	if not is_inside_tree():
		await self.ready

	_blinking_arrow.hide()
	
	_rich_text_label.text = text
	# Required for the `_rich_text_label`'s  text to update and the code below to work.
	call_deferred("_begin_dialogue_display")


func _begin_dialogue_display() -> void:
	var character_count := _rich_text_label.get_total_character_count()
	_rich_text_label.visible_characters = 0
	_tween = create_tween()
	_tween.finished.connect(_on_tween_finished)
	_tween.tween_property(
		_rich_text_label, "visible_characters", character_count, character_count / display_speed
	)


func fade_in_async() -> void:
	_anim_player.play("fade_in")
	_anim_player.seek(0.0, true)
	await _anim_player.animation_finished


func fade_out_async() -> void:
	_anim_player.play("fade_out")
	await _anim_player.animation_finished


func _on_tween_finished() -> void:
	display_finished.emit()
	_blinking_arrow.show()


func _on_ChoiceSelector_choice_made(target_id: int) -> void:
	choice_made.emit(target_id)
	_skip_button.show()
	_name_background.appear()
	_rich_text_label.show()


func _on_SkipButton_timer_ticked() -> void:
	advance_dialogue()


func _substitute_variables(text_to_process: String) -> String:
	var result = text_to_process
	var regex = RegEx.new()
	# Matches [variable] or {variable}
	regex.compile("(\\[([a-zA-Z0-9_]+)\\]|\\{([a-zA-Z0-9_]+)\\})")
	
	var matches = regex.search_all(text_to_process)
	# Process matches in reverse order to avoid index issues if we were replacing by index,
	# but replace() handles strings so order doesn't strictly matter unless nested (unlikely here)
	for regex_match in matches:
		var full_match = regex_match.get_string(0)
		var var_name = regex_match.get_string(2) # Group 2 is [VAR] content
		if var_name == "":
			var_name = regex_match.get_string(3) # Group 3 is {VAR} content
		
		var val = null
		
		# 1. Check Dialogue Variables (Numbers/Flags)
		val = Variables.get_stored_variables_list().get(var_name)
		
		# 2. Check GameGlobal Macros (Strings/Player Name/etc)
		if val == null:
			if var_name == "PLAYER_NAME":
				# Assuming GameGlobal has this field or method
				if "player_name" in GameGlobal:
					val = GameGlobal.player_name
				else:
					val = "Danila" # Fallback
			elif var_name in GameGlobal:
				val = GameGlobal.get(var_name)
				
		if val != null:
			result = result.replace(full_match, str(val))
	
	return result
