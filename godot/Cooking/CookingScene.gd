extends Control

signal cooking_finished(score: int)

# === CONFIGURATION ===
const MAX_TEMP: float = 100.0
const MIN_TEMP: float = 0.0
var GREEN_ZONE_MIN: float = 40.0
var GREEN_ZONE_MAX: float = 70.0
var DANGER_ZONE_MIN: float = 95.0

# Dynamic Mechanics
var _green_zone_center: float = 55.0
var _green_zone_width: float = 30.0 # Wider target (was 20)
var _time_elapsed: float = 0.0
var _turbulence_timer: float = 0.0



# Balance loaded from GameGlobal
var BASE_HEATING_RATE: float = 5.0
var COOLING_RATE: float = 40.0
var PROGRESS_RATE: float = 10.0
var TOTAL_PROGRESS_REQD: float = 100.0
var INGREDIENT_TIMEOUT: float = 8.0

# === STATE ===


var _temperature: float = 20.0
var _progress: float = 0.0
var _is_stirring: bool = false
var _is_active: bool = false
var _heating_modifier: float = 1.0
var _input_locked: bool = false
var _start_warmup: float = 0.0 # Grace period at start
var _score: int = 0
var _pot_rotation_angle: float = 0.0 # For shader rotation

# Ingredient Requests
var _ingredient_timer: float = 0.0
var _current_requested_ingredient: String = ""
var _current_ingredient_time_left: float = 0.0
const INGREDIENTS = ["Пряности", "Ягоды", "Яблоки", "Сахар"]


var _stick_initial_pos: Vector2 = Vector2.ZERO
var _stick_initial_rot: float = 0.0
var _stick_anchor_norm: Vector2 = Vector2.ZERO # Normalized offset from pot center (-1..1)

# === NODES ===
@onready var heat_slider = $UI/HeatSlider
@onready var progress_bar = $UI/ProgressBar
@onready var status_label = $UI/StatusLabel
@onready var pot_visual = $GameArea/Pot
@onready var stick_visual = $GameArea/Stick
@onready var ingredient_label = $UI/IngredientRequestLabel
@onready var ingredient_timer_bar = $UI/IngredientRequestLabel/TimerBar
@onready var green_zone_rect = $UI/HeatSlider/GreenZone
@onready var danger_indicator = $UI/DangerIndicator
@onready var game_area = $GameArea
@onready var money_label = $UI/MoneyPanel/HBox/MoneyValue

func _ready():
	print("CookingScene: _ready called")
	if stick_visual:
		_stick_initial_pos = stick_visual.position
		stick_visual.position = _stick_initial_pos
		_stick_initial_rot = stick_visual.rotation
		
		# Calculate normalized anchor position relative to Pot
		if pot_visual:
			# Shift center down by 10px and right by 10px (Total) as requested
			var pot_center = pot_visual.position + pot_visual.size / 2.0 + Vector2(10, 10)
			# Track the BOTTOM TIP of the stick, not the center
			# Assuming stick texture is vertical and bottom is the stirrer
			var stick_tip_offset = Vector2(stick_visual.size.x / 2.0, stick_visual.size.y)
			var stick_tip_pos = _stick_initial_pos + stick_tip_offset
			
			var diff = stick_tip_pos - pot_center
			
			# Reduce radius by 130 pixels (100 + 30)
			var len = diff.length()
			if len > 130.0:
				diff = diff.normalized() * (len - 130.0)
			
			# Normalize against pot radius (half-size)
			if pot_visual.size.x > 0 and pot_visual.size.y > 0:
				_stick_anchor_norm = Vector2(diff.x / (pot_visual.size.x / 2.0), diff.y / (pot_visual.size.y / 2.0))
				
				# CLAMP to keep inside oval (0.9 margin)
				if _stick_anchor_norm.length() > 0.9:
					_stick_anchor_norm = _stick_anchor_norm.normalized() * 0.9
			else:
				_stick_anchor_norm = Vector2.ZERO
	
	_start_game()
	_update_money_display()
	if "GameGlobal" in get_node("/root"):
		# Connect cleanly
		if not GameGlobal.money_changed.is_connected(_on_money_changed):
			GameGlobal.money_changed.connect(_on_money_changed)

func _exit_tree():
	if "GameGlobal" in get_node("/root"):
		if GameGlobal.money_changed.is_connected(_on_money_changed):
			GameGlobal.money_changed.disconnect(_on_money_changed)

