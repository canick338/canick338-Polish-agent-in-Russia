extends Control

# === CONFIGURATION ===
const MAX_LIVES: int = 3
const BASE_JAR_SPEED: float = 200.0
const SPAWN_INTERVAL_START: float = 2.0
const MIN_SPAWN_INTERVAL: float = 0.6
const ACCELERATION_RATE: float = 0.05
const MONEY_PER_POINT: int = 2
const MIN_SCORE_TO_PAY: int = 8

# === ENUMS ===
enum BasketPos { LT = 0, LB = 1, RT = 2, RB = 3 }
enum Lane { LT = 0, LB = 1, RT = 2, RB = 3 }
enum GameState { WAITING, PLAYING, FINISHED }

# === STATE ===
var _state: int = GameState.WAITING
var _score: int = 0
var _lives: int = MAX_LIVES
var _current_basket: int = BasketPos.LB
var _spawn_timer: float = 0.0
var _current_spawn_interval: float = SPAWN_INTERVAL_START
var _input_cooldown: float = 0.0

# === DATA CLASSES ===
class JarData:
	var node: Control
	var lane: int
	var progress: float = 0.0
	var speed: float
	var is_bad: bool

var _active_jars: Array[JarData] = []

# === NODES ===
@onready var _danila_sprites: Dictionary = {
	BasketPos.LT: $GameArea/DanilaLT,
	BasketPos.LB: $GameArea/DanilaLB,
	BasketPos.RT: $GameArea/DanilaRT,
	BasketPos.RB: $GameArea/DanilaRB
}
@onready var _jars_container: Control = $GameArea/JarsContainer
@onready var _ui_score: Label = $UI/InfoPanelContainer/InfoPanel/ScoreLabel
@onready var _ui_lives: Label = $UI/InfoPanelContainer/InfoPanel/LivesLabel
@onready var _ui_game_over: Panel = $UI/GameOverPanel
@onready var _ui_final_score: Label = $UI/GameOverPanel/FinalScoreLabel

# === SIGNALS ===
signal factory_game_finished(score: int, caught: int, broken: int)

func _ready() -> void:
	# Hide legacy GameLogic node warning if exists
	if has_node("FactoryJamGame"):
		get_node("FactoryJamGame").queue_free()
	
	_ui_game_over.visible = false
	_update_lane_visuals()
	_update_basket_visuals()
	_update_ui()
	
	# Auto-start after short delay
	await get_tree().create_timer(1.0).timeout
	
	# Reset global variable to ensure no stale high scores affect dialogue
	if has_node("/root/Variables"):
		get_node("/root/Variables").add_variable("factory_jam_result_v2", 0)
		
	_start_game()

func _update_lane_visuals() -> void:
	# Draw lines for visual reference
	var _set_line = func(name: String, start: Vector2, end: Vector2):
		var line = $GameArea.get_node_or_null(name)
		if line and line is Line2D:
			line.points = PackedVector2Array([start, end])
			line.width = 10.0
			line.default_color = Color(0.6, 0.6, 0.6, 0.5)

	# Visual Chutes based on jar paths
	_set_line.call("LaneLT", Vector2(460, 200), Vector2(660, 440))
	_set_line.call("LaneLB", Vector2(460, 600), Vector2(660, 640))
	_set_line.call("LaneRT", Vector2(1460, 200), Vector2(1260, 440))
	_set_line.call("LaneRB", Vector2(1460, 600), Vector2(1260, 640))

func _process(delta: float) -> void:
	if _state != GameState.PLAYING:
		return
		
	# 1. Spawning
	_process_spawner(delta)
	
	# 2. Movement & Physics
	_process_jars(delta)
	
	# 3. Input Cooldown
	if _input_cooldown > 0:
		_input_cooldown -= delta

func _input(event: InputEvent) -> void:
	if _state != GameState.PLAYING: return
	if _input_cooldown > 0: return

	if event is InputEventKey and event.pressed:
		var old_pos = _current_basket
		
		# Precise Control mapping
		match event.keycode:
			KEY_W, KEY_UP:
				if _current_basket == BasketPos.LB: _current_basket = BasketPos.LT
				elif _current_basket == BasketPos.RB: _current_basket = BasketPos.RT
			KEY_S, KEY_DOWN:
				if _current_basket == BasketPos.LT: _current_basket = BasketPos.LB
				elif _current_basket == BasketPos.RT: _current_basket = BasketPos.RB
			KEY_A, KEY_LEFT:
				if _current_basket == BasketPos.RT: _current_basket = BasketPos.LT
				elif _current_basket == BasketPos.RB: _current_basket = BasketPos.LB
			KEY_D, KEY_RIGHT:
				if _current_basket == BasketPos.LT: _current_basket = BasketPos.RT
				elif _current_basket == BasketPos.LB: _current_basket = BasketPos.RB
		
		if old_pos != _current_basket:
			_update_basket_visuals()

# === CORE LOGIC ===

func _start_game() -> void:
	_state = GameState.PLAYING
	_score = 0
	_lives = MAX_LIVES
	_active_jars.clear()
	_current_spawn_interval = SPAWN_INTERVAL_START
	_update_ui()
	print("FactoryJam: Started")

