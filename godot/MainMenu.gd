extends Control

signal start_game_requested
signal options_requested
signal exit_requested

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

@onready var danila_highlight: TextureRect = $Characters/DanilaHighlight
@onready var boss_highlight: TextureRect = $Characters/BossHighlight
@onready var danila_texture: TextureRect = $Characters/Danila
@onready var boss_texture: TextureRect = $Characters/Boss

# Sounds (optional, placeholders for now)
# @onready var hover_sound: AudioStreamPlayer = $HoverSound
# @onready var click_sound: AudioStreamPlayer = $ClickSound

func _ready():
	_connect_signals()
	_setup_animations()
	
	# Initial state & setup pivots
	if danila_highlight: 
		danila_highlight.modulate.a = 0
		danila_highlight.pivot_offset = danila_highlight.size / 2
	if boss_highlight: 
		boss_highlight.modulate.a = 0
		boss_highlight.pivot_offset = boss_highlight.size / 2
	if danila_texture:
		danila_texture.pivot_offset = danila_texture.size / 2
	if boss_texture:
		boss_texture.pivot_offset = boss_texture.size / 2

func _connect_signals():
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
	
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
		options_button.mouse_entered.connect(_on_button_hover.bind(options_button))
		
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		exit_button.mouse_entered.connect(_on_button_hover.bind(exit_button))
		
	# Character interactivity
	if danila_texture:
		danila_texture.mouse_entered.connect(_on_character_hover.bind(danila_texture, danila_highlight, true))
		danila_texture.mouse_exited.connect(_on_character_hover.bind(danila_texture, danila_highlight, false))
		
	if boss_texture:
		boss_texture.mouse_entered.connect(_on_character_hover.bind(boss_texture, boss_highlight, true))
		boss_texture.mouse_exited.connect(_on_character_hover.bind(boss_texture, boss_highlight, false))

func _setup_animations():
	# Intro animation for buttons
	var buttons = [start_button, options_button, exit_button]
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn:
			btn.modulate.a = 0
			var tween = create_tween()
			tween.tween_property(btn, "modulate:a", 1.0, 0.5).set_delay(0.5 + i * 0.2)

func _on_start_pressed():
	# Animate out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	start_game_requested.emit()

const SETTINGS_SCENE = preload("res://SettingsMenu.tscn")

func _on_options_pressed():
	options_requested.emit()
	var settings = SETTINGS_SCENE.instantiate()
	add_child(settings)
	settings.back_requested.connect(_on_settings_back)
	
	# Hide main buttons temporarily
	$VBoxContainer.visible = false

func _on_settings_back():
	$VBoxContainer.visible = true

func _on_exit_pressed():
	exit_requested.emit()
	get_tree().quit()

func _on_button_hover(btn: Button):
	# Small pop effect
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _on_character_hover(char_tex: TextureRect, highlight: TextureRect, entered: bool):
	var target_scale = Vector2(1.05, 1.05) if entered else Vector2(1.0, 1.0)
	var target_alpha = 1.0 if entered else 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if char_tex:
		tween.tween_property(char_tex, "scale", target_scale, 0.2).set_trans(Tween.TRANS_CUBIC)
	
	if highlight:
		tween.tween_property(highlight, "scale", target_scale, 0.2).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(highlight, "modulate:a", target_alpha, 0.2)
