extends Control

signal cooking_finished(score: int)

# === CONFIGURATION ===
const MAX_TEMP: float = 100.0
const MIN_TEMP: float = 0.0
const GREEN_ZONE_MIN: float = 40.0
const GREEN_ZONE_MAX: float = 70.0
var DANGER_ZONE_MIN: float = 90.0



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
var _score: int = 0

# Ingredient Requests
var _ingredient_timer: float = 0.0
var _current_requested_ingredient: String = ""
var _current_ingredient_time_left: float = 0.0
const INGREDIENTS = ["Огненный корень", "Ледяная пыль", "Соль", "Сахар"]

# === NODES ===
@onready var heat_slider = $UI/HeatSlider
@onready var progress_bar = $UI/ProgressBar
@onready var status_label = $UI/StatusLabel
@onready var pot_visual = $GameArea/Pot
@onready var ingredient_label = $UI/IngredientRequestLabel
@onready var ingredient_timer_bar = $UI/IngredientRequestLabel/TimerBar
@onready var green_zone_rect = $UI/HeatSlider/GreenZone
@onready var danger_indicator = $UI/DangerIndicator
@onready var money_label = $UI/MoneyPanel/HBox/MoneyValue

func _ready():
	print("CookingScene: _ready called")
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
	
	# Fail conditions
	if _temperature >= 100.0:
		_fail_game("КОТЕЛ ВЗОРВАЛСЯ!")
	elif _temperature <= 0.0:
		_fail_game("ВАРЕВО ОСТЫЛО!")

func _update_progress(delta):
	# Progress continues even if ingredient demanded, BUT failure comes if timer runs out.
	if _temperature >= GREEN_ZONE_MIN and _temperature <= GREEN_ZONE_MAX:
		_progress += PROGRESS_RATE * delta
		_score += int(delta * 10) 
		if _progress >= TOTAL_PROGRESS_REQD:
			_win_game()
	
	# Danger zone warning
	danger_indicator.visible = (_temperature > DANGER_ZONE_MIN)

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

func _on_stir_button_down():
	if not _input_locked:
		_is_stirring = true

func _on_stir_button_up():
	_is_stirring = false

# Called by Pot.gd when ingredient is dropped
func on_ingredient_dropped(type: String):
	if type == _current_requested_ingredient:
		_score += 50
		_apply_ingredient_effect(type)
		_current_requested_ingredient = ""
		ingredient_label.visible = false
		_ingredient_timer = randf_range(3.0, 6.0)
		_animate_pot_success()
	else:
		_score -= 20
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
		"Огненный корень":
			status_label.text = "ОГОНЬ! Нагрев усилен!"
			# Twist: Heat up much faster
			_heating_modifier = 4.0 
			await get_tree().create_timer(3.0).timeout
			_heating_modifier = 1.0
		"Ледяная пыль":
			status_label.text = "ЛЕД! Управление замерзло!"
			# Twist: Freeze controls
			_input_locked = true
			# Visual freeze feedback
			var original_modulate = heat_slider.modulate
			heat_slider.modulate = Color.CYAN
			await get_tree().create_timer(2.0).timeout
			_input_locked = false
			heat_slider.modulate = original_modulate
		"Соль":
			status_label.text = "Соль добавлена."
			# Maybe slight temp reduction?
			_temperature -= 5.0
		"Сахар":
			status_label.text = "Сахар добавлен."
			_progress += 5.0
		_:
			status_label.text = "Ингредиент добавлен."

func _update_visuals():
	heat_slider.value = _temperature
	progress_bar.value = _progress
	
	# Pot color interpolation
	var color_start = Color(0.4, 0.2, 0.0) # Muddy brown
	var color_end = Color(0.0, 1.0, 1.0) # Glowing cyan
	var t = _progress / TOTAL_PROGRESS_REQD
	pot_visual.modulate = color_start.lerp(color_end, t)

func _start_game():
	# Load balance
	if "GameGlobal" in get_node("/root") and GameGlobal.COOKING_BALANCE:
		var b = GameGlobal.COOKING_BALANCE
		BASE_HEATING_RATE = b.get("heating_rate", 5.0)
		COOLING_RATE = b.get("cooling_rate", 40.0)
		PROGRESS_RATE = b.get("progress_rate", 10.0)
		TOTAL_PROGRESS_REQD = b.get("total_progress", 100.0)
		INGREDIENT_TIMEOUT = b.get("ingredient_timeout", 8.0)

	_is_active = true
	_score = 0
	_progress = 0
	_temperature = 50.0 # Start safely
	_ingredient_timer = 2.0
	status_label.text = "Удерживай температуру в ЗЕЛЕНОЙ ЗОНЕ!"
	
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
		elif style == "fast":
			BASE_HEATING_RATE *= 2.0 # Much faster heat
			PROGRESS_RATE *= 1.5 # Faster progress
			INGREDIENT_TIMEOUT *= 0.7 # Hurry up!
			DANGER_ZONE_MIN = 85.0 # Danger comes sooner
			status_label.text += "\n(Режим: Рискованный)"

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
