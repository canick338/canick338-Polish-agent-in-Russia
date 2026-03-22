extends Control
## Кинематографическая заставка студии "БЫДЛО ГЕЙМС"
## Режиссёрская версия

signal splash_finished

var _slides: Array[Dictionary] = []
var _current_slide: int = -1
var _skip_pressed: bool = false

var _bg: ColorRect
var _label_main: RichTextLabel
var _label_sub: RichTextLabel
var _skip_hint: Label
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _line_top: ColorRect
var _line_bot: ColorRect
var _deco_dots: Array[Label] = []
var _loaded_sounds: Dictionary = {}  # cached sound streams

const INTRO_MUSIC_FOLDER = "res://Assets/Audio/Music/Intro"
const SPLASH_SFX_FOLDER = "res://Assets/Audio/SFX/Splash"

func _get_vp() -> Vector2:
	# Use the actual root viewport size for proper full-screen coverage
	return get_tree().root.get_visible_rect().size

func _ready() -> void:
	# Force this Control to cover entire viewport
	var vp = _get_vp()
	set_anchors_preset(PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = vp
	
	_setup_slides()
	_create_ui()
	_preload_sounds()
	_start_music()
	
	# Brief opening pause
	await get_tree().create_timer(0.8).timeout
	_play_sequence()

func _process(_delta: float) -> void:
	# Keep stretching to viewport in case of resize
	var vp = _get_vp()
	if size != vp:
		size = vp
		if _bg: _bg.size = vp
		if _line_top:
			_line_top.size.x = vp.x
		if _line_bot:
			_line_bot.position.y = vp.y - _line_bot.size.y
			_line_bot.size.x = vp.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_skip_pressed = true
	if event is InputEventMouseButton and event.pressed:
		_skip_pressed = true

# ========================
# SLIDES
# ========================

func _setup_slides() -> void:
	_slides = [
		{
			"text": "БЫДЛО ГЕЙМС",
			"subtext": "п р е д с т а в л я е т",
			"duration": 3.5,
			"bg_color": Color(0.03, 0.03, 0.08),
			"text_color": Color(1.0, 0.85, 0.15),
			"sub_color": Color(0.7, 0.6, 0.25),
			"font_size": 92,
			"sub_size": 28,
			"effect": "zoom_pulse",
			"sound_file": "logo_hit",       # Удар/свуш для лого
			"lines": true,
		},
		{
			"text": "ВНИМАНИЕ",
			"subtext": "Поведение персонажей в этой игре\nне является примером для подражания\n\nОно является СМЫСЛОМ ЖИЗНИ",
			"duration": 3.5,
			"bg_color": Color(0.12, 0.02, 0.02),
			"text_color": Color(1.0, 0.3, 0.2),
			"sub_color": Color(0.95, 0.9, 0.85),
			"font_size": 56,
			"sub_size": 24,
			"effect": "shake",
			"sound_file": "warning_slam",    # Резкий удар
			"lines": false,
		},
		{
			"text": "МИНЗДРАВ ПРЕДУПРЕЖДАЕТ",
			"subtext": "Курение убивает\n\n...но персонажей нашей игры\nэто никогда не останавливало",
			"duration": 3.5,
			"bg_color": Color(0.02, 0.02, 0.02),
			"text_color": Color(0.8, 0.8, 0.8),
			"sub_color": Color(0.6, 0.6, 0.6),
			"font_size": 40,
			"sub_size": 22,
			"effect": "typewriter",
			"sound_file": "typewriter_click", # Печатная машинка
			"lines": false,
		},
		{
			"text": "Разработчики не несут\nответственности за",
			"subtext": "сломанные клавиатуры\nиспорченное настроение\nпотерянное время\nи утраченную веру в человечество",
			"duration": 3.5,
			"bg_color": Color(0.02, 0.04, 0.02),
			"text_color": Color(0.4, 0.85, 0.4),
			"sub_color": Color(0.7, 0.8, 0.7),
			"font_size": 38,
			"sub_size": 21,
			"effect": "fade_dramatic",
			"sound_file": "whoosh",
			"lines": false,
		},
		{
			"text": "18+",
			"subtext": "После прохождения этой игры\nбудьте готовы к душевной травме\nэкзистенциальному кризису\nи переоценке жизненных ценностей",
			"duration": 3.5,
			"bg_color": Color(0.06, 0.01, 0.1),
			"text_color": Color(0.75, 0.4, 1.0),
			"sub_color": Color(0.7, 0.65, 0.8),
			"font_size": 80,
			"sub_size": 22,
			"effect": "pulse_glow",
			"sound_file": "deep_boom",        # Глубокий бас
			"lines": false,
		},
		{
			"text": "Ни один рабочий не пострадал\nпри создании этой игры",
			"subtext": "...физически\n\nморально — это другой вопрос",
			"duration": 3.0,
			"bg_color": Color(0.05, 0.03, 0.01),
			"text_color": Color(0.95, 0.8, 0.5),
			"sub_color": Color(0.7, 0.6, 0.45),
			"font_size": 36,
			"sub_size": 22,
			"effect": "slide_up",
			"sound_file": "whoosh",
			"lines": false,
		},
		{
			"text": "Создано на движке\nGODOT ENGINE",
			"subtext": "потому что на Unity мы не потянули\nа на Unreal даже не пытались",
			"duration": 3.0,
			"bg_color": Color(0.01, 0.04, 0.08),
			"text_color": Color(0.45, 0.7, 1.0),
			"sub_color": Color(0.45, 0.45, 0.5),
			"font_size": 38,
			"sub_size": 19,
			"effect": "fade_dramatic",
			"sound_file": "whoosh",
			"lines": false,
		},
		{
			"text": "Все совпадения с реальными\nлюдьми и событиями",
			"subtext": "абсолютно неслучайны\nОни знают за что",
			"duration": 3.0,
			"bg_color": Color(0.06, 0.06, 0.04),
			"text_color": Color(0.95, 0.93, 0.88),
			"sub_color": Color(0.85, 0.65, 0.3),
			"font_size": 42,
			"sub_size": 24,
			"effect": "fade_dramatic",
			"sound_file": "reverse_cymbal",   # Нарастание
			"lines": true,
		},
		{
			"text": "Если вам не понравится игра",
			"subtext": "то вы просто не поняли\nглубокий замысел автора\n\nпопробуйте ещё раз",
			"duration": 3.0,
			"bg_color": Color(0.04, 0.02, 0.05),
			"text_color": Color(0.85, 0.75, 0.95),
			"sub_color": Color(0.65, 0.6, 0.7),
			"font_size": 38,
			"sub_size": 21,
			"effect": "slide_up",
			"sound_file": "whoosh",
			"lines": false,
		},
		{
			"text": "АГЕНТ В РОССИИ",
			"subtext": "история которую вы не заслужили\nно которую получите",
			"duration": 4.5,
			"bg_color": Color(0.0, 0.0, 0.0),
			"text_color": Color(1.0, 0.9, 0.1),
			"sub_color": Color(0.65, 0.6, 0.4),
			"font_size": 88,
			"sub_size": 24,
			"effect": "epic_zoom",
			"sound_file": "title_reveal",     # Эпичный удар
			"lines": true,
		},
	]

# ========================
# UI
# ========================

func _create_ui() -> void:
	var vp = _get_vp()
	
	# Background — oversized to guarantee coverage
	_bg = ColorRect.new()
	_bg.position = Vector2(-10, -10)
	_bg.size = vp + Vector2(20, 20)
	_bg.color = Color.BLACK
	add_child(_bg)
	
	# Cinematic lines top/bottom — full width guaranteed
	_line_top = ColorRect.new()
	_line_top.position = Vector2(-10, 0)
	_line_top.size = Vector2(vp.x + 20, 3)
	_line_top.color = Color(1.0, 0.85, 0.2, 0.0)
	_line_top.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_line_top)
	
	_line_bot = ColorRect.new()
	_line_bot.position = Vector2(-10, vp.y - 3)
	_line_bot.size = Vector2(vp.x + 20, 3)
	_line_bot.color = Color(1.0, 0.85, 0.2, 0.0)
	_line_bot.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_line_bot)
	
	# Decorative dots
	_create_deco(vp)
	
	# Main text
	_label_main = RichTextLabel.new()
	_label_main.bbcode_enabled = false
	_label_main.scroll_active = false
	_label_main.fit_content = true
	_label_main.size = Vector2(vp.x * 0.85, 300)
	_label_main.position = Vector2(vp.x * 0.075, vp.y * 0.5 - 130)
	_label_main.modulate.a = 0.0
	_label_main.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_label_main)
	
	# Sub text
	_label_sub = RichTextLabel.new()
	_label_sub.bbcode_enabled = false
	_label_sub.scroll_active = false
	_label_sub.fit_content = true
	_label_sub.size = Vector2(vp.x * 0.75, 280)
	_label_sub.position = Vector2(vp.x * 0.125, vp.y * 0.5 + 30)
	_label_sub.modulate.a = 0.0
	_label_sub.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_label_sub)
	
	# Skip hint
	_skip_hint = Label.new()
	_skip_hint.text = "Нажмите любую клавишу чтобы пропустить"
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	_skip_hint.position = Vector2(vp.x - 370, vp.y - 30)
	_skip_hint.modulate.a = 0.0
	_skip_hint.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_skip_hint)
	
	# Visible skip button
	var skip_btn = Button.new()
	skip_btn.text = "ПРОПУСТИТЬ >>"
	skip_btn.add_theme_font_size_override("font_size", 16)
	skip_btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
	skip_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.4))
	skip_btn.flat = true
	skip_btn.position = Vector2(vp.x - 200, vp.y - 55)
	skip_btn.size = Vector2(180, 40)
	skip_btn.modulate.a = 0.0
	skip_btn.pressed.connect(func():
		_skip_pressed = true
		# Play skip sound
		if _loaded_sounds.has("transition"):
			_sfx_player.stream = _loaded_sounds["transition"]
			_sfx_player.play()
		elif has_node("/root/AudioManager"):
			AudioManager.play_event("ui_click")
	)
	add_child(skip_btn)
	
	var tw_btn = create_tween()
	tw_btn.tween_property(skip_btn, "modulate:a", 0.8, 1.0).set_delay(2.0)
	var tw = create_tween()
	tw.tween_property(_skip_hint, "modulate:a", 0.6, 1.5).set_delay(3.0)

