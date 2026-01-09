extends Control
## Сцена мини-игры: "Волк ловит банки"

@onready var game_logic: FactoryJamGame = $FactoryJamGame
@onready var danila_lt: Sprite2D = $GameArea/DanilaLT
@onready var danila_lb: Sprite2D = $GameArea/DanilaLB
@onready var danila_rt: Sprite2D = $GameArea/DanilaRT
@onready var danila_rb: Sprite2D = $GameArea/DanilaRB

func _update_basket_position():
	# Hide all first
	if danila_lt: danila_lt.visible = false
	if danila_lb: danila_lb.visible = false
	if danila_rt: danila_rt.visible = false
	if danila_rb: danila_rb.visible = false
	
	# Show active
	match current_basket_pos:
		0: if danila_lt: danila_lt.visible = true # LT
		1: if danila_lb: danila_lb.visible = true # LB
		2: if danila_rt: danila_rt.visible = true # RT
		3: if danila_rb: danila_rb.visible = true # RB


# ... (rest of vars)



# ... (input logic remains same, changing current_basket_pos)



@onready var jars_container: Control = $GameArea/JarsContainer
@onready var score_label: Label = $UI/InfoPanelContainer/InfoPanel/ScoreLabel
@onready var lives_label: Label = $UI/InfoPanelContainer/InfoPanel/LivesLabel
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/FinalScoreLabel

# Transition overlay
var fade_overlay: ColorRect

# Centered Positions (Screen 1920x1080, Center 960, 540)
# Lane X offsets from center: -300 (Left), +300 (Right)
# Y positions: Top=400, Bottom=600

# 0=LT, 1=LB, 2=RT, 3=RB
var basket_positions = {
	0: Vector2(660, 440),
	1: Vector2(660, 640),
	2: Vector2(1260, 440),
	3: Vector2(1260, 640)
}

# Start points for falling jars (high up)
var lane_start_positions = {
	0: Vector2(660, 100),
	1: Vector2(660, 100), # Both left lanes start from same top area or slightly different? Let's make them flow from top
	2: Vector2(1260, 100),
	3: Vector2(1260, 100)
}

# Текущая позиция корзинки
var current_basket_pos: int = 1 # Start at Left Bottom

# Банки на экране
class JarInfo:
	var node: Control
	var lane: int
	var progress: float # 0.0 to 1.0 (1.0 = caught)
	var speed: float
	var is_rotten: bool

var active_jars: Array[JarInfo] = []

signal factory_game_finished(score: int, jars_labeled: int, jars_missed: int)

func _ready():
	# Create fade overlay
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_overlay)

	# Fade In
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	_update_lane_visuals()
	_update_basket_position()
	
	if game_logic:
		game_logic.score_updated.connect(_on_score_updated)
		game_logic.lives_updated.connect(_on_lives_updated)
		# Assuming signal signature update is handled automatically by connect if args match
		game_logic.spawn_jar_requested.connect(_on_spawn_jar)
		game_logic.game_finished.connect(_on_game_finished)
		
		# ... (rest of ready) ...
		await get_tree().create_timer(1.0).timeout
		start_game_auto()
	else:
		push_error("FactoryJamScene: GameLogic node not found!")

# ... (omitting irrelevant functions) ...



func _update_lane_visuals():
	# Helper to set line points
	var set_line = func(node_name, start, end):
		var line = $GameArea.get_node_or_null(node_name)
		if line:
			line.points = PackedVector2Array([start, end])
			line.width = 10.0
			line.default_color = Color(0.6, 0.6, 0.6, 0.5)
	
	# Visual lines start abit higher than catch point
	# 0=LT
	set_line.call("LaneLT", Vector2(660, 100), Vector2(660, 440))
	# 1=LB (connects from LT to LB? or separate? Let's make them separate falls for now or continuous?)
	# Original conception was 4 diagonal lanes? Wolf style is usually 4 diagonal chutes.
	# Let's approximate chutes.
	# LT Chute
	set_line.call("LaneLT", Vector2(460, 200), Vector2(660, 440))
	# LB Chute
	set_line.call("LaneLB", Vector2(460, 600), Vector2(660, 640))
	# RT Chute
	set_line.call("LaneRT", Vector2(1460, 200), Vector2(1260, 440))
	# RB Chute
	set_line.call("LaneRB", Vector2(1460, 600), Vector2(1260, 640))