func _end_game() -> void:
	if _state == GameState.FINISHED: return
	_state = GameState.FINISHED
	
	print("FactoryJam: Game Over. Score: %d" % _score)
	
	_ui_game_over.visible = true
	
	var earned = 0
	if _score >= MIN_SCORE_TO_PAY:
		earned = _score * MONEY_PER_POINT
		GameGlobal.add_money(earned)
		_ui_final_score.text = "Смена окончена\nСчет: %d\nЗарплата: %d $" % [_score, earned]
	else:
		_ui_final_score.text = "Смена окончена\nСчет: %d\nУволен (Мало очков)" % _score
	
	# Sync with Story Variables
	if has_node("/root/Variables"):
		get_node("/root/Variables").add_variable("factory_jam_result_v2", _score)
		print("FactoryJam: Saved score to Variables as 'factory_jam_result_v2': %d" % _score)
		
	print("FactoryJam: Emitting finished signal with Score: %d" % _score)
	factory_game_finished.emit(_score, _score, MAX_LIVES - _lives)

func _process_spawner(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_jar()
		_spawn_timer = _current_spawn_interval
		# Accelerate
		_current_spawn_interval = max(MIN_SPAWN_INTERVAL, _current_spawn_interval - ACCELERATION_RATE)

func _process_jars(delta: float) -> void:
	var to_remove: Array[JarData] = []
	
	for jar in _active_jars:
		# Move visual progress 0.0 -> 1.0
		jar.progress += (jar.speed / 300.0) * delta
		_update_jar_visual(jar)
		
		if jar.progress >= 1.0:
			# Collision Check
			if jar.lane == _current_basket:
				_on_catch(jar)
				to_remove.append(jar)
			elif jar.progress >= 1.2:
				_on_miss(jar)
				to_remove.append(jar)
	
	for j in to_remove:
		_remove_jar(j)

func _spawn_jar() -> void:
	var lane = randi() % 4
	var is_bad = (randf() < 0.2) # 20% Rotten
	var speed = BASE_JAR_SPEED
	
	var node = TextureRect.new()
	# Use placeholders if textures missing
	var tex = load("res://Factory/jar_filled.png")
	if is_bad: tex = load("res://Factory/jar_filled_bad.png")
	
	if tex:
		node.texture = tex
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.size = Vector2(40, 50)
	else:
		node.custom_minimum_size = Vector2(40, 50) # Fallback
	
	if is_bad: node.modulate = Color.GREEN # Double ensure green
	
	_jars_container.add_child(node)
	
	var jar = JarData.new()
	jar.node = node
	jar.lane = lane
	jar.speed = speed
	jar.is_bad = is_bad
	_active_jars.append(jar)

func _remove_jar(jar: JarData) -> void:
	if jar.node: jar.node.queue_free()
	_active_jars.erase(jar)

# === EVENTS ===

func _on_catch(jar: JarData) -> void:
	if jar.is_bad:
		# Caught Bad = Penalty
		_modify_lives(-1)
		_show_popup(jar.node.position, "-1 ЖИЗНЬ", Color.RED)
		_input_cooldown = 0.5 # Stun
	else:
		# Caught Good = Score
		_score += 1
		_update_ui()
		_show_popup(jar.node.position, "+1", Color.GREEN)

func _on_miss(jar: JarData) -> void:
	if jar.is_bad:
		# Missed Bad = Good (Ignore)
		pass
	else:
		# Missed Good = Penalty
		_modify_lives(-1)
		_show_popup(jar.node.position, "РАЗБИЛ!", Color.RED)

func _modify_lives(amount: int) -> void:
	_lives += amount
	_update_ui()
	if _lives <= 0:
		_end_game()

# === VISUALS ===

func _update_basket_visuals() -> void:
	for k in _danila_sprites:
		var sprite = _danila_sprites[k]
		if sprite: sprite.visible = (k == _current_basket)

func _update_jar_visual(jar: JarData) -> void:
	# Visual Trajectory (Diagonal Chutes)
	var start = Vector2.ZERO
	var end = Vector2.ZERO
	
	match jar.lane:
		Lane.LT: 
			start = Vector2(460, 200)
			end = Vector2(660, 440)
		Lane.LB:
			start = Vector2(460, 600)
			end = Vector2(660, 640)
		Lane.RT:
			start = Vector2(1460, 200)
			end = Vector2(1260, 440)
		Lane.RB:
			start = Vector2(1460, 600)
			end = Vector2(1260, 640)
	
	jar.node.position = start.lerp(end, jar.progress) - (jar.node.size / 2)
	jar.node.rotation_degrees += 5.0 # Faster spin

func _update_ui() -> void:
	if _ui_score: _ui_score.text = "Счет: %d" % _score
	if _ui_lives: _ui_lives.text = "Жизни: %d" % max(0, _lives)

func _show_popup(pos: Vector2, text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.position = pos
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", pos.y - 50, 0.5)
	tw.tween_callback(label.queue_free)