func _create_deco(vp: Vector2) -> void:
	for i in 8:
		for side in [0, 1]:
			var dot = Label.new()
			dot.text = [".", "+", "-", "*"][randi() % 4]
			dot.add_theme_font_size_override("font_size", randi_range(10, 22))
			dot.add_theme_color_override("font_color", Color(0.4, 0.35, 0.2))
			var x_pos = randf_range(15, 90) if side == 0 else randf_range(vp.x - 90, vp.x - 15)
			dot.position = Vector2(x_pos, randf_range(60, vp.y - 60))
			dot.modulate.a = 0.0
			dot.mouse_filter = MOUSE_FILTER_IGNORE
			add_child(dot)
			_deco_dots.append(dot)

func _show_lines(show: bool, color: Color = Color(1.0, 0.85, 0.2)) -> void:
	var vp = _get_vp()
	var h = 4.0 if show else 1.0
	var a = 0.9 if show else 0.0
	var c = Color(color.r, color.g, color.b, a)
	
	# Ensure lines stretch
	_line_top.size.x = vp.x + 20
	_line_bot.size.x = vp.x + 20
	_line_bot.position.y = vp.y - h
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_line_top, "size:y", h, 0.8)
	tw.tween_property(_line_top, "color", c, 0.8)
	tw.tween_property(_line_bot, "size:y", h, 0.8)
	tw.tween_property(_line_bot, "color", c, 0.8)
	
	for dot in _deco_dots:
		var da = randf_range(0.2, 0.5) if show else 0.0
		tw.tween_property(dot, "modulate:a", da, randf_range(0.6, 1.5))
		if show:
			tw.tween_property(dot, "position:y", dot.position.y + randf_range(-20, 20), 2.0)