func _process(delta):
	# print("CookingScene: process active? ", _is_active) # Too spammy
	if not _is_active: return
	
	if _start_warmup > 0:
		_start_warmup -= delta
		if _start_warmup <= 0:
			status_label.text = "Удерживай температуру в ЗЕЛЕНОЙ ЗОНЕ!"
		else:
			_update_visuals() # Ensure visuals are correct during warmup
			return # Skip logic updates during warmup
	
	_time_elapsed += delta
	# Drift removed as per user request - static zone
	
	_update_temperature(delta)
	_update_progress(delta)
	_update_ingredients(delta)
	_update_visuals()

func _update_temperature(delta):
	var current_heating = BASE_HEATING_RATE * _heating_modifier
	
	if _is_stirring and not _input_locked:
		_temperature -= COOLING_RATE * delta
	else:
		_temperature += current_heating * delta
		
	_temperature = clamp(_temperature, MIN_TEMP, MAX_TEMP)
	
	# Update Pot Rotation Shader
	if _is_stirring:
		_pot_rotation_angle -= delta * 1.5 # Slower rotation (was 5.0)
		if _pot_rotation_angle > TAU:
			_pot_rotation_angle -= TAU
		if pot_visual.material:
			# Pass positive angle to rotate texture Counter-Clockwise (or simple Other Way)
			pot_visual.material.set_shader_parameter("angle", _pot_rotation_angle)
	
	# Update Stick Animation
	if stick_visual and pot_visual:
		if _is_stirring:
			# Calculate rotated position based on initial UV offset
			# We rotate the normalized vector, then scale back to pot dimensions
			var pot_size = pot_visual.size
			# Shift center down by 10px and right by 10px (Total) as requested
			var pot_center = pot_visual.position + pot_visual.size / 2.0 + Vector2(10, 10)
			
			# Rotation angle (must match shader direction)
			# Shader uses _pot_rotation_angle directly now (Positive = CCW usually? user said matches)
			# Let's assume positive angle rotates vector normally.
			
			var current_angle = -_pot_rotation_angle
			var cos_a = cos(current_angle)
			var sin_a = sin(current_angle)
			
			# Rotate the initial normalized offset
			# _stick_anchor_norm was calculated in _ready
			var new_norm_x = _stick_anchor_norm.x * cos_a - _stick_anchor_norm.y * sin_a
			var new_norm_y = _stick_anchor_norm.x * sin_a + _stick_anchor_norm.y * cos_a
			
			# Map back to screen space
			var new_pos_relative = Vector2(new_norm_x * (pot_size.x / 2.0), new_norm_y * (pot_size.y / 2.0))
			
			# new_pos_relative is the new TIP position relative to pot center
			var target_tip_pos = pot_center + new_pos_relative
			
			# We want to place the stick such that its bottom tip is at target_tip_pos
			# Stick Pos = Tip Pos - Tip Offset
			var stick_tip_offset = Vector2(stick_visual.size.x / 2.0, stick_visual.size.y)
			stick_visual.position = target_tip_pos - stick_tip_offset
			
			# Wobble rotation
			stick_visual.rotation = _stick_initial_rot + sin(current_angle * 3.0) * 0.1
			
		else:
			# Idle pose - return to INITIAL
			# Actually, if we want it "attached", does it return? 
			# User: "stay in this place on the drawing".
			# Implies it should stay where the texture stopped?
			# "and synchronously move with it".
			# If texture stops, stick stops there.
			# But user also said "return to positions" in previous contexts? 
			# Let's assume for now it stays "attached" meaning if we stop stirring, it stays at the current rotated pos?
			# OR it returns to initial.
			# "in preparatory time and during the game she was in one position" (Step 1346).
			# Meaning: Idle position = Initial Position.
			# So when stopping, we lerp back to Initial.
			
			# Return to initial (Static, no wobble)
			stick_visual.rotation = lerp_angle(stick_visual.rotation, _stick_initial_rot, delta * 5.0)
			stick_visual.position = stick_visual.position.lerp(_stick_initial_pos, delta * 5.0)
	
	# Fail conditions
	if _temperature >= 100.0:
		AudioManager.play_event("cook_fail")
		_fail_game("КОТЕЛ ВЗОРВАЛСЯ!")
	elif _temperature <= 0.0:
		AudioManager.play_event("cook_fail")
		_fail_game("ВАРЕВО ОСТЫЛО!")

