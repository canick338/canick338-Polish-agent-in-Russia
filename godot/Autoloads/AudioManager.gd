# AudioManager — Professional Sound Design System
# Centralized audio management with crossfade, ducking, and per-context music.
#
# API:
#   AudioManager.play_bgm("res://Assets/Audio/Music/track.ogg")
#   AudioManager.stop_bgm()
#   AudioManager.play_sfx("res://Assets/Audio/SFX/click.ogg")
#   AudioManager.play_ambience("res://Assets/Audio/Ambience/city.ogg")
#   AudioManager.stop_ambience()
#   AudioManager.play_radio("res://Assets/Audio/Radio/station/track.ogg")
#   AudioManager.stop_radio()
#   AudioManager.set_bgm_volume(db)  # -80.0 to 0.0

extends Node

# ========================
# CONFIGURATION
# ========================
const CROSSFADE_TIME: float = 2.0
const DUCK_VOLUME_DB: float = -20.0
const NORMAL_VOLUME_DB: float = -10.0
const SFX_POOL_SIZE: int = 4

# ========================
# INTERNAL STATE
# ========================
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _bgm_active: AudioStreamPlayer  # Points to whichever is currently playing
var _bgm_current_path: String = ""
var _bgm_ducked: bool = false

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0

var _ambience: AudioStreamPlayer
var _ambience_current_path: String = ""

var _radio: AudioStreamPlayer
var _radio_current_path: String = ""

func _ready() -> void:
	# --- BGM: Two players for crossfade ---
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.bus = "Master"
	_bgm_a.volume_db = NORMAL_VOLUME_DB
	add_child(_bgm_a)
	
	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.bus = "Master"
	_bgm_b.volume_db = -80.0
	add_child(_bgm_b)
	
	_bgm_active = _bgm_a
	
	# --- SFX: Pool of players ---
	for i in SFX_POOL_SIZE:
		var sfx = AudioStreamPlayer.new()
		sfx.bus = "Master"
		sfx.volume_db = -5.0
		add_child(sfx)
		_sfx_pool.append(sfx)
	
	# --- Ambience ---
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Master"
	_ambience.volume_db = -15.0
	add_child(_ambience)
	
	# --- Radio ---
	_radio = AudioStreamPlayer.new()
	_radio.bus = "Master"
	_radio.volume_db = -8.0
	add_child(_radio)

# ========================
# 🎵 BGM (Background Music)
# ========================

## Play a background music track with crossfade.
## If the same track is already playing, does nothing.
func play_bgm(path: String, fade_time: float = CROSSFADE_TIME) -> void:
	if path == _bgm_current_path and _bgm_active.playing:
		return  # Already playing this track
	
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: BGM not found: " + path)
		return
	
	_bgm_current_path = path
	var stream = load(path)
	if not stream:
		return
	
	# Determine which player is inactive
	var new_player = _bgm_b if _bgm_active == _bgm_a else _bgm_a
	var old_player = _bgm_active
	
	# Setup new player
	new_player.stream = stream
	var target_vol = DUCK_VOLUME_DB if _bgm_ducked else NORMAL_VOLUME_DB
	new_player.volume_db = -80.0
	new_player.play()
	
	# Crossfade
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(new_player, "volume_db", target_vol, fade_time).set_trans(Tween.TRANS_SINE)
	if old_player.playing:
		tw.tween_property(old_player, "volume_db", -80.0, fade_time).set_trans(Tween.TRANS_SINE)
	
	# After crossfade, stop old player
	await tw.finished
	if old_player != new_player:
		old_player.stop()
	
	_bgm_active = new_player
	print("🎵 BGM: ", path.get_file())

## Stop BGM with fade out.
func stop_bgm(fade_time: float = CROSSFADE_TIME) -> void:
	if not _bgm_active.playing:
		return
	_bgm_current_path = ""
	var tw = create_tween()
	tw.tween_property(_bgm_active, "volume_db", -80.0, fade_time).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_bgm_active.stop()

