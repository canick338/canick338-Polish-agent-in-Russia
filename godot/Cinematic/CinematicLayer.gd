extends Control

## Cinematic Layer for displaying Plot Frames (CGs) with dynamic effects.
## Supports Ken Burns effect (Pan/Zoom) and "Alive" idle animations.

signal cinematic_finished

# Nodes
@onready var _texture_rect: TextureRect = $TextureRect
@onready var _dim: ColorRect = $Dim

# State
var _original_size: Vector2
var _current_tween: Tween
var _idle_tween: Tween

const IDLE_EFFECTS = {
	"none": null,
	"breathing": "_idle_breathing",
	"handheld": "_idle_handheld",
	"shake": "_idle_shake",
	"heartbeat": "_idle_heartbeat",
	"wiggle": "_idle_wiggle",
	"bounce": "_idle_bounce"
}

func _ready() -> void:
	# Ensure the texture rect is centered
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.anchor_right = 1.0
	_texture_rect.anchor_bottom = 1.0
	_texture_rect.offset_left = 0
	_texture_rect.offset_top = 0
	_texture_rect.offset_right = 0
	_texture_rect.offset_bottom = 0
	_texture_rect.pivot_offset = size / 2 # Center pivot for zooming
	
	# Ensure Dim is ready
	if _dim:
		_dim.visible = false
		_dim.color = Color(0, 0, 0, 0)

func show_image(texture_path: String, transition_time: float = 0.5) -> void:
	"""Shows a new CG image with a fade transition."""
	if not FileAccess.file_exists(texture_path):
		push_error("Cinematic image not found: " + texture_path)
		return

	var texture = load(texture_path)
	if not texture:
		push_error("Failed to load texture: " + texture_path)
		return

	# Reset transform
	_kill_tweens()
	_texture_rect.scale = Vector2.ONE
	_texture_rect.position = Vector2.ZERO
	_texture_rect.rotation = 0.0
	_texture_rect.modulate = Color.WHITE # Reset mood

	# Fade transition
	if _texture_rect.texture:
		# If we already have an image, crossfade (simplified: fade out then in)
		var t = create_tween()
		t.tween_property(_texture_rect, "modulate:a", 0.0, transition_time / 2)
		t.tween_callback(func(): 
			_texture_rect.texture = texture
			_texture_rect.pivot_offset = size / 2 # Reset pivot
		)
		t.tween_property(_texture_rect, "modulate:a", 1.0, transition_time / 2)
	else:
		# First image
		_texture_rect.texture = texture
		_texture_rect.modulate.a = 0.0
		var t = create_tween()
		t.tween_property(_texture_rect, "modulate:a", 1.0, transition_time)

func move_camera(target_zoom: float, target_offset: Vector2, duration: float = 0.0) -> void:
	"""
	Moves the 'camera' (scales and moves the image).
	target_zoom: 1.0 = fit screen, >1.0 = zoom in.
	target_offset: Vector2 offset from center in pixels.
	"""
	_kill_tweens(true) # Kill movement tween, keep idle

	var target_scale = Vector2(target_zoom, target_zoom)
	var target_pos = target_offset 

	if duration <= 0.0:
		_texture_rect.scale = target_scale
		_texture_rect.position = target_pos
	else:
		_current_tween = create_tween()
		_current_tween.set_parallel(true)
		_current_tween.set_ease(Tween.EASE_IN_OUT)
		_current_tween.set_trans(Tween.TRANS_SINE)
		
		_current_tween.tween_property(_texture_rect, "scale", target_scale, duration)
		_current_tween.tween_property(_texture_rect, "position", target_pos, duration)
		
		await _current_tween.finished
		cinematic_finished.emit()

func start_idle(effect_name: String, intensity: float = 1.0) -> void:
	"""Starts an idle animation loop."""
	if _idle_tween:
		_idle_tween.kill()
	
	if not IDLE_EFFECTS.has(effect_name) or IDLE_EFFECTS[effect_name] == null:
		return

	call(IDLE_EFFECTS[effect_name], intensity)

func apply_mood(mood_name: String, duration: float = 1.0) -> void:
	"""Applies a color tint to the image."""
	var target_color = Color.WHITE
	match mood_name:
		"sepia": target_color = Color(1.0, 0.9, 0.7, 1.0)
		"night": target_color = Color(0.4, 0.5, 0.8, 1.0)
		"danger": target_color = Color(1.0, 0.5, 0.5, 1.0)
		"bw": target_color = Color(0.5, 0.5, 0.5, 1.0) # Just gray tint, properly needs saturation shader
		"dark": target_color = Color(0.3, 0.3, 0.3, 1.0)
		"normal": target_color = Color.WHITE
		_: return

	var t = create_tween()
	t.tween_property(_texture_rect, "modulate", target_color, duration)

