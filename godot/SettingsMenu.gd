extends Control

signal back_requested

@onready var master_slider: HSlider = $Panel/VBoxContainer/VolumeContainer/MasterSlider
@onready var fullscreen_check: CheckButton = $Panel/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var back_button: Button = $Panel/VBoxContainer/BackButton
@onready var main_container = $Panel/VBoxContainer

var lang_option: OptionButton

const SETTINGS_FILE = "user://settings.cfg"
var _config = ConfigFile.new()

func _ready():
	_setup_language_ui()
	_load_settings()
	_connect_signals()
	
	# Intro animation
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _connect_signals():
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
		
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)

func _setup_language_ui():
	# Create container for Language
	var hbox = HBoxContainer.new()
	hbox.name = "LanguageContainer"
	
	var label = Label.new()
	label.text = "UI_SETTINGS_LANGUAGE"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	lang_option = OptionButton.new()
	lang_option.name = "LanguageOption"
	lang_option.add_item("Русский", 0)
	lang_option.add_item("English", 1)
	lang_option.add_item("Polski", 2)
	
	lang_option.item_selected.connect(_on_language_selected)
	
	hbox.add_child(lang_option)
	
	# Add to main container at top (index 0)
	if main_container:
		main_container.add_child(hbox)
		main_container.move_child(hbox, 0)


func _load_settings():
	# Load from file
	var err = _config.load(SETTINGS_FILE)
	
	# Volume
	var master_vol = _config.get_value("audio", "master_volume", 1.0)
	if master_slider:
		master_slider.value = master_vol
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_vol))
	
	# Fullscreen
	var is_fullscreen = _config.get_value("display", "fullscreen", false)
	if fullscreen_check:
		fullscreen_check.button_pressed = is_fullscreen
	_set_fullscreen(is_fullscreen)
	
	# Language
	var locale = _config.get_value("localization", "current_locale", "ru")
	if lang_option:
		match locale:
			"ru": lang_option.selected = 0
			"en": lang_option.selected = 1
			"pl": lang_option.selected = 2
			_: lang_option.selected = 0

func _on_master_volume_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	_config.set_value("audio", "master_volume", value)
	_save_settings()

func _on_fullscreen_toggled(toggled: bool):
	_set_fullscreen(toggled)
	_config.set_value("display", "fullscreen", toggled)
	_save_settings()

func _on_language_selected(index: int):
	var locale = "ru"
	match index:
		0: locale = "ru"
		1: locale = "en"
		2: locale = "pl"
	
	_config.set_value("localization", "current_locale", locale)
	_save_settings()
	
	# Apply immediately via Global
	GameGlobal.apply_settings()

func _set_fullscreen(is_fullscreen: bool):
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_settings():
	_config.save(SETTINGS_FILE)

func _on_back_pressed():
	# Outro animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	back_requested.emit()
	queue_free()