## Duck BGM (lower volume when radio/dialogue plays).
func duck_bgm() -> void:
	_bgm_ducked = true
	if _bgm_active.playing:
		var tw = create_tween()
		tw.tween_property(_bgm_active, "volume_db", DUCK_VOLUME_DB, 0.5)

## Unduck BGM (restore volume).
func unduck_bgm() -> void:
	_bgm_ducked = false
	if _bgm_active.playing:
		var tw = create_tween()
		tw.tween_property(_bgm_active, "volume_db", NORMAL_VOLUME_DB, 0.8)

## Check if BGM is currently playing.
func is_bgm_playing() -> bool:
	return _bgm_active.playing

## Get the current BGM path.
func get_current_bgm() -> String:
	return _bgm_current_path

# ========================
# 🔊 SFX (Sound Effects)
# ========================

## Play a one-shot sound effect. Uses a pool so multiple SFX can overlap.
func play_sfx(path: String, volume_db: float = -5.0) -> void:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: SFX not found: " + path)
		return
	
	var stream = load(path)
	if not stream:
		return
	
	# Find a free player or use round-robin
	var player = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % SFX_POOL_SIZE
	
	player.stream = stream
	player.volume_db = volume_db
	player.play()

# ========================
# 🌧️ AMBIENCE
# ========================

## Play ambient background sound (city noise, rain, night crickets, etc.)
func play_ambience(path: String, fade_time: float = 3.0) -> void:
	if path == _ambience_current_path and _ambience.playing:
		return
	
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: Ambience not found: " + path)
		return
	
	_ambience_current_path = path
	var stream = load(path)
	if not stream:
		return
	
	# Fade out old, then fade in new
	if _ambience.playing:
		var tw_out = create_tween()
		tw_out.tween_property(_ambience, "volume_db", -80.0, fade_time * 0.5)
		await tw_out.finished
	
	_ambience.stream = stream
	_ambience.volume_db = -80.0
	_ambience.play()
	var tw_in = create_tween()
	tw_in.tween_property(_ambience, "volume_db", -15.0, fade_time)
	print("🌧️ Ambience: ", path.get_file())

## Stop ambience with fade out.
func stop_ambience(fade_time: float = 2.0) -> void:
	if not _ambience.playing:
		return
	_ambience_current_path = ""
	var tw = create_tween()
	tw.tween_property(_ambience, "volume_db", -80.0, fade_time)
	await tw.finished
	_ambience.stop()

# ========================
# 📻 RADIO
# ========================

