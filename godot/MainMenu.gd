extends Control

signal start_game_requested
signal options_requested
signal exit_requested

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = %LoadButton
@onready var collection_button: Button = $VBoxContainer/CollectionButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

@onready var danila_highlight: TextureRect = $Characters/DanilaHighlight
@onready var boss_highlight: TextureRect = $Characters/BossHighlight
@onready var danila_texture: TextureRect = $Characters/Danila
@onready var boss_texture: TextureRect = $Characters/Boss

const MENU_MUSIC_PATH = "res://Assets/Audio/Music/Menu/menu.ogg"

# Pulse system globals
var _beat_time: float = 0.0
var _bpm: float = 85.0
var _pulse_active: bool = false
var _beat_particles: Array[ColorRect] = []
var _snow_wind_target: float = 0.0
var _bg_base_scale: Vector2 = Vector2.ONE
var _music_time: float = 0.0

# Base positions to avoid drifting
var _danila_base_y: float = 0.0
var _boss_base_y: float = 0.0

# Sounds (optional, placeholders for now)
# @onready var hover_sound: AudioStreamPlayer = $HoverSound
# @onready var click_sound: AudioStreamPlayer = $ClickSound

func _ready():
	_connect_signals()
	_setup_animations()
	
	# Initial state & setup pivots
	if $Background:
		$Background.pivot_offset = $Background.size / 2.0
		_bg_base_scale = $Background.scale
		
	if danila_highlight: 
		danila_highlight.modulate.a = 0
		danila_highlight.pivot_offset = danila_highlight.size / 2
	if boss_highlight: 
		boss_highlight.modulate.a = 0
		boss_highlight.pivot_offset = boss_highlight.size / 2
	if danila_texture:
		danila_texture.pivot_offset = danila_texture.size / 2
		_danila_base_y = danila_texture.position.y
	if boss_texture:
		boss_texture.pivot_offset = boss_texture.size / 2
		_boss_base_y = boss_texture.position.y
		
	_create_beat_particles()

func _create_beat_particles() -> void:
	# Add some subtle atmospheric 'dust' that pulses to the beat
	var vp = get_viewport_rect().size
	for i in 15:
		var p = ColorRect.new()
		p.size = Vector2(randf_range(2, 5), randf_range(2, 5))
		p.position = Vector2(randf_range(0, vp.x), randf_range(0, vp.y))
		p.color = Color(1.0, 0.9, 0.7, 0.0)
		p.mouse_filter = MOUSE_FILTER_IGNORE
		# Put them behind UI but over BG
		add_child(p)
		move_child(p, 1) # index 1 is usually right after Background
		_beat_particles.append(p)

var _smoothed_bass: float = 0.0
var _smoothed_mids: float = 0.0