func start_game_auto():
	if game_logic:
		game_logic.start_game()
		set_process_input(true)
		grab_focus() # Попытка захватить фокус
	
func start_game_manual():
	start_game_auto()

func _input(event):
	if not game_logic: return
	
	if game_logic.current_state != FactoryJamGame.GameState.PLAYING:
		return
		
	# Input Cooldown Check
	if input_cooldown > 0:
		return
		
	if event is InputEventKey and event.pressed:
		var moved = false
		# WASD Controls
		if event.keycode == KEY_W: # UP
			if current_basket_pos == 1: current_basket_pos = 0; moved = true
			if current_basket_pos == 3: current_basket_pos = 2; moved = true
		elif event.keycode == KEY_S: # DOWN
			if current_basket_pos == 0: current_basket_pos = 1; moved = true
			if current_basket_pos == 2: current_basket_pos = 3; moved = true
		elif event.keycode == KEY_A: # LEFT
			if current_basket_pos == 2: current_basket_pos = 0; moved = true
			if current_basket_pos == 3: current_basket_pos = 1; moved = true
		elif event.keycode == KEY_D: # RIGHT
			if current_basket_pos == 0: current_basket_pos = 2; moved = true
			if current_basket_pos == 1: current_basket_pos = 3; moved = true
			
		# Keep NumPad support just in case (also triggers cooldown)
		elif event.keycode == KEY_KP_7: current_basket_pos = 0; moved = true
		elif event.keycode == KEY_KP_1: current_basket_pos = 1; moved = true
		elif event.keycode == KEY_KP_9: current_basket_pos = 2; moved = true
		elif event.keycode == KEY_KP_3: current_basket_pos = 3; moved = true
		
		# Arrow keys support
		elif event.keycode == KEY_UP:
			if current_basket_pos == 1: current_basket_pos = 0; moved = true
			if current_basket_pos == 3: current_basket_pos = 2; moved = true
		elif event.keycode == KEY_DOWN:
			if current_basket_pos == 0: current_basket_pos = 1; moved = true
			if current_basket_pos == 2: current_basket_pos = 3; moved = true
		elif event.keycode == KEY_LEFT:
			if current_basket_pos == 2: current_basket_pos = 0; moved = true
			if current_basket_pos == 3: current_basket_pos = 1; moved = true
		elif event.keycode == KEY_RIGHT:
			if current_basket_pos == 0: current_basket_pos = 2; moved = true
			if current_basket_pos == 1: current_basket_pos = 3; moved = true
			
		if moved:
			# Cooldown removed from movement
			_update_basket_position()



var input_cooldown: float = 0.0

func _process(delta):
	if input_cooldown > 0:
		input_cooldown -= delta

	if game_logic.current_state != FactoryJamGame.GameState.PLAYING:
		return
		
	var jars_to_remove = []
	# ... rest of process ...
	
	for jar in active_jars:
		# Движение
		jar.progress += (jar.speed / 300.0) * delta # 300px distance approx
		
		# Обновление позиции
		_update_jar_visual_position(jar)
		
		# Проверка столкновения
		if jar.progress >= 1.0:
			if jar.lane == current_basket_pos:
				# ПОЙМАЛ!
				if jar.is_rotten:
					# Поймал гнилую :(
					game_logic.hit_rotten_jar()
					_show_penalty_effect(jar.node.position) # Show Red -5 effect
					jars_to_remove.append(jar)
					# No delay for bad catch? Or yes? User said "delay after catch".
					# Let's say yes, physics of catching applies.
					input_cooldown = 1.0
				else:
					# Поймал нормальную :)
					game_logic.catch_jar()
					_show_catch_effect(jar.node.position)
					jars_to_remove.append(jar)
					# Freeze input after catching
					input_cooldown = 1.0
			else:
				# ПРОПУСТИЛ (прошла мимо)
				if jar.progress >= 1.2:
					if jar.is_rotten:
						# Пропустил гнилую - молодец!
						jars_to_remove.append(jar)
					else:
						# Пропустил нормальную :(
						game_logic.miss_jar()
						_show_miss_effect(jar.node.position)
						jars_to_remove.append(jar)
	
	for jar in jars_to_remove:
		_remove_jar(jar)