## Play radio track. Automatically ducks BGM.
func play_radio(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: Radio track not found: " + path)
		return
	
	_radio_current_path = path
	var stream = load(path)
	if not stream:
		return
	
	duck_bgm()
	
	_radio.stream = stream
	_radio.volume_db = -80.0
	_radio.play()
	var tw = create_tween()
	tw.tween_property(_radio, "volume_db", -8.0, 0.5)
	print("📻 Radio: ", path.get_file())

## Stop radio. Restores BGM volume.
func stop_radio(fade_time: float = 0.5) -> void:
	if not _radio.playing:
		unduck_bgm()
		return
	_radio_current_path = ""
	var tw = create_tween()
	tw.tween_property(_radio, "volume_db", -80.0, fade_time)
	await tw.finished
	_radio.stop()
	unduck_bgm()

## Check if radio is playing.
func is_radio_playing() -> bool:
	return _radio.playing

## Get the radio AudioStreamPlayer (for PhoneHUD to connect signals).
func get_radio_player() -> AudioStreamPlayer:
	return _radio

# ========================
# 🎮 QUEST / SCENE SOUND EVENTS
# ========================
# Named events for easy integration. Falls back to procedural synth if no file exists.

const SFX_PATHS = {
	# UI / Quest
	"text_appear": "res://Assets/Audio/SFX/UI/text_appear.ogg",
	"choice_appear": "res://Assets/Audio/SFX/UI/choice_appear.ogg",
	"choice_select": "res://Assets/Audio/SFX/UI/choice_select.ogg",
	"transition_fade": "res://Assets/Audio/SFX/UI/transition_fade.ogg",
	"time_pass": "res://Assets/Audio/SFX/UI/time_pass.ogg",
	"sleep": "res://Assets/Audio/SFX/UI/sleep.ogg",
	"unlock": "res://Assets/Audio/SFX/UI/unlock.ogg",
	"quest_update": "res://Assets/Audio/SFX/UI/quest_update.ogg",
	"notification": "res://Assets/Audio/SFX/UI/notification.ogg",
	"map_node_hover": "res://Assets/Audio/SFX/UI/map_hover.ogg",
	"map_node_click": "res://Assets/Audio/SFX/UI/map_click.ogg",
	"phone_open": "res://Assets/Audio/SFX/UI/phone_open.ogg",
	"phone_close": "res://Assets/Audio/SFX/UI/phone_close.ogg",
	# Card Game
	"card_deal": "res://Assets/Audio/SFX/Minigame/card_deal.ogg",
	"card_flip": "res://Assets/Audio/SFX/Minigame/card_flip.ogg",
	"card_bust": "res://Assets/Audio/SFX/Minigame/card_bust.ogg",
	"round_win": "res://Assets/Audio/SFX/Minigame/round_win.ogg",
	"round_lose": "res://Assets/Audio/SFX/Minigame/round_lose.ogg",
	"match_victory": "res://Assets/Audio/SFX/Minigame/match_victory.ogg",
	"match_defeat": "res://Assets/Audio/SFX/Minigame/match_defeat.ogg",
	"bet_placed": "res://Assets/Audio/SFX/Minigame/bet_placed.ogg",
	"coin_clink": "res://Assets/Audio/SFX/Minigame/coin_clink.ogg",
	# Cooking
	"ingredient_drop": "res://Assets/Audio/SFX/Minigame/ingredient_drop.ogg",
	"ingredient_wrong": "res://Assets/Audio/SFX/Minigame/ingredient_wrong.ogg",
	"cook_stir": "res://Assets/Audio/SFX/Minigame/cook_stir.ogg",
	"cook_win": "res://Assets/Audio/SFX/Minigame/cook_win.ogg",
	"cook_fail": "res://Assets/Audio/SFX/Minigame/cook_fail.ogg",
	"temp_warning": "res://Assets/Audio/SFX/Minigame/temp_warning.ogg",
	"ingredient_request": "res://Assets/Audio/SFX/Minigame/ingredient_request.ogg",
	# General Minigame
	"minigame_start": "res://Assets/Audio/SFX/Minigame/minigame_start.ogg",
	"minigame_countdown": "res://Assets/Audio/SFX/Minigame/minigame_countdown.ogg",
}

## Play a named sound event. If the .ogg file exists, use it. Otherwise, synthesize a tone.
func play_event(event_name: String) -> void:
	var path = SFX_PATHS.get(event_name, "")
	if path != "" and ResourceLoader.exists(path):
		play_sfx(path)
		return
	
	# Fallback: procedural synth
	_play_synth_event(event_name)

## Synthesize sounds procedurally (no files needed).
func _play_synth_event(event_name: String) -> void:
	var freq := 440.0
	var duration := 0.1
	var volume := -10.0
	var wave_type := 0  # 0=sine, 1=square
	
	match event_name:
		"text_appear":
			freq = 800.0; duration = 0.04; volume = -20.0
		"choice_appear":
			freq = 600.0; duration = 0.12; volume = -12.0
		"choice_select":
			freq = 900.0; duration = 0.08; volume = -10.0
		"transition_fade":
			freq = 300.0; duration = 0.3; volume = -15.0
		"time_pass":
			freq = 500.0; duration = 0.2; volume = -12.0
		"sleep":
			freq = 250.0; duration = 0.5; volume = -15.0
		"unlock":
			freq = 1200.0; duration = 0.15; volume = -8.0; wave_type = 1
		"quest_update":
			freq = 700.0; duration = 0.2; volume = -8.0
		"notification":
			freq = 1000.0; duration = 0.1; volume = -10.0
		"map_node_hover":
			freq = 650.0; duration = 0.05; volume = -18.0
		"map_node_click":
			freq = 850.0; duration = 0.1; volume = -10.0
		"phone_open":
			freq = 400.0; duration = 0.15; volume = -12.0
		"phone_close":
			freq = 350.0; duration = 0.12; volume = -14.0
		# === Card Game ===
		"card_deal":
			freq = 1200.0; duration = 0.06; volume = -12.0
		"card_flip":
			freq = 1400.0; duration = 0.05; volume = -14.0
		"card_bust":
			freq = 150.0; duration = 0.4; volume = -8.0; wave_type = 1
		"round_win":
			freq = 880.0; duration = 0.25; volume = -6.0
		"round_lose":
			freq = 220.0; duration = 0.35; volume = -10.0
		"match_victory":
			freq = 1100.0; duration = 0.5; volume = -4.0
		"match_defeat":
			freq = 130.0; duration = 0.6; volume = -8.0
		"bet_placed":
			freq = 700.0; duration = 0.1; volume = -10.0
		"coin_clink":
			freq = 2000.0; duration = 0.04; volume = -12.0
		# === Cooking ===
		"ingredient_drop":
			freq = 500.0; duration = 0.15; volume = -6.0
		"ingredient_wrong":
			freq = 180.0; duration = 0.25; volume = -8.0; wave_type = 1
		"cook_stir":
			freq = 350.0; duration = 0.08; volume = -18.0
		"cook_win":
			freq = 1000.0; duration = 0.4; volume = -4.0
		"cook_fail":
			freq = 100.0; duration = 0.5; volume = -6.0; wave_type = 1
		"temp_warning":
			freq = 1500.0; duration = 0.08; volume = -10.0; wave_type = 1
		"ingredient_request":
			freq = 660.0; duration = 0.15; volume = -8.0
		# === General Minigame ===
		"minigame_start":
			freq = 750.0; duration = 0.3; volume = -6.0
		"minigame_countdown":
			freq = 550.0; duration = 0.1; volume = -10.0
		_:
			freq = 440.0; duration = 0.1; volume = -15.0
	
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in num_samples:
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / num_samples)  # Linear fade out
		envelope = envelope * envelope  # Squared for smoother decay
		var sample_val := 0.0
		if wave_type == 0:
			sample_val = sin(t * freq * TAU) * envelope
		else:
			sample_val = (1.0 if sin(t * freq * TAU) > 0 else -1.0) * envelope * 0.3
		var int_val := int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF
	
	audio.data = data
	
	var player = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % SFX_POOL_SIZE
	player.stream = audio
	player.volume_db = volume
	player.play()

# ========================
# 🎬 SCENE BGM SUPPORT
# ========================

## Play BGM for a specific scene/quest, with scene-specific folder scan.
func play_scene_bgm(scene_path: String) -> void:
	# Try to find scene-specific music folder
	# e.g. "res://Story/00_Warsaw/02_factory_shift.json" → "res://Assets/Audio/Music/Scenes/02_factory_shift/"
	var scene_name = scene_path.get_file().get_basename()
	var scene_music_folder = "res://Assets/Audio/Music/Scenes/" + scene_name
	
	if DirAccess.dir_exists_absolute(scene_music_folder):
		var d = DirAccess.open(scene_music_folder)
		if d:
			d.list_dir_begin()
			var file = d.get_next()
			while file != "":
				if not d.current_is_dir():
					var clean = file.replace(".import", "").replace(".remap", "")
					if clean.ends_with(".ogg") or clean.ends_with(".mp3") or clean.ends_with(".wav"):
						play_bgm(scene_music_folder + "/" + clean)
						return
				file = d.get_next()
	
	# No scene-specific music found — don't stop what's already playing