func _process(delta: float) -> void:
	if not _pulse_active:
		return
	
	_beat_time += delta
	_music_time += delta
	
	# Fetch real-time frequencies
	var bass = 0.0
	var mids = 0.0
	if has_node("/root/AudioManager"):
		bass = AudioManager.get_bass_intensity()
		mids = AudioManager.get_mid_intensity()
		
	# Smooth out frequencies
	_smoothed_bass = lerp(_smoothed_bass, bass, delta * 20.0)
	_smoothed_mids = lerp(_smoothed_mids, mids, delta * 15.0)
	
	# Detect heavy kicks for sudden changes (wind direction)
	if bass > 0.85 and randf() < 0.1:
		_snow_wind_target = randf_range(-600.0, 600.0)
	
	# 1. Background Reacts to Bass (Subtle Zoom + Brightness flash)
	if $Background:
		var bg_zoom = _smoothed_bass * 0.02
		$Background.scale = lerp($Background.scale, _bg_base_scale + Vector2(bg_zoom, bg_zoom), delta * 12.0)
		var bg_flash = 1.0 + (_smoothed_bass * 0.15)
		$Background.self_modulate = Color(bg_flash, bg_flash, bg_flash, 1.0)
	
	# 2. Characters use a Hybrid animation (smooth sine floating + audio reaction)
	# This prevents uniform "jolts" and feels much more organic and complex.
	var danila_sine = sin(_music_time * 2.5) * 5.0
	var boss_sine = sin(_music_time * 2.0 + 1.5) * 5.0
	
	if danila_texture and danila_texture.modulate.a > 0.5:
		# Danila reacts more to Bass (heaviness)
		var target_y = _danila_base_y + danila_sine + (_smoothed_bass * 12.0)
		var target_rot = sin(_music_time * 1.0) * 0.5 + (_smoothed_bass * 1.5)
		danila_texture.position.y = lerp(danila_texture.position.y, target_y, delta * 10.0)
		danila_texture.rotation_degrees = lerp(danila_texture.rotation_degrees, target_rot, delta * 8.0)
		
	if boss_texture and boss_texture.modulate.a > 0.5:
		# Boss reacts more to Mids (melody/vocals) and floats differently
		var target_y = _boss_base_y + boss_sine + (_smoothed_mids * 10.0)
		var target_rot = sin(_music_time * 1.2 + 2.0) * 0.6 + (_smoothed_mids * -1.2)
		boss_texture.position.y = lerp(boss_texture.position.y, target_y, delta * 8.0)
		boss_texture.rotation_degrees = lerp(boss_texture.rotation_degrees, target_rot, delta * 8.0)
	
	# 3. Existing Snow Particles -> Music Reactive with WIND
	if $Particles:
		var hue = fmod(_beat_time, 15.0) / 15.0
		# Boost the glow heavily on bass so it exceeds 1.0 and triggers WorldEnvironment bloom
		var v_glow = 0.8 + (_smoothed_mids * 0.5) + (_smoothed_bass * 1.5)
		$Particles.color = Color.from_hsv(hue, 0.8, v_glow, 0.8)
		# Snow reacts to heavy bass by changing wind direction and speeding up gravity
		$Particles.gravity.y = lerp($Particles.gravity.y, 50.0 + (_smoothed_bass * 250.0), delta * 8.0)
		$Particles.gravity.x = lerp($Particles.gravity.x, _snow_wind_target, delta * 2.0)
		# Return wind to 0 slowly
		_snow_wind_target = lerp(_snow_wind_target, 0.0, delta * 0.5)
	
	# 4. Ambient background dust particles flash on bass strikes and fly away
	for p in _beat_particles:
		p.position.y -= delta * (15.0 + _smoothed_bass * 80.0)
		p.position.x += delta * _snow_wind_target * 0.1 # Dust blows with wind
		
		# Wrap around logic
		var vp = get_viewport_rect().size
		if p.position.y < -10: p.position.y = vp.y + 10
		if p.position.x < -10: p.position.x = vp.x + 10
		if p.position.x > vp.x + 10: p.position.x = -10
		
		p.color.a = lerp(p.color.a, 0.05 + (_smoothed_bass * 0.8), delta * 15.0)

func _connect_signals():
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
	
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
		load_button.mouse_entered.connect(_on_button_hover.bind(load_button))
		
	if collection_button:
		collection_button.pressed.connect(_on_collection_pressed)
		collection_button.mouse_entered.connect(_on_button_hover.bind(collection_button))
	
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
		options_button.mouse_entered.connect(_on_button_hover.bind(options_button))
		
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		exit_button.mouse_entered.connect(_on_button_hover.bind(exit_button))
		
	var exit_overlay = $ExitConfirmationOverlay
	if exit_overlay:
		exit_overlay.confirmed.connect(_on_confirm_exit_pressed)
		exit_overlay.cancelled.connect(_on_cancel_exit_pressed)
		
	# Character interactivity
	if danila_texture:
		danila_texture.mouse_entered.connect(_on_character_hover.bind(danila_texture, danila_highlight, true))
		danila_texture.mouse_exited.connect(_on_character_hover.bind(danila_texture, danila_highlight, false))
		
	if boss_texture:
		boss_texture.mouse_entered.connect(_on_character_hover.bind(boss_texture, boss_highlight, true))
		boss_texture.mouse_exited.connect(_on_character_hover.bind(boss_texture, boss_highlight, false))

func _setup_animations():
	# Start everything invisible for cinematic reveal
	modulate.a = 0.0
	
	var buttons = [start_button, load_button, collection_button, options_button, exit_button]
	for btn in buttons:
		if btn:
			btn.modulate.a = 0
			btn.position.x += 30  # Will slide from right
	
	# Hide characters initially
	if danila_texture:
		danila_texture.modulate.a = 0.0
	if boss_texture:
		boss_texture.modulate.a = 0.0
	
	# Cinematic reveal sequence
	_run_intro_sequence(buttons)