func _update_progress(delta):
	# Progress continues even if ingredient demanded, BUT failure comes if timer runs out.
	if _temperature >= GREEN_ZONE_MIN and _temperature <= GREEN_ZONE_MAX:
		_progress += PROGRESS_RATE * delta
		_score += int(delta * 10) 
		if _progress >= TOTAL_PROGRESS_REQD:
			AudioManager.play_event("cook_win")
			_win_game()
	
	# Danger zone warning
	var in_danger = _temperature > DANGER_ZONE_MIN
	danger_indicator.visible = in_danger
	if in_danger and int(Time.get_ticks_msec()) % 1000 < 50:
		AudioManager.play_event("temp_warning")

func _update_ingredients(delta):
	if _current_requested_ingredient == "":
		_ingredient_timer -= delta
		if _ingredient_timer <= 0:
			_request_ingredient()
	else:
		# Process active request
		_current_ingredient_time_left -= delta
		ingredient_timer_bar.value = _current_ingredient_time_left / INGREDIENT_TIMEOUT
		
		# Visual urgency
		if _current_ingredient_time_left < 2.0:
			ingredient_label.modulate = Color(1, 0, 0) if int(Time.get_ticks_msec() / 200) % 2 == 0 else Color(1, 1, 0)
		else:
			ingredient_label.modulate = Color(1, 1, 0)

		if _current_ingredient_time_left <= 0:
			_fail_game("НЕ УСПЕЛ ДОБАВИТЬ ИНГРЕДИЕНТ!")

func _request_ingredient():
	_current_requested_ingredient = INGREDIENTS.pick_random()
	_current_ingredient_time_left = INGREDIENT_TIMEOUT
	ingredient_label.text = "Добавьте: " + _current_requested_ingredient
	ingredient_label.visible = true
	ingredient_timer_bar.value = 1.0
	AudioManager.play_event("ingredient_request")

func _on_stir_button_down():
	if not _input_locked:
		_is_stirring = true
		AudioManager.play_event("cook_stir")

func _on_stir_button_up():
	_is_stirring = false

# Called by Pot.gd when ingredient is dropped
func on_ingredient_dropped(type: String):
	if type == _current_requested_ingredient:
		_score += 50
		AudioManager.play_event("ingredient_drop")
		_apply_ingredient_effect(type)
		_current_requested_ingredient = ""
		ingredient_label.visible = false
		_ingredient_timer = randf_range(3.0, 6.0)
		_animate_pot_success()
	else:
		_score -= 20
		AudioManager.play_event("ingredient_wrong")
		status_label.text = "Не тот ингредиент!"
		_animate_pot_fail()