# ========================
# MUSIC
# ========================

func _start_music() -> void:
	var d = DirAccess.open(INTRO_MUSIC_FOLDER)
	if not d: return
	d.list_dir_begin()
	var file = d.get_next()
	while file != "":
		if not d.current_is_dir() and not file.begins_with(".") and not file.ends_with(".txt"):
			var clean = file.replace(".import", "").replace(".remap", "")
			if clean.ends_with(".ogg") or clean.ends_with(".mp3") or clean.ends_with(".wav"):
				var path = INTRO_MUSIC_FOLDER + "/" + clean
				if ResourceLoader.exists(path):
					_music_player = AudioStreamPlayer.new()
					_music_player.stream = load(path)
					_music_player.volume_db = -80.0
					add_child(_music_player)
					_music_player.play()
					var tw = create_tween()
					tw.tween_property(_music_player, "volume_db", -6.0, 3.0)
					return
		file = d.get_next()

func _preload_sounds() -> void:
	# Create SFX player
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.volume_db = -4.0
	add_child(_sfx_player)
	
	# Scan SFX folder and preload all .ogg files
	var d = DirAccess.open(SPLASH_SFX_FOLDER)
	if not d: return
	d.list_dir_begin()
	var file = d.get_next()
	while file != "":
		if not d.current_is_dir() and not file.begins_with(".") and not file.ends_with(".txt"):
			var clean = file.replace(".import", "").replace(".remap", "")
			if clean.ends_with(".ogg") or clean.ends_with(".mp3") or clean.ends_with(".wav"):
				var path = SPLASH_SFX_FOLDER + "/" + clean
				if ResourceLoader.exists(path):
					var key = clean.get_basename()  # "logo_hit.ogg" -> "logo_hit"
					_loaded_sounds[key] = load(path)
		file = d.get_next()