func _update_jar_visual_position(jar: JarInfo):
	# Интерполяция по линии (Chute)
	var end = basket_positions[jar.lane]
	var start = Vector2.ZERO
	
	match jar.lane:
		0: start = Vector2(460, 200) # LT Start
		1: start = Vector2(460, 600) # LB Start
		2: start = Vector2(1460, 200) # RT Start
		3: start = Vector2(1460, 600) # RB Start
	
	# Clamp progress for visual (can go beyond 1.0 for falling effect)
	var t = jar.progress
	jar.node.position = start.lerp(end, t) - jar.node.size / 2
	
	# Вращение для динамики
	jar.node.rotation += 5.0 * get_process_delta_time()

func _on_spawn_jar(lane: int, speed: float, is_rotten: bool):
	var jar_node = TextureRect.new()
	
	var texture_path = "res://Factory/jar_filled.png"
	if is_rotten:
		texture_path = "res://Factory/jar_filled_bad.png"
		
	var texture = load(texture_path)
	
	if not texture:
		# Fallback if specific bad texture missing, try standard
		if is_rotten:
			texture = load("res://Factory/jar_filled.png")
			
	if not texture:
		# Fallback primitive
		jar_node = ColorRect.new()
		jar_node.color = Color.ORANGE
		jar_node.size = Vector2(40, 50)
		
		# Emojis for fun
		var label = Label.new()
		label.text = "🍯"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = Vector2(40, 50)
		label.add_theme_font_size_override("font_size", 24)
		jar_node.add_child(label)
	else:
		jar_node.texture = texture
		jar_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		jar_node.size = Vector2(40, 50)
	
	if is_rotten:
		jar_node.modulate = Color(0.2, 0.8, 0.2) # Greenish Rotten (as requested: "paint it green")
	
	jar_node.pivot_offset = jar_node.size / 2
	jars_container.add_child(jar_node)
	
	var info = JarInfo.new()
	info.node = jar_node
	info.lane = lane
	info.speed = speed
	info.progress = 0.0
	info.is_rotten = is_rotten
	
	active_jars.append(info)
	_update_jar_visual_position(info)

func _remove_jar(jar: JarInfo):
	if jar in active_jars:
		active_jars.erase(jar)
	if is_instance_valid(jar.node):
		jar.node.queue_free()

func _show_catch_effect(pos: Vector2):
	var label = Label.new()
	label.text = "+1"
	label.modulate = Color.GREEN
	label.position = pos
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y - 50, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _show_penalty_effect(pos: Vector2):
	var label = Label.new()
	label.text = "-1 ❤"
	label.modulate = Color.RED
	label.position = pos
	label.add_theme_font_size_override("font_size", 32) # Bigger font for impact
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y + 50, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _show_miss_effect(pos: Vector2):
	var label = Label.new()
	label.text = "MISS!"
	label.modulate = Color.RED
	label.position = pos
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", pos.y + 50, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _on_score_updated(new_score: int):
	if score_label:
		score_label.text = "Score: %d" % new_score

func _on_lives_updated(new_lives: int):
	if lives_label:
		lives_label.text = "Lives: %d" % new_lives

func _on_game_finished(score: int, caught: int, broken: int):
	# Показать Game Over
	if game_over_panel:
		game_over_panel.show()
	if final_score_label:
		final_score_label.text = "Final Score: %d" % score
	
	# Ждем, чтобы игрок увидел результат
	await get_tree().create_timer(2.0).timeout
	
	# Fade Out
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
	
	print("FactoryJamScene: Emitting game_finished with Score: %d" % score)
	factory_game_finished.emit(score, caught, broken)