func _animate_pot_success():
	var tween = create_tween()
	pot_visual.scale = Vector2(1.2, 1.2)
	tween.tween_property(pot_visual, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	pot_visual.modulate = Color.GREEN * 2.0 # Flash brighter
	tween.chain().tween_property(pot_visual, "modulate", Color.WHITE, 0.2) # This will be overwritten by _process, so maybe just scale is enough

func _animate_pot_fail():
	var tween = create_tween()
	tween.tween_property(pot_visual, "position", pot_visual.position + Vector2(10, 0), 0.05)
	tween.tween_property(pot_visual, "position", pot_visual.position - Vector2(10, 0), 0.05)
	tween.tween_property(pot_visual, "position", pot_visual.position, 0.05)



func _apply_ingredient_effect(type: String):
	match type:
		"Пряности":
			status_label.text = "ПРЯНОСТИ! Жгучий вкус!"
			# Twist: Heat up much faster
			_heating_modifier = 4.0 
			await get_tree().create_timer(3.0).timeout
			_heating_modifier = 1.0
		"Ягоды":
			status_label.text = "ЯГОДЫ! Лесной вкус!"
			# Berries effect: Score bonus + Small visual bounce
			_score += 100
			# removed input lock
		"Яблоки":
			status_label.text = "ЯБЛОКИ! Витамины!"
			# Apples effect: maybe just score or standard?
			# Lavrushka reduced temp. Let's make Apples do something else or same.
			# "Slight temp reduction" fits apples too (cooling)?
			_temperature -= 5.0
		"Сахар":
			status_label.text = "Сахар. Сладкая жизнь."
			_score += 10
		_:
			status_label.text = "Ингредиент добавлен."



func _update_visuals():
	heat_slider.value = _temperature
	progress_bar.value = _progress
	
	# Visual feedback for filling
	if _temperature >= GREEN_ZONE_MIN and _temperature <= GREEN_ZONE_MAX:
		progress_bar.modulate = Color(0.5, 1.0, 0.5) # Glowing Green
		progress_bar.scale = Vector2(1.02, 1.02) # Slight pulse hint, better handled in _process or animation but this works for now
	else:
		progress_bar.modulate = Color.WHITE
		progress_bar.scale = Vector2.ONE
	
	# Pot color interpolation removed as per request
	pot_visual.modulate = Color.WHITE
	
	# Update Green Zone Visuals
	# Slider is 500px tall. Value 100 is Top (y=0). Value 0 is Bottom (y=500).
	# Top Offset = (100 - MAX) / 100 * 500
	# Bottom Offset = (100 - MIN) / 100 * 500 - 500 (since checking from top parent? No, standard rect offsets)
	# Easier: top is (1.0 - MAX/100) * height. bottom is (1.0 - MIN/100) * height - height (relative to bottom anchor)
	# Actually let's just use absolute pixels relative to top (0) since anchors are full stretch?
	# Wait, check tscn: anchors 15 (full rect) for GreenZone inside Slider?
	# No, GreenZone is child of HeatSlider.
	# Top Offset = (100 - MAX) / 100 * 500
	# Bottom Offset = (100 - MIN) / 100 * 500 - 500 
	
	# Assuming HeatSlider is 500px height fixed.
	var info = heat_slider.size.y # Should be 500
	var top_y = (1.0 - (GREEN_ZONE_MAX / 100.0)) * info
	var bot_y = (1.0 - (GREEN_ZONE_MIN / 100.0)) * info
	
	# Setting margins/offsets
	green_zone_rect.offset_top = top_y
	green_zone_rect.offset_bottom = bot_y - info # offset_bottom is relative to bottom edge, so negative

func _start_game():
	# Load balance
	# Force hardcoded values to bypass potential Autoload caching issues in running game
	if "GameGlobal" in get_node("/root") and GameGlobal.COOKING_BALANCE:
		pass
		# var b = GameGlobal.COOKING_BALANCE
		# BASE_HEATING_RATE = b.get("heating_rate", 5.0)
		# COOLING_RATE = b.get("cooling_rate", 40.0)
		# PROGRESS_RATE = b.get("progress_rate", 10.0)
		# TOTAL_PROGRESS_REQD = b.get("total_progress", 100.0)
		# INGREDIENT_TIMEOUT = b.get("ingredient_timeout", 8.0)
		
	# HARDCODED EXTREME VALUES (As per latest request)
	BASE_HEATING_RATE = 7.0
	COOLING_RATE = 18.0 # Adjusted for heating 7
	PROGRESS_RATE = 3.4 # Requested speed
	TOTAL_PROGRESS_REQD = 100.0
	INGREDIENT_TIMEOUT = 8.0

	_is_active = true
	_score = 0
	_progress = 0
	_temperature = 20.0 # Start much safely (was 50.0)
	_start_warmup = 2.0 # Give 2 seconds to prepare
	_ingredient_timer = 2.0
	status_label.text = "Приготовься..."
	
	# Apply Story Choice Modifiers
	if has_node("/root/Variables"):
		var vars = get_node("/root/Variables").get_stored_variables_list()
		var style = vars.get("cooking_style", "normal")
		print("Cooking Style: ", style)
		if style == "fast":
			BASE_HEATING_RATE *= 2.0 # Much faster heat
			PROGRESS_RATE *= 1.5 # Faster progress
			status_label.text += "\n(Режим: Рискованный)"
		elif style == "safe":
			BASE_HEATING_RATE *= 0.5 # Slower heat
			COOLING_RATE *= 1.2 # Easier cooling
			INGREDIENT_TIMEOUT *= 1.5 # More time to add ingredients
			DANGER_ZONE_MIN = 95.0 # Wider green/safe zone (effectively)
			status_label.text += "\n(Режим: Осторожный)"
		else:
			status_label.text += "\n(Режим: По инструкции)"


func _fail_game(reason: String):
	_is_active = false
	status_label.text = reason
	await get_tree().create_timer(2.0).timeout
	cooking_finished.emit(0) # Score 0 on fail

func _win_game():
	_is_active = false
	status_label.text = "ВАРКА ЗАВЕРШЕНА!"
	await get_tree().create_timer(2.0).timeout
	cooking_finished.emit(_score)

func _update_money_display():
	if "GameGlobal" in get_node("/root"):
		money_label.text = str(GameGlobal.player_money)
	else:
		money_label.text = "0"

func _on_money_changed(new_amount):
	money_label.text = str(new_amount)