func _play_sfx(sound_name: String) -> void:
	if sound_name == "": return
	
	# First try loaded file from SFX/Splash folder
	if _loaded_sounds.has(sound_name):
		_sfx_player.stream = _loaded_sounds[sound_name]
		_sfx_player.play()
		return
	
	# Fallback: generate synth sound based on the sound name
	_play_synth_fallback(sound_name)

func _play_synth_fallback(sound_name: String) -> void:
	var sample_rate := 22050
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	
	# Different sounds for different events
	var freq := 120.0
	var duration := 0.3
	var decay_power := 2.0
	
	match sound_name:
		"logo_hit":        freq = 80.0;  duration = 0.6;  decay_power = 1.5
		"title_reveal":    freq = 60.0;  duration = 0.8;  decay_power = 1.2
		"warning_slam":    freq = 200.0; duration = 0.3;  decay_power = 3.0
		"deep_boom":       freq = 40.0;  duration = 0.7;  decay_power = 1.5
		"reverse_cymbal":  freq = 800.0; duration = 0.5;  decay_power = 0.5
		"typewriter_click":freq = 1200.0;duration = 0.05; decay_power = 4.0
		_:                 freq = 300.0; duration = 0.15; decay_power = 3.0
	
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in num_samples:
		var t := float(i) / sample_rate
		var env := pow(1.0 - float(i) / num_samples, decay_power)
		var val := sin(t * freq * TAU) * env
		# Add some harmonic richness for impact sounds
		if sound_name in ["logo_hit", "title_reveal", "deep_boom"]:
			val += sin(t * freq * 2.0 * TAU) * env * 0.3
			val += sin(t * freq * 0.5 * TAU) * env * 0.5
		var int_val := int(clampf(val, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF
	
	audio.data = data
	_sfx_player.stream = audio
	_sfx_player.volume_db = -5.0
	_sfx_player.play()

func _play_transition_sfx() -> void:
	# Play transition whoosh between slides if available
	if _loaded_sounds.has("transition"):
		_sfx_player.stream = _loaded_sounds["transition"]
		_sfx_player.play()

# ========================
# SEQUENCE
# ========================

func _play_sequence() -> void:
	for i in _slides.size():
		if _skip_pressed: break
		_current_slide = i
		await _show_slide(_slides[i])
		if not _skip_pressed and i < _slides.size() - 1:
			_play_transition_sfx()
			await get_tree().create_timer(0.25).timeout
	_finish()

func _show_slide(slide: Dictionary) -> void:
	var vp = _get_vp()
	var cy = vp.y / 2.0
	var duration = slide.get("duration", 4.0)
	var effect = slide.get("effect", "fade_dramatic")
	
	# Text setup
	_label_main.clear()
	_label_main.add_theme_font_size_override("normal_font_size", slide.get("font_size", 48))
	_label_main.add_theme_color_override("default_color", slide.get("text_color", Color.WHITE))
	_label_main.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_label_main.add_text(slide.get("text", ""))
	_label_main.pop()
	
	_label_sub.clear()
	_label_sub.add_theme_font_size_override("normal_font_size", slide.get("sub_size", 22))
	_label_sub.add_theme_color_override("default_color", slide.get("sub_color", Color.GRAY))
	_label_sub.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_label_sub.add_text(slide.get("subtext", ""))
	_label_sub.pop()
	
	# Reset positions
	_label_main.size = Vector2(vp.x * 0.85, 300)
	_label_main.position = Vector2(vp.x * 0.075, cy - 130)
	_label_sub.size = Vector2(vp.x * 0.75, 280)
	_label_sub.position = Vector2(vp.x * 0.125, cy + 30)
	_label_main.scale = Vector2.ONE
	_label_main.pivot_offset = _label_main.size / 2.0
	_label_sub.scale = Vector2.ONE
	
	# BG transition
	var tw_bg = create_tween()
	tw_bg.tween_property(_bg, "color", slide.get("bg_color", Color.BLACK), 1.2)
	
	# Lines
	_show_lines(slide.get("lines", false), slide.get("text_color", Color.WHITE))
	
	# Sound
	_play_sfx(slide.get("sound_file", ""))
	
	match effect:
		"zoom_pulse": await _fx_zoom_pulse(duration)
		"shake": await _fx_shake(duration)
		"typewriter": await _fx_typewriter(duration)
		"pulse_glow": await _fx_pulse_glow(duration)
		"slide_up": await _fx_slide_up(duration)
		"epic_zoom": await _fx_epic_zoom(duration)
		_: await _fx_fade(duration)

# ========================
# EFFECTS
# ========================

func _fade_in(t: float = 1.2, d: float = 0.8) -> void:
	_label_main.modulate.a = 0.0
	_label_sub.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_label_main, "modulate:a", 1.0, t)
	tw.tween_property(_label_sub, "modulate:a", 1.0, t + 0.3).set_delay(d)
	await tw.finished

func _fade_out(t: float = 0.8) -> void:
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_label_main, "modulate:a", 0.0, t)
	tw.tween_property(_label_sub, "modulate:a", 0.0, t)
	await tw.finished