func trigger_flash(color_name: String = "white", duration: float = 0.5) -> void:
	"""Triggers a screen flash."""
	var flash_color = Color.WHITE
	match color_name:
		"white": flash_color = Color.WHITE
		"red": flash_color = Color(1.0, 0.0, 0.0, 0.8)
		"black": flash_color = Color.BLACK
	
	_dim.visible = true
	_dim.color = flash_color
	_dim.color.a = 0.0
	
	var t = create_tween()
	t.tween_property(_dim, "color:a", 1.0 if color_name == "black" else 0.8, duration * 0.2).set_ease(Tween.EASE_OUT)
	t.tween_property(_dim, "color:a", 0.0, duration * 0.8).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): _dim.visible = false)

func trigger_impact(intensity: float = 1.0) -> void:
	"""Triggers a single heavy impact shake."""
	_kill_tweens(true) # Kill movement tweed
	
	var impact_vector = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 30.0 * intensity
	var duration = 0.4
	
	_current_tween = create_tween()
	
	# Initial hit
	_current_tween.tween_property(_texture_rect, "position", impact_vector, 0.05).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Recovery (elastic)
	_current_tween.tween_property(_texture_rect, "position", Vector2.ZERO, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await _current_tween.finished
	cinematic_finished.emit()


func stop_idle() -> void:
	if _idle_tween:
		_idle_tween.kill()
	# Reset minimal offsets if needed? 
	# For now, we assume idle effects are subtle relative movements that don't need hard reset

func _kill_tweens(movement_only: bool = false) -> void:
	if _current_tween:
		_current_tween.kill()
	if not movement_only and _idle_tween:
		_idle_tween.kill()

# --- Idle Effects ---

func _idle_breathing(intensity: float) -> void:
	"""Subtle zoom in/out resembling breathing."""
	var base_scale = _texture_rect.scale
	var strength = 0.03 * intensity
	var duration = 4.0
	
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	_idle_tween.set_trans(Tween.TRANS_SINE)
	_idle_tween.set_ease(Tween.EASE_IN_OUT)
	
	_idle_tween.tween_property(_texture_rect, "scale", base_scale * (1.0 + strength), duration)
	_idle_tween.tween_property(_texture_rect, "scale", base_scale, duration)

func _idle_heartbeat(intensity: float) -> void:
	"""Tense heartbeat pulsing."""
	var base_scale = _texture_rect.scale
	var strength = 0.05 * intensity # Sharp pulse
	# BPM simulation
	
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	
	# Pulse out (beat)
	_idle_tween.tween_property(_texture_rect, "scale", base_scale * (1.0 + strength), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	# Relax
	_idle_tween.tween_property(_texture_rect, "scale", base_scale, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	# Rest
	_idle_tween.tween_interval(0.4)

func _idle_handheld(intensity: float) -> void:
	"""Slow drift and rotation like a handheld camera."""
	var base_pos = _texture_rect.position
	var base_rot = _texture_rect.rotation
	
	var drift_range = 15.0 * intensity
	var rot_range = 0.02 * intensity # radians
	
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	
	# Random sequence of drifts
	for i in range(5):
		var target_pos = base_pos + Vector2(randf_range(-drift_range, drift_range), randf_range(-drift_range, drift_range))
		var target_rot = base_rot + randf_range(-rot_range, rot_range)
		var duration = randf_range(2.0, 4.0)
		
		_idle_tween.tween_property(_texture_rect, "position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_idle_tween.parallel().tween_property(_texture_rect, "rotation", target_rot, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _idle_shake(intensity: float) -> void:
	"""Nervous shaking."""
	var base_pos = _texture_rect.position
	var shake_range = 5.0 * intensity
	var duration = 0.05
	
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	
	# Rapid random movements
	_idle_tween.tween_callback(func():
		var offset = Vector2(randf_range(-shake_range, shake_range), randf_range(-shake_range, shake_range))
		_texture_rect.position = base_pos + offset
	).set_delay(duration)

func _idle_wiggle(intensity: float) -> void:
	"""Playful rotation wiggle."""
	var base_rot = _texture_rect.rotation
	var rot_amount = 0.05 * intensity # radians
	var duration = 0.2
	
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	
	# Right
	_idle_tween.tween_property(_texture_rect, "rotation", base_rot + rot_amount, duration).set_trans(Tween.TRANS_SINE)
	# Left
	_idle_tween.tween_property(_texture_rect, "rotation", base_rot - rot_amount, duration).set_trans(Tween.TRANS_SINE)

func _idle_bounce(intensity: float) -> void:
	"""Bouncing scale effect."""
	var base_scale = _texture_rect.scale
	var strength = 0.05 * intensity
	var duration = 0.5
	
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	
	# Up
	_idle_tween.tween_property(_texture_rect, "scale", base_scale * (1.0 + strength), duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	# Down
	_idle_tween.tween_property(_texture_rect, "scale", base_scale, duration * 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