func _run_intro_sequence(buttons: Array) -> void:
	# Phase 1: Fade in the whole menu background from black (1.5s)
	var tw1 = create_tween()
	tw1.tween_property(self, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	await tw1.finished
	
	# Phase 2: Characters slide in from sides (0.8s)
	var tw2 = create_tween().set_parallel(true)
	if danila_texture:
		var orig_x = danila_texture.position.x
		danila_texture.position.x -= 80
		tw2.tween_property(danila_texture, "position:x", orig_x, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw2.tween_property(danila_texture, "modulate:a", 1.0, 0.8)
	if boss_texture:
		var orig_x2 = boss_texture.position.x
		boss_texture.position.x += 80
		tw2.tween_property(boss_texture, "position:x", orig_x2, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw2.tween_property(boss_texture, "modulate:a", 1.0, 0.8)
	await tw2.finished
	
	# Phase 3: Buttons cascade in from right, one by one
	for i in range(buttons.size()):
		var btn = buttons[i]
		if btn:
			var orig_x = btn.position.x - 30  # Undo the +30 offset
			var tw3 = create_tween().set_parallel(true)
			tw3.tween_property(btn, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
			tw3.tween_property(btn, "position:x", orig_x, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await tw3.finished
	
	# Start menu music after reveal
	_start_menu_music()
	
	# Activate beat pulse
	_pulse_active = true

func _start_menu_music() -> void:
	if has_node("/root/AudioManager"):
		# Scan for any music in the Menu folder
		var d = DirAccess.open("res://Assets/Audio/Music/Menu")
		if d:
			d.list_dir_begin()
			var file = d.get_next()
			while file != "":
				if not d.current_is_dir() and not file.begins_with(".") and not file.ends_with(".txt"):
					var clean = file.replace(".import", "").replace(".remap", "")
					if clean.ends_with(".ogg") or clean.ends_with(".mp3") or clean.ends_with(".wav"):
						var path = "res://Assets/Audio/Music/Menu/" + clean
						if ResourceLoader.exists(path):
							AudioManager.play_bgm(path)
							return
				file = d.get_next()

func _on_start_pressed():
	_pulse_active = false
	# Stop menu music
	if has_node("/root/AudioManager"):
		AudioManager.stop_bgm()
	# Animate out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	start_game_requested.emit()

const SETTINGS_SCENE = preload("res://SettingsMenu.tscn")
const COLLECTION_SCENE = preload("res://CollectionMenu.tscn")
const SAVE_LOAD_SCENE = preload("res://SaveLoadMenu.tscn")

func _on_options_pressed():
	options_requested.emit()
	var settings = SETTINGS_SCENE.instantiate()
	add_child(settings)
	settings.back_requested.connect(_on_settings_back)
	
	# Hide main buttons temporarily
	$VBoxContainer.visible = false

func _on_collection_pressed():
	var collection = COLLECTION_SCENE.instantiate()
	add_child(collection)
	collection.back_requested.connect(_on_settings_back) # Reuse same back handler
	
	# Hide main buttons temporarily
	$VBoxContainer.visible = false

func _on_load_pressed():
	var menu = SAVE_LOAD_SCENE.instantiate()
	menu.set_mode("load")
	add_child(menu)
	# Menu handles closing itself, or we can listen to destroy signal
	# Since it covers screen, we don't strictly need to hide buttons, but for consistency:
	# $VBoxContainer.visible = false 
	# (Actually SaveMenu usually has a semi-transparent BG, so maybe keep buttons visible underneath? 
	#  The design has opaque panel but typical overlay. keep buttons visible.)

func start_game_from_load():
	_on_start_pressed()

func _on_settings_back():
	$VBoxContainer.visible = true

func _on_exit_pressed():
	# exit_requested.emit() # Optional if we still want to signal
	$ExitConfirmationOverlay.visible = true
	$VBoxContainer.visible = false # Hide main buttons

func _on_confirm_exit_pressed():
	get_tree().quit()

func _on_cancel_exit_pressed():
	$ExitConfirmationOverlay.visible = false
	$VBoxContainer.visible = true # Show main buttons

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