func _fx_fade(duration: float) -> void:
	await _fade_in(1.5, 1.0)
	await _wait(duration - 3.0)
	await _fade_out(1.0)

func _fx_zoom_pulse(duration: float) -> void:
	_label_main.modulate.a = 0.0
	_label_sub.modulate.a = 0.0
	_label_main.scale = Vector2(0.2, 0.2)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_label_main, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label_main, "modulate:a", 1.0, 1.0)
	await tw.finished
	
	var ts = create_tween()
	ts.tween_property(_label_sub, "modulate:a", 1.0, 1.2)
	await ts.finished
	
	var pulse = create_tween().set_loops(4)
	pulse.tween_property(_label_main, "scale", Vector2(1.04, 1.04), 0.6)
	pulse.tween_property(_label_main, "scale", Vector2.ONE, 0.6)
	
	await _wait(duration - 4.0)
	pulse.kill()
	
	var tw2 = create_tween().set_parallel(true)
	tw2.tween_property(_label_main, "scale", Vector2(1.4, 1.4), 0.8)
	tw2.tween_property(_label_main, "modulate:a", 0.0, 0.8)
	tw2.tween_property(_label_sub, "modulate:a", 0.0, 0.6)
	await tw2.finished

func _fx_shake(duration: float) -> void:
	_label_main.modulate.a = 0.0
	_label_sub.modulate.a = 0.0
	_label_main.scale = Vector2(2.5, 2.5)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_label_main, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_label_main, "modulate:a", 1.0, 0.2)
	await tw.finished
	
	var orig = _label_main.position
	for i in 10:
		if _skip_pressed: break
		var intensity = 14.0 * (1.0 - float(i) / 10.0)
		_label_main.position = orig + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		await get_tree().create_timer(0.04).timeout
	_label_main.position = orig
	
	await _wait(0.6)
	var tw2 = create_tween()
	tw2.tween_property(_label_sub, "modulate:a", 1.0, 1.2)
	await tw2.finished
	
	await _wait(duration - 3.0)
	await _fade_out(0.6)

func _fx_typewriter(duration: float) -> void:
	_label_main.modulate.a = 1.0
	_label_sub.modulate.a = 0.0
	
	var full_text = _label_main.get_parsed_text()
	_label_main.clear()
	_label_main.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_label_main.add_text("")
	_label_main.pop()
	
	var typed = ""
	for ch in full_text:
		if _skip_pressed:
			typed = full_text
			break
		typed += ch
		_label_main.clear()
		_label_main.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		_label_main.add_text(typed)
		_label_main.pop()
		await get_tree().create_timer(0.08).timeout
	
	await _wait(0.5)
	var tw = create_tween()
	tw.tween_property(_label_sub, "modulate:a", 1.0, 1.2).set_delay(0.3)
	await tw.finished
	
	await _wait(duration - 3.5)
	await _fade_out(0.8)

func _fx_pulse_glow(duration: float) -> void:
	await _fade_in(1.0, 0.8)
	
	var glow = create_tween().set_loops(5)
	glow.tween_property(_label_main, "modulate", Color(1.4, 1.3, 1.6, 1.0), 0.6)
	glow.tween_property(_label_main, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)
	
	await _wait(duration - 2.5)
	glow.kill()
	_label_main.modulate = Color.WHITE
	await _fade_out(0.8)

func _fx_slide_up(duration: float) -> void:
	var vp = _get_vp()
	var cy = vp.y / 2.0
	_label_main.modulate.a = 0.0
	_label_sub.modulate.a = 0.0
	_label_main.position.y = cy + 150
	_label_sub.position.y = cy + 300
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_label_main, "position:y", cy - 130.0, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_label_main, "modulate:a", 1.0, 1.0)
	tw.tween_property(_label_sub, "position:y", cy + 30.0, 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_label_sub, "modulate:a", 1.0, 1.0).set_delay(0.5)
	await tw.finished
	
	await _wait(duration - 3.0)
	
	var tw2 = create_tween().set_parallel(true)
	tw2.tween_property(_label_main, "position:y", cy - 400.0, 0.8)
	tw2.tween_property(_label_main, "modulate:a", 0.0, 0.7)
	tw2.tween_property(_label_sub, "modulate:a", 0.0, 0.6)
	await tw2.finished

func _fx_epic_zoom(duration: float) -> void:
	_label_main.modulate.a = 0.0
	_label_sub.modulate.a = 0.0
	_label_main.scale = Vector2(0.05, 0.05)
	
	# Warm white flash
	_bg.color = Color(1.0, 0.95, 0.85)
	_play_sfx("unlock")
	var fl = create_tween()
	fl.tween_property(_bg, "color", Color.BLACK, 0.5)
	await fl.finished
	
	# Very slow zoom
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_label_main, "scale", Vector2.ONE, 2.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label_main, "modulate:a", 1.0, 1.2)
	await tw.finished
	
	await _wait(0.5)
	var ts = create_tween()
	ts.tween_property(_label_sub, "modulate:a", 1.0, 1.5)
	
	var drift = create_tween().set_loops(3)
	drift.tween_property(_label_main, "scale", Vector2(1.02, 1.02), 1.2)
	drift.tween_property(_label_main, "scale", Vector2.ONE, 1.2)
	
	await _wait(duration - 4.5)
	drift.kill()
	
	var tw2 = create_tween().set_parallel(true)
	tw2.tween_property(_label_main, "modulate:a", 0.0, 1.5)
	tw2.tween_property(_label_sub, "modulate:a", 0.0, 1.2)
	await tw2.finished

# ========================
# UTILS
# ========================

func _wait(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		if _skip_pressed: return
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05

func _finish() -> void:
	_show_lines(false)
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(_bg, "color", Color.BLACK, 0.8)
	tw.tween_property(_label_main, "modulate:a", 0.0, 0.6)
	tw.tween_property(_label_sub, "modulate:a", 0.0, 0.6)
	tw.tween_property(_skip_hint, "modulate:a", 0.0, 0.3)
	for dot in _deco_dots:
		tw.tween_property(dot, "modulate:a", 0.0, 0.3)
	if _music_player:
		tw.tween_property(_music_player, "volume_db", -80.0, 1.5)
	await tw.finished
	
	# Brief hold then signal — menu will handle the reveal
	await get_tree().create_timer(0.3).timeout
	
	if _music_player: _music_player.stop()
	splash_finished.emit()
	queue_free()
