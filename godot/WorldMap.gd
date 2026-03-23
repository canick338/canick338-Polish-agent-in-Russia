extends Control

const MANIFEST_PATH = "res://Story/Manifests/main_story.json"
const PHONE_HUD_SCENE = preload("res://PhoneHUD.tscn")

var manifest_data: Dictionary = {}
var current_location_id: String = "warsaw_center"
var _tooltip_root: Control
var _tooltip_portrait: TextureRect
var _tooltip_portrait_panel: PanelContainer
var _tooltip_title: Label
var _tooltip_desc: Label
var _hovered_node_data: Dictionary = {}

var custom_tooltip_loaded: bool = false
var _custom_tooltip_node: Control = null

# === ACTION-BASED TIME ===
# Время меняется только через действия игрока (посещение локаций)
# Нет пассивного таймера — как в визуальных новеллах (Persona, Steins;Gate)

@onready var map_background: TextureRect = $MapBackground
@onready var nodes_container: Control = $MapNodes
@onready var location_label: Label = %LocationLabel
@onready var time_label: RichTextLabel = %TimeLabel
@onready var phone_button: Button = %PhoneButton
@onready var side_panel: Control = %SidePanel
@onready var location_buttons_container: VBoxContainer = %LocationButtonsContainer

const TIME_NAMES = ["Утро", "День", "Вечер", "Ночь"]
const TIME_COLORS = [
	Color(1.0, 0.95, 0.7),   # Утро — тёплый жёлтый
	Color(1.0, 1.0, 1.0),    # День — белый
	Color(0.9, 0.7, 0.5),    # Вечер — оранжевый
	Color(0.5, 0.5, 0.8),    # Ночь — синеватый
]

signal scene_requested(scene_path: String)

func _ready() -> void:
	# Smooth fade in transition
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)
	
	if has_node("/root/AudioManager"):
		AudioManager.play_event("map_open")
	
	_load_manifest()
	if phone_button: phone_button.pressed.connect(_on_phone_pressed)
	if get_node_or_null("%ToggleSidePanelButton"):
		%ToggleSidePanelButton.pressed.connect(_toggle_side_panel)
	
	_generate_tscn_files_once()
	
	_create_tooltip_ui()
	_refresh_map()
	_update_side_panel_locations()
	_update_time_hud()
	_update_quest_banner()
	_setup_ambient_barks()
	
	# Время: без пассивного таймера (action-based, как в VN/Persona)
	
	# Start background music
	_start_map_music()
	
	# Tutorial: first time on map
	if Variables.get_variable("map_tutorial_done") != 1:
		_run_map_tutorial()

func _run_map_tutorial() -> void:
	Variables.add_variable("map_tutorial_done", 1)
	
	# Small delay to let map render first
	await get_tree().create_timer(0.5).timeout
	
	var tutorial_path = "res://Story/00_Warsaw/00_map_tutorial.json"
	if FileAccess.file_exists(tutorial_path):
		var sp_scene = load("res://ScenePlayer.tscn")
		if sp_scene:
			# Создаём CanvasLayer, чтобы ScenePlayer был поверх UI карты (QuestBanner и т.д.)
			var canvas = CanvasLayer.new()
			canvas.name = "TutorialCanvas"
			canvas.layer = 100
			add_child(canvas)
			
			var sp = sp_scene.instantiate()
			sp.name = "TutorialScenePlayer"
			canvas.add_child(sp)
			
			# Для загрузки парсера
			var LoaderClass = load("res://Parser/JSONDialogueLoader.gd")
			var loader = LoaderClass.new()
			var tree = loader.load_scene(tutorial_path)
			
			if tree:
				sp.load_scene(tree)
				sp.scene_finished.connect(func():
					canvas.queue_free() # Удаляем вместе с CanvasLayer
				)
				sp.run_scene(0)

func _create_tooltip_ui() -> void:
	var custom_tt_path = "res://UI/WorldMap/Tooltip.tscn"
	if ResourceLoader.exists(custom_tt_path):
		var tt_packed = load(custom_tt_path)
		if tt_packed:
			_custom_tooltip_node = tt_packed.instantiate()
			_custom_tooltip_node.name = "CustomTooltipRoot"
			_custom_tooltip_node.visible = false
			_custom_tooltip_node.z_index = 100
			add_child(_custom_tooltip_node)
			custom_tooltip_loaded = true
			return
			
	_tooltip_root = Control.new()
	_tooltip_root.name = "TooltipRoot"
	_tooltip_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.visible = false
	_tooltip_root.z_index = 100
	
	# Main Container for unified outer red border
	var main_bg = PanelContainer.new()
	main_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color.BLACK # Inner black border
	main_style.border_width_left = 6; main_style.border_width_top = 6; main_style.border_width_right = 6; main_style.border_width_bottom = 6
	main_style.border_color = Color(0.85, 0.1, 0.2) # Thick red outer border
	main_style.content_margin_left = 4; main_style.content_margin_right = 4; main_style.content_margin_top = 4; main_style.content_margin_bottom = 4
	main_bg.add_theme_stylebox_override("panel", main_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_bg.add_child(vbox)
	
	_tooltip_portrait_panel = PanelContainer.new()
	_tooltip_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.1, 0.1, 0.1)
	_tooltip_portrait_panel.add_theme_stylebox_override("panel", p_style)
	
	_tooltip_portrait = TextureRect.new()
	_tooltip_portrait.custom_minimum_size = Vector2(250, 140)
	_tooltip_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tooltip_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tooltip_portrait_panel.add_child(_tooltip_portrait)
	vbox.add_child(_tooltip_portrait_panel)
	
	var text_panel = PanelContainer.new()
	text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color.WHITE
	t_style.border_width_left = 3; t_style.border_width_top = 4; t_style.border_width_right = 3; t_style.border_width_bottom = 3
	t_style.border_color = Color.BLACK
	t_style.content_margin_left = 12; t_style.content_margin_right = 12; t_style.content_margin_top = 10; t_style.content_margin_bottom = 10
	text_panel.add_theme_stylebox_override("panel", t_style)
	
	var inner_v = VBoxContainer.new()
	inner_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_title = Label.new()
	_tooltip_title.add_theme_font_size_override("font_size", 20)
	_tooltip_title.add_theme_color_override("font_color", Color.BLACK)
	inner_v.add_child(_tooltip_title)
	
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 12)
	
	# Stylized Exclamation Icon
	var icon_panel = PanelContainer.new()
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var i_style = StyleBoxFlat.new()
	i_style.bg_color = Color(0.95, 0.8, 0.2)
	i_style.border_width_left = 3; i_style.border_width_top = 3; i_style.border_width_right = 3; i_style.border_width_bottom = 3
	i_style.border_color = Color.BLACK
	if "skew" in i_style: i_style.skew = Vector2(0.1, 0.0)
	i_style.content_margin_left = 6; i_style.content_margin_right = 6
	icon_panel.add_theme_stylebox_override("panel", i_style)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_lbl = Label.new()
	icon_lbl.text = "!"
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.add_theme_color_override("font_color", Color.BLACK)
	icon_panel.add_child(icon_lbl)
	hbox.add_child(icon_panel)
	
	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 16)
	_tooltip_desc.add_theme_color_override("font_color", Color.BLACK)
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.custom_minimum_size = Vector2(160, 0)
	_tooltip_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tooltip_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_tooltip_desc)
	
	var go_panel = PanelContainer.new()
	go_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var go_style = StyleBoxFlat.new()
	go_style.bg_color = Color(0.95, 0.8, 0.2)
	go_style.border_width_left = 4; go_style.border_width_top = 4; go_style.border_width_right = 4; go_style.border_width_bottom = 4
	go_style.border_color = Color.BLACK
	go_style.content_margin_left = 12; go_style.content_margin_right = 12
	go_panel.add_theme_stylebox_override("panel", go_style)
	go_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var go_lbl = Label.new()
	go_lbl.text = "GO"
	go_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	go_lbl.add_theme_color_override("font_color", Color.BLACK)
	go_lbl.add_theme_font_size_override("font_size", 20)
	go_panel.add_child(go_lbl)
	hbox.add_child(go_panel)
	
	inner_v.add_child(hbox)
	text_panel.add_child(inner_v)
	vbox.add_child(text_panel)
	_tooltip_root.add_child(main_bg)
	
	# Tail piece (red triangle pointing down, from the bottom center of main_bg)
	var tail = ColorRect.new()
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.color = Color(0.85, 0.1, 0.2)
	tail.size = Vector2(40, 40)
	tail.rotation_degrees = 45
	tail.position = Vector2(160, -20)
	tail.z_index = -1
	
	# To make tail sit relative properly, we attach it to _tooltip_root with layout.
	# The position must be manually updated in _show_tooltip or we just attach it to text_panel!
	# Actually, since main_bg contains everything, the tail should be slightly below it.
	text_panel.add_child(tail)
	
	add_child(_tooltip_root)

func _update_time_hud() -> void:
	if not time_label: return
	
	# Hide old basic text label and its parent container
	var center_info = time_label.get_parent()
	center_info.visible = false
	var top_bar = center_info.get_parent()
	
	# Clear out any previous Anime HUD elements (SYNCHRONOUS delete!)
	var to_remove = []
	for c in top_bar.get_children():
		if c.name.begins_with("AnimeHUD_"):
			to_remove.append(c)
	for c in to_remove:
		top_bar.remove_child(c)
		c.free()
			
	var day = int(Variables.get_variable("current_day", 1))
	if day == 0: day = 1
	var time_idx = int(Variables.get_variable("current_time", 0))
	if time_idx < 0 or time_idx > 3: time_idx = 0
	
	if time_idx == 3:
		Variables.add_variable("is_night", 1)
	else:
		Variables.add_variable("is_night", 0)
	
	var hud_wrapper = Control.new()
	hud_wrapper.name = "AnimeHUD_Wrapper"
	hud_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(hud_wrapper)
	
	# --- Left HUD: DAY and TIME ---
	# Base black shadow/border
	var l_base = Panel.new()
	var lb_style = StyleBoxFlat.new()
	lb_style.bg_color = Color.BLACK
	l_base.add_theme_stylebox_override("panel", lb_style)
	l_base.size = Vector2(240, 90)
	l_base.position = Vector2(40, 15)
	l_base.rotation_degrees = -6
	hud_wrapper.add_child(l_base)
	
	# Top White panel (УТРО)
	var l_top = Panel.new()
	var lt_style = StyleBoxFlat.new()
	lt_style.bg_color = Color.WHITE
	lt_style.border_width_left = 4; lt_style.border_width_top = 4; lt_style.border_width_right = 4; lt_style.border_width_bottom = 4
	lt_style.border_color = Color.BLACK
	l_top.add_theme_stylebox_override("panel", lt_style)
	l_top.size = Vector2(230, 45)
	l_top.position = Vector2(40, 10)
	l_top.rotation_degrees = -6
	hud_wrapper.add_child(l_top)
	
	# Dynamic time icon and color
	var time_icon = "🌅"
	var time_panel_color = Color(0.85, 0.7, 0.95)
	var day_panel_color = Color(0.2, 0.8, 0.2)
	match time_idx:
		0:
			time_icon = "🌅"
			time_panel_color = Color(0.85, 0.7, 0.95) # Фиолетовый рассвет
			day_panel_color = Color(0.6, 0.4, 0.8)
		1:
			time_icon = "☀️"
			time_panel_color = Color(1.0, 0.95, 0.8) # Ясный жёлтый
			day_panel_color = Color(0.2, 0.75, 0.3)
		2:
			time_icon = "🌇"
			time_panel_color = Color(1.0, 0.7, 0.4) # Оранжевый закат
			day_panel_color = Color(0.9, 0.5, 0.2)
		3:
			time_icon = "🌙"
			time_panel_color = Color(0.25, 0.25, 0.5) # Глубокий синий
			day_panel_color = Color(0.15, 0.15, 0.4)
	
	var time_lbl = Label.new()
	time_lbl.text = time_icon + " " + TIME_NAMES[time_idx].to_upper()
	time_lbl.add_theme_font_size_override("font_size", 24)
	time_lbl.add_theme_color_override("font_color", Color.BLACK if time_idx != 3 else Color.WHITE)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_lbl.size = l_top.size
	l_top.add_child(time_lbl)
	
	# Tint the top panel based on time
	lt_style.bg_color = time_panel_color
	
	# Bottom Green panel (ДЕНЬ)
	var l_bot = Panel.new()
	var lbot_style = StyleBoxFlat.new()
	lbot_style.bg_color = day_panel_color
	lbot_style.border_width_left = 4; lbot_style.border_width_top = 4; lbot_style.border_width_right = 4; lbot_style.border_width_bottom = 4
	lbot_style.border_color = Color.BLACK
	l_bot.add_theme_stylebox_override("panel", lbot_style)
	l_bot.size = Vector2(250, 45)
	l_bot.position = Vector2(35, 50)
	l_bot.rotation_degrees = -6
	hud_wrapper.add_child(l_bot)
	
	var day_lbl = Label.new()
	day_lbl.text = "📅 ДЕНЬ %d" % day
	day_lbl.add_theme_font_size_override("font_size", 22)
	day_lbl.add_theme_color_override("font_color", Color.BLACK if time_idx != 3 else Color.WHITE)
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_lbl.size = l_bot.size
	l_bot.add_child(day_lbl)
	
	# --- Right HUD: STATS ---
	var right_container = Control.new()
	right_container.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	right_container.offset_left = -350
	right_container.offset_top = 20
	right_container.offset_right = -30
	right_container.offset_bottom = 120
	hud_wrapper.add_child(right_container)
	
	var y_offset = 0
	
	# Инициализация статов, если их ещё нет
	var hunger = Variables.get_variable("hunger", -1)
	if hunger <= 0 and hunger != 0: # -1 means not set
		hunger = 100
		Variables.add_variable("hunger", 100)
		
	var energy = Variables.get_variable("energy", -1)
	if energy <= 0 and energy != 0:
		energy = 100
		Variables.add_variable("energy", 100)
		
	var money = GameGlobal.player_money
	
	_create_stat_panel(right_container, "ДЕНЬГИ", str(int(money)) + "$", y_offset, Color(0.2, 0.8, 0.3))
	y_offset += 55
	
	_create_stat_panel(right_container, "СЫТОСТЬ", str(int(hunger)), y_offset, Color(0.9, 0.2, 0.2))
	y_offset += 55
	
	_create_stat_panel(right_container, "ЭНЕРГИЯ", str(int(energy)), y_offset, Color(0.2, 0.6, 0.9))
	y_offset += 55
		
	# Days Left Alert Panel
	var days_left = Variables.get_variable("days_left", -1)
	if days_left >= 0:
		_create_stat_panel(right_container, "ОСТАЛОСЬ ДНЕЙ", str(int(days_left)), y_offset, Color.RED)
		
	_style_top_buttons()

func _create_stat_panel(parent: Control, title: String, val: String, y_pos: float, accent: Color = Color(0.95, 0.8, 0.2)) -> void:
	var p = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_width_left = 4; style.border_width_top = 4; style.border_width_right = 4; style.border_width_bottom = 4
	style.border_color = Color.BLACK
	p.add_theme_stylebox_override("panel", style)
	p.size = Vector2(280, 40)
	p.position = Vector2(0, y_pos)
	p.rotation_degrees = 3
	parent.add_child(p)
	
	# Accent color stripe at bottom
	var stripe = ColorRect.new()
	stripe.color = accent
	stripe.size = Vector2(272, 6)
	stripe.position = Vector2(4, 30)
	p.add_child(stripe)
	
	var val_lbl = Label.new()
	val_lbl.text = val
	val_lbl.add_theme_font_size_override("font_size", 22)
	val_lbl.add_theme_color_override("font_color", Color.BLACK)
	val_lbl.position = Vector2(20, 5)
	p.add_child(val_lbl)
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color.BLACK)
	title_lbl.position = Vector2(100, 10)
	p.add_child(title_lbl)

func _style_top_buttons() -> void:
	var btn_loc = get_node_or_null("%ToggleSidePanelButton")
	var btn_phone = get_node_or_null("%PhoneButton")
	for b in [btn_loc, btn_phone]:
		if b and b is Button:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color.WHITE
			sb.border_width_left = 4; sb.border_width_top = 4; sb.border_width_right = 4; sb.border_width_bottom = 4
			sb.border_color = Color.BLACK
			sb.content_margin_left = 16; sb.content_margin_right = 16; sb.content_margin_top = 8; sb.content_margin_bottom = 8
			if "skew" in sb:
				sb.skew = Vector2(0.2, 0.0)
			b.add_theme_stylebox_override("normal", sb)
			var sb_h = sb.duplicate()
			sb_h.bg_color = Color(0.85, 0.1, 0.2)
			b.add_theme_stylebox_override("hover", sb_h)
			b.add_theme_color_override("font_color", Color.BLACK)
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			b.rotation_degrees = 0
			if "skew" in b:
				b.skew = 0.1 # Try canvas level skew as well for 4.x
			
	# Also hide container bg if needed
	var c = get_node_or_null("%TopLeftMenu")
	if c and c is PanelContainer:
		var st = StyleBoxEmpty.new()
		c.add_theme_stylebox_override("panel", st)

func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("Main story manifest not found!")
		return
	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		manifest_data = json.get_data()

func set_location(loc_id: String) -> void:
	current_location_id = loc_id
	_refresh_map()

func _refresh_map() -> void:
	var time_idx = int(Variables.get_variable("current_time", 0))
	if time_idx < 0 or time_idx > 3: time_idx = 0
	
	# === DAY-NIGHT MODULATE ===
	var time_modulate = get_node_or_null("DayNightModulate")
	if time_modulate:
		var target_color = Color.WHITE
		match time_idx:
			0: target_color = Color(0.92, 0.88, 0.98)
			1: target_color = Color(1.0, 1.0, 1.0)
			2: target_color = Color(0.95, 0.65, 0.45)
			3: target_color = Color(0.35, 0.35, 0.55)  # Ночь — тёмный, но ЧИТАЕМЫЙ
		time_modulate.color = target_color  # Instant on first load
	
	# === CLOUDS: instant set on first load ===
	var cloud_layer = map_background.get_node_or_null("CloudLayer")
	if cloud_layer:
		match time_idx:
			0: cloud_layer.modulate = Color(1.0, 1.0, 1.0, 0.4)
			1: cloud_layer.modulate = Color(1.0, 1.0, 1.0, 0.0)
			2: cloud_layer.modulate = Color(1.0, 0.7, 0.5, 0.5)
			3: cloud_layer.modulate = Color(0.4, 0.4, 0.6, 0.3)
		
	var preplaced_nodes = []
	for child in nodes_container.get_children():
		# Preserve nodes that the user placed manually in the inspector
		if child.has_method("setup") or child.name.begins_with("MapNode"):
			preplaced_nodes.append(child)
			child.visible = false # hide them initially, show only if unlocked
		else:
			child.queue_free()
	
	# Map background color
	if current_location_id == "warsaw_center":
		var img_loaded = false
		var img_path = ProjectSettings.globalize_path("res://Assets/Textures/Maps/map_bg_warsaw.png")
		if FileAccess.file_exists(img_path):
			var img = Image.load_from_file(img_path)
			if img:
				var tex = ImageTexture.create_from_image(img)
				map_background.texture = tex
				map_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				map_background.modulate = Color(1.0, 1.0, 1.0)
				img_loaded = true
				
		var fallback = map_background.get_node_or_null("MapColorFallback")
		if fallback:
			if img_loaded:
				fallback.visible = false
				fallback.material = null
			else:
				fallback.visible = true
				fallback.color = Color(1.0, 1.0, 1.0, 0.0) # Hide fallback dots if image loaded
				var sm = ShaderMaterial.new()
				var shader = Shader.new()
				shader.code = """
shader_type canvas_item;
uniform vec4 bg_color = vec4(0.85, 0.95, 0.85, 1.0); // Bright pale green
uniform vec4 dot_color = vec4(0.5, 0.85, 0.6, 0.8);  // Cyan-green dots
uniform float speed = 15.0;

void fragment() {
	vec2 uv = FRAGCOORD.xy;
	uv.x += TIME * speed;
	uv.y += TIME * speed * 0.5;
	
	vec2 grid = fract(uv / 30.0);
	float dist = distance(grid, vec2(0.5));
	
	if (dist < 0.25) {
		COLOR = dot_color;
	} else {
		COLOR = bg_color;
	}
}
				"""
				sm.shader = shader
				fallback.material = sm
			
	elif current_location_id == "oboyan_center":
		map_background.texture = null
		var fallback = map_background.get_node_or_null("MapColorFallback")
		if fallback: 
			fallback.material = null
			fallback.color = Color(0.22, 0.16, 0.1)
	
	if not manifest_data.has("locations"): return
	
	var loc_data = null
	for loc in manifest_data["locations"]:
		if loc["id"] == current_location_id:
			loc_data = loc
			break
	if not loc_data: return
	
	location_label.text = loc_data.get("name", "Unknown")
	
	if loc_data.has("nodes"):
		for node in loc_data["nodes"]:
			if _check_requirements(node.get("requires", [])):
				var nid = node.get("id", "")
				var existing_node = null
				
				# Check if the user placed this node manually in the scene
				for pn in preplaced_nodes:
					var ed_id = pn.get("location_id") if "location_id" in pn else ""
					if ed_id == nid or pn.name.to_lower().ends_with(nid.to_lower()):
						existing_node = pn
						break
				
				if existing_node:
					existing_node.visible = true
					var chibi_id = node.get("chibi", "")
					var tex_path = _get_chibi_texture(chibi_id)
					existing_node.setup(node, tex_path)
					
					# Connect manually placed node signals
					if not existing_node.node_clicked.is_connected(_on_node_clicked):
						existing_node.node_clicked.connect(_on_node_clicked)
						existing_node.node_hovered.connect(_on_node_hovered)
						existing_node.node_unhovered.connect(_hide_tooltip)
				else:
					# Fallback logic: auto-create the node like before
					_create_map_node(node)

func _on_node_clicked(scene_path: String) -> void:
	_hide_tooltip()
	
	# Поездка забирает силы и сытость
	var h = int(Variables.get_variable("hunger", 100)) - 10
	var e = int(Variables.get_variable("energy", 100)) - 10
	Variables.add_variable("hunger", clamp(h, 0, 100))
	Variables.add_variable("energy", clamp(e, 0, 100))
	
	if h <= 0 or e <= 0:
		_handle_exhaustion()
		return
		
	# Ироничная концовка "Долгая счастливая жизнь на заводе" (50 дней)
	if scene_path.ends_with("02_factory_shift.json"):
		if int(Variables.get_variable("current_day", 1)) >= 50 and int(Variables.get_variable("refused_johny", 0)) == 1:
			scene_requested.emit("res://Story/00_Warsaw/factory_death_ending.json")
			return
		
	# 15% шанс случайного события в пути
	if randf() < 0.15:
		var event_type = (randi() % 4) + 1
		Variables.add_variable("random_event_type", event_type)
		var event_path = "res://Story/00_Warsaw/random_event.json"
		if FileAccess.file_exists(event_path):
			scene_requested.emit(event_path)
			return
			
	scene_requested.emit(scene_path)

func _on_node_hovered(title: String, desc: String, icon: String, pos: Vector2, chibi_id: String, chibi_path: String) -> void:
	_show_tooltip(title, desc, icon, pos, chibi_id)

func _check_requirements(reqs: Array) -> bool:
	for req in reqs:
		var r_str = str(req)
		if r_str.begins_with("!"):
			var r = r_str.substr(1)
			if Variables.get_variable(r) == 1:
				return false
		else:
			if Variables.get_variable(req) != 1:
				return false
	return true

func _create_map_node(data: Dictionary) -> void:
	var chibi_id = data.get("chibi", "")
	var tex_path = _get_chibi_texture(chibi_id)
	var pos_data = data.get("position", {"x": 0, "y": 0})
	var icon_size := Vector2(100, 100)
	var target_pos = Vector2(pos_data.get("x", 0), pos_data.get("y", 0)) - icon_size / 2
	
	# Сначала проверяем, создал ли пользователь свою сцену
	var custom_node_path = "res://UI/WorldMap/MapNode.tscn"
	if ResourceLoader.exists(custom_node_path):
		var custom_packed = load(custom_node_path)
		if custom_packed:
			var node = custom_packed.instantiate()
			node.position = target_pos
			node.setup(data, tex_path)
			
			node.node_clicked.connect(_on_node_clicked)
			node.node_hovered.connect(_on_node_hovered)
			node.node_unhovered.connect(_hide_tooltip)
			
			nodes_container.add_child(node)
			return # Пропускаем программную генерацию
			
	# Container for icon + label (Fallback)
	var container = Control.new()
	container.name = "Node_" + data.get("id", "unknown")
	
	var node_name = data.get("name", "???").to_upper()
	var node_desc = data.get("description", "")
	var node_icon = data.get("icon", "📍")
	
	# --- Background Badge (Stylized Comic Box) ---
	var shadow_badge = Panel.new()
	var sb_style = StyleBoxFlat.new()
	sb_style.bg_color = Color.BLACK
	shadow_badge.add_theme_stylebox_override("panel", sb_style)
	shadow_badge.size = Vector2(80, 80)
	shadow_badge.rotation_degrees = -8
	shadow_badge.position = Vector2(0, -56)
	shadow_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(shadow_badge)

	var badge = Panel.new()
	var b_style = StyleBoxFlat.new()
	# Different colors for different node types
	var b_color = Color(0.85, 0.15, 0.25) # Vibrant Red default
	if data.get("id") == "home" or data.get("id") == "home_finale": b_color = Color(0.1, 0.5, 0.9)
	elif data.get("id") == "academy": b_color = Color(0.2, 0.8, 0.3)
	elif data.get("id") == "factory": b_color = Color(0.4, 0.4, 0.4)
	elif data.get("id") == "casino": b_color = Color(0.7, 0.2, 0.8)
	
	b_style.bg_color = b_color
	b_style.border_width_left = 6
	b_style.border_width_top = 6
	b_style.border_width_right = 6
	b_style.border_width_bottom = 6
	b_style.border_color = Color.WHITE
	
	badge.add_theme_stylebox_override("panel", b_style)
	badge.size = Vector2(80, 80)
	badge.rotation_degrees = 4 # Pop overlay offset
	badge.position = Vector2(0, -60)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(badge)
	
	# Portrait / Icon inside Badge
	var has_tex = ResourceLoader.exists(tex_path)
	if has_tex:
		var tex = TextureRect.new()
		tex.texture = load(tex_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size = Vector2(70, 70)
		tex.position = Vector2(5, -15) # Pops out of frame slightly
		tex.rotation_degrees = -4 # Sub-rotation for neatness
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(tex)
	else:
		var emoji = Label.new()
		emoji.text = node_icon
		emoji.add_theme_font_size_override("font_size", 40)
		emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emoji.size = Vector2(80, 80)
		emoji.rotation_degrees = -4
		emoji.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(emoji)
	
	# --- Stylized Name Label ---
	var lbl_panel = PanelContainer.new()
	var l_style = StyleBoxFlat.new()
	l_style.bg_color = Color.WHITE
	l_style.border_width_left = 4
	l_style.border_width_top = 4
	l_style.border_width_right = 4
	l_style.border_width_bottom = 4
	l_style.border_color = Color.BLACK
	l_style.content_margin_left = 12
	l_style.content_margin_right = 12
	l_style.content_margin_top = 4
	l_style.content_margin_bottom = 4
	if "skew" in l_style: l_style.skew = Vector2(0.15, 0.0)
	lbl_panel.add_theme_stylebox_override("panel", l_style)
	lbl_panel.position = Vector2(-30, 25) # Shift down so it doesn't overlap horribly
	lbl_panel.rotation_degrees = -3
	lbl_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var name_lbl = Label.new()
	name_lbl.text = node_name
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl_panel.add_child(name_lbl)
	container.add_child(lbl_panel)
	
	# --- Clickable button overlay ---
	var btn = Button.new()
	btn.flat = true
	btn.size = Vector2(160, 140)
	btn.position = Vector2(-30, -70)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Hover effects
	btn.mouse_entered.connect(func():
		b_style.border_color = Color.WHITE
		b_style.shadow_color = Color(0.9, 0.1, 0.3)
		container.scale = Vector2(1.15, 1.15)
		container.z_index = 50
		_show_tooltip(node_name, node_desc, node_icon, container.global_position, chibi_id)
	)
	btn.mouse_exited.connect(func():
		b_style.border_color = Color.BLACK
		b_style.shadow_color = Color(0, 0, 0, 1)
		container.scale = Vector2(1.0, 1.0)
		container.z_index = 0
		_hide_tooltip()
	)
	btn.pressed.connect(func():
		_hide_tooltip()
		scene_requested.emit(data.get("scene", ""))
	)
	container.add_child(btn)
	
	# Position
	container.position = target_pos
	
	# Bobbing animation
	var base_y = container.position.y
	var tw = create_tween().set_loops()
	tw.tween_property(container, "position:y", base_y - 8, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(container, "position:y", base_y, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Свечение нодов ночью для видимости
	var time_idx_glow = int(Variables.get_variable("current_time", 0))
	if time_idx_glow == 3:
		container.modulate = Color(1.3, 1.3, 1.6)  # Яркое голубоватое свечение ночью
	
	# Pulse for "quest critical" nodes
	if data.get("id", "") in ["hq", "home_finale", "streets", "academy"]:
		var pulse_tw = create_tween().set_loops()
		pulse_tw.tween_property(container, "modulate:a", 0.7, 0.8).set_trans(Tween.TRANS_SINE)
		pulse_tw.tween_property(container, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	
	nodes_container.add_child(container)

func _show_tooltip(title: String, desc: String, icon: String, pos: Vector2, chibi_id: String = "") -> void:
	var tex_path = _get_chibi_texture(chibi_id)
	
	if custom_tooltip_loaded and _custom_tooltip_node:
		_custom_tooltip_node.show_info(title, desc, chibi_id, tex_path)
		_custom_tooltip_node.global_position = pos - Vector2(120, 180) # смещение над узлом
		return
		
	if not _tooltip_root: return
	_tooltip_title.text = title
	_tooltip_desc.text = desc if desc != "" else "Нет задач."
	
	if chibi_id != "" and ResourceLoader.exists(tex_path):
		_tooltip_portrait.texture = load(tex_path)
		_tooltip_portrait_panel.visible = true
	else:
		_tooltip_portrait_panel.visible = false
	
	_tooltip_root.position = pos - Vector2(120, 180) # adjust offset to anchor tail
	_tooltip_root.visible = true

func _hide_tooltip() -> void:
	if custom_tooltip_loaded and _custom_tooltip_node:
		_custom_tooltip_node.hide_info()
		return
		
	if _tooltip_root:
		_tooltip_root.visible = false

func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	if node != new_owner:
		node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)

func _generate_tscn_files_once() -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("UI/WorldMap"):
		dir.make_dir_recursive("UI/WorldMap")
	
	# --- MAP NODE ---
	var m_path = "res://UI/WorldMap/MapNode.tscn"
	if not FileAccess.file_exists(m_path):
		var root = Control.new()
		root.name = "MapNode"
		
		var shadow_badge = Panel.new()
		shadow_badge.name = "ShadowBadge"
		var sb_style = StyleBoxFlat.new()
		sb_style.bg_color = Color.BLACK
		shadow_badge.add_theme_stylebox_override("panel", sb_style)
		shadow_badge.size = Vector2(80, 80)
		shadow_badge.rotation_degrees = -8
		shadow_badge.position = Vector2(0, -56)
		shadow_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(shadow_badge)
		
		var badge = Panel.new()
		badge.name = "Badge"
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(0.85, 0.15, 0.25)
		b_style.border_width_left = 4; b_style.border_width_top = 4; b_style.border_width_right = 4; b_style.border_width_bottom = 4
		b_style.border_color = Color.WHITE
		badge.add_theme_stylebox_override("panel", b_style)
		badge.size = Vector2(80, 80)
		badge.rotation_degrees = 4
		badge.position = Vector2(0, -60)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(badge)
		
		var tex = TextureRect.new()
		tex.name = "Portrait"
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size = Vector2(70, 70)
		tex.position = Vector2(5, -15)
		tex.rotation_degrees = -4
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(tex)
		
		var lbl_panel = PanelContainer.new()
		var l_style = StyleBoxFlat.new()
		l_style.bg_color = Color.WHITE
		l_style.border_width_left = 4; l_style.border_width_top = 4; l_style.border_width_right = 4; l_style.border_width_bottom = 4
		l_style.border_color = Color.BLACK
		l_style.content_margin_left = 12; l_style.content_margin_right = 12; l_style.content_margin_top = 4; l_style.content_margin_bottom = 4
		if "skew" in l_style: l_style.skew = Vector2(0.15, 0.0)
		lbl_panel.add_theme_stylebox_override("panel", l_style)
		lbl_panel.position = Vector2(-30, 25)
		lbl_panel.rotation_degrees = -3
		lbl_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var name_lbl = Label.new()
		name_lbl.name = "NameLabel"
		name_lbl.text = "LOCAL"
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color.BLACK)
		lbl_panel.add_child(name_lbl)
		root.add_child(lbl_panel)
		
		var btn = Button.new()
		btn.name = "Button"
		btn.flat = true
		btn.size = Vector2(160, 140)
		btn.position = Vector2(-30, -70)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		root.add_child(btn)
		
		var script_path = "res://UI/WorldMap/MapNode.gd"
		if ResourceLoader.exists(script_path):
			root.set_script(load(script_path))
			
		_set_owner_recursive(root, root)
		var packed = PackedScene.new()
		packed.pack(root)
		ResourceSaver.save(packed, m_path)
		
	# --- GENERATE TOOLTIP ---
	var t_path = "res://UI/WorldMap/Tooltip.tscn"
	if not FileAccess.file_exists(t_path):
		var root = Control.new()
		root.name = "TooltipP5"
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var main_bg = PanelContainer.new()
		main_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var main_style = StyleBoxFlat.new()
		main_style.bg_color = Color.BLACK 
		main_style.border_width_left = 6; main_style.border_width_top = 6; main_style.border_width_right = 6; main_style.border_width_bottom = 6
		main_style.border_color = Color(0.85, 0.1, 0.2) 
		main_style.content_margin_left = 4; main_style.content_margin_right = 4; main_style.content_margin_top = 4; main_style.content_margin_bottom = 4
		main_bg.add_theme_stylebox_override("panel", main_style)
		root.add_child(main_bg)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 0)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_bg.add_child(vbox)
		
		var _tooltip_portrait_panel = PanelContainer.new()
		_tooltip_portrait_panel.name = "PortraitContainer"
		_tooltip_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.1, 0.1, 0.1)
		_tooltip_portrait_panel.add_theme_stylebox_override("panel", p_style)
		
		var _tooltip_portrait = TextureRect.new()
		_tooltip_portrait.name = "Portrait"
		_tooltip_portrait.custom_minimum_size = Vector2(250, 140)
		_tooltip_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_tooltip_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_tooltip_portrait_panel.add_child(_tooltip_portrait)
		vbox.add_child(_tooltip_portrait_panel)
		
		var text_panel = PanelContainer.new()
		text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t_style = StyleBoxFlat.new()
		t_style.bg_color = Color.WHITE
		t_style.border_width_left = 3; t_style.border_width_top = 4; t_style.border_width_right = 3; t_style.border_width_bottom = 3
		t_style.border_color = Color.BLACK
		t_style.content_margin_left = 12; t_style.content_margin_right = 12; t_style.content_margin_top = 10; t_style.content_margin_bottom = 10
		text_panel.add_theme_stylebox_override("panel", t_style)
		
		var inner_v = VBoxContainer.new()
		inner_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var _tooltip_title = Label.new()
		_tooltip_title.name = "Title"
		_tooltip_title.text = "TITLE"
		_tooltip_title.add_theme_font_size_override("font_size", 20)
		_tooltip_title.add_theme_color_override("font_color", Color.BLACK)
		inner_v.add_child(_tooltip_title)
		
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 12)
		
		var icon_panel = PanelContainer.new()
		icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var i_style = StyleBoxFlat.new()
		i_style.bg_color = Color(0.95, 0.8, 0.2)
		i_style.border_width_left = 3; i_style.border_width_top = 3; i_style.border_width_right = 3; i_style.border_width_bottom = 3
		i_style.border_color = Color.BLACK
		if "skew" in i_style: i_style.skew = Vector2(0.1, 0.0)
		i_style.content_margin_left = 6; i_style.content_margin_right = 6
		icon_panel.add_theme_stylebox_override("panel", i_style)
		icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var icon_lbl = Label.new()
		icon_lbl.text = "!"
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_lbl.add_theme_font_size_override("font_size", 22)
		icon_lbl.add_theme_color_override("font_color", Color.BLACK)
		icon_panel.add_child(icon_lbl)
		hbox.add_child(icon_panel)
		
		var _tooltip_desc = Label.new()
		_tooltip_desc.name = "Desc"
		_tooltip_desc.text = "Description here"
		_tooltip_desc.add_theme_font_size_override("font_size", 16)
		_tooltip_desc.add_theme_color_override("font_color", Color.BLACK)
		_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tooltip_desc.custom_minimum_size = Vector2(160, 0)
		_tooltip_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tooltip_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(_tooltip_desc)
		
		var go_panel = PanelContainer.new()
		go_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var go_style = StyleBoxFlat.new()
		go_style.bg_color = Color(0.95, 0.8, 0.2)
		go_style.border_width_left = 4; go_style.border_width_top = 4; go_style.border_width_right = 4; go_style.border_width_bottom = 4
		go_style.border_color = Color.BLACK
		go_style.content_margin_left = 12; go_style.content_margin_right = 12
		go_panel.add_theme_stylebox_override("panel", go_style)
		go_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var go_lbl = Label.new()
		go_lbl.text = "GO"
		go_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		go_lbl.add_theme_color_override("font_color", Color.BLACK)
		go_lbl.add_theme_font_size_override("font_size", 20)
		go_panel.add_child(go_lbl)
		hbox.add_child(go_panel)
		
		inner_v.add_child(hbox)
		text_panel.add_child(inner_v)
		vbox.add_child(text_panel)
		
		var tail = ColorRect.new()
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tail.color = Color(0.85, 0.1, 0.2)
		tail.size = Vector2(40, 40)
		tail.rotation_degrees = 45
		tail.position = Vector2(160, -20)
		tail.z_index = -1
		text_panel.add_child(tail)
		
		var script_path = "res://UI/WorldMap/Tooltip.gd"
		if ResourceLoader.exists(script_path):
			root.set_script(load(script_path))
			
		_set_owner_recursive(root, root)
		var packed = PackedScene.new()
		packed.pack(root)
		ResourceSaver.save(packed, t_path)

func _update_side_panel_locations() -> void:
	if not location_buttons_container: return
	for child in location_buttons_container.get_children():
		child.queue_free()
	if manifest_data.has("locations"):
		for loc in manifest_data["locations"]:
			if _check_requirements(loc.get("requires_location", [])):
				var btn = Button.new()
				btn.text = loc.get("name", "Unknown")
				btn.custom_minimum_size = Vector2(0, 50)
				btn.add_theme_font_size_override("font_size", 20)
				if loc["id"] == current_location_id:
					btn.disabled = true
					btn.modulate = Color(0.5, 1.0, 0.5)
				btn.pressed.connect(func():
					set_location(loc["id"])
					_update_side_panel_locations()
				)
				location_buttons_container.add_child(btn)

func _toggle_side_panel() -> void:
	if not side_panel: return
	var target_x = -300 if side_panel.position.x == 0 else 0
	var tw = create_tween()
	tw.tween_property(side_panel, "position:x", target_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _get_chibi_texture(chibi_id: String) -> String:
	match chibi_id:
		"danila": return "res://Characters/Danila/danila_neutral.png"
		"worker": return "res://Characters/Worker/worker_neutral.png"
		"boss": return "res://Characters/boss_of_factory/boss_of_factory_angry.png"
	return ""

func _on_phone_pressed() -> void:
	if not has_node("PhoneHUD"):
		var phone = PHONE_HUD_SCENE.instantiate()
		phone.name = "PhoneHUD"
		add_child(phone)
	else:
		get_node("PhoneHUD").toggle()

func _update_quest_banner() -> void:
	var quest_label = get_node_or_null("%QuestLabel")
	var quest_banner = get_node_or_null("%QuestBanner")
	if not quest_label or not quest_banner: return
	
	if not manifest_data.has("locations"):
		quest_banner.visible = false
		return
	
	# Найти первый доступный main-квест
	var quest_name := ""
	for loc in manifest_data["locations"]:
		if loc["id"] != current_location_id: continue
		if not loc.has("nodes"): continue
		for node in loc["nodes"]:
			if node.get("priority", "") == "main":
				if _check_requirements(node.get("requires", [])):
					quest_name = node.get("name", "")
					break
		if quest_name != "": break
	
	if quest_name == "":
		quest_banner.visible = false
		return
	
	quest_banner.visible = true
	quest_label.text = "📋 ЦЕЛЬ: " + quest_name.to_upper()
	
	# Анимация появления
	quest_banner.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(quest_banner, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)

func _advance_time_action() -> void:
	var time_idx = Variables.get_variable("current_time")
	if time_idx < 0 or time_idx > 3: time_idx = 0
	
	time_idx += 1
	if time_idx > 3:
		time_idx = 0
		var day = Variables.get_variable("current_day", 1)
		Variables.add_variable("current_day", day + 1)
	
	Variables.add_variable("current_time", time_idx)
	
	# Action cost
	var h = int(Variables.get_variable("hunger", 100)) - 20
	var e = int(Variables.get_variable("energy", 100)) - 20
	Variables.add_variable("hunger", clamp(h, 0, 100))
	Variables.add_variable("energy", clamp(e, 0, 100))
	
	_update_weather_visuals_instant(time_idx)
	_update_time_hud()
	_refresh_map()
	_update_quest_banner()
	
	# Если наступила ночь — показать уведомление «Пора домой»
	if time_idx == 3:
		_show_night_popup()
	
	if h <= 0 or e <= 0:
		_handle_exhaustion()

# === REAL-TIME CLOCK TICK (DISABLED) ===
func _on_time_tick() -> void:
	pass

func _show_night_popup() -> void:
	var popup = PanelContainer.new()
	popup.name = "NightPopup"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.95)
	style.border_width_left = 4; style.border_width_top = 4
	style.border_width_right = 4; style.border_width_bottom = 4
	style.border_color = Color(0.3, 0.3, 0.8)
	style.content_margin_left = 30; style.content_margin_right = 30
	style.content_margin_top = 20; style.content_margin_bottom = 20
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var icon = Label.new()
	icon.text = "🌙"
	icon.add_theme_font_size_override("font_size", 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)
	
	var title = Label.new()
	title.text = "НАСТУПИЛА НОЧЬ"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "Всё закрыто. Иди домой и ложись спать."
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	popup.add_child(vbox)
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.z_index = 60
	add_child(popup)
	
	# Анимация: появление → исчезновение через 3 секунды
	popup.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(popup, "modulate:a", 1.0, 0.5)
	tw.tween_interval(3.0)
	tw.tween_property(popup, "modulate:a", 0.0, 0.5)
	tw.tween_callback(popup.queue_free)

func _handle_exhaustion() -> void:
	print("🚨 ОБМОРОК ОТ ИСТОЩЕНИЯ!")
	# Сброс статов
	Variables.add_variable("hunger", 50)
	Variables.add_variable("energy", 50)
	
	# Штраф денег (20%)
	var penalty = int(GameGlobal.player_money * 0.2)
	if penalty > 0:
		GameGlobal.remove_money(penalty)
	
	# Промотаем время на следующий день/период
	var time_idx = Variables.get_variable("current_time", 0) + 1
	if time_idx > 3:
		time_idx = 0
		Variables.add_variable("current_day", Variables.get_variable("current_day", 1) + 1)
	Variables.add_variable("current_time", time_idx)
	
	_update_weather_visuals_instant(time_idx)
	_update_time_hud()
	_refresh_map()
	
	# Визуальное уведомление
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.1, 0.1, 0.9)
	style.border_width_left = 6; style.border_width_top = 6; style.border_width_right = 6; style.border_width_bottom = 6
	style.border_color = Color.BLACK
	panel.add_theme_stylebox_override("panel", style)
	
	var text = Label.new()
	text.text = "ВЫ ПОТЕРЯЛИ СОЗНАНИЕ ОТ ИСТОЩЕНИЯ.\nПока вы спали на улице, вас обокрали на %d$." % penalty
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 24)
	text.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(text)
	
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position -= Vector2(300, 100)
	add_child(panel)
	
	var tw = create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(panel, "modulate:a", 0.0, 1.0)
	tw.tween_callback(panel.queue_free)

# Continuous interpolation every frame — no more abrupt transitions!
const CLOUD_STATES = [
	Color(1.0, 1.0, 1.0, 0.4),   # 0 Утро: белые, видимые
	Color(1.0, 1.0, 1.0, 0.0),   # 1 День: полностью прозрачные
	Color(1.0, 0.7, 0.5, 0.5),   # 2 Вечер: оранжевые, видимые
	Color(0.4, 0.4, 0.6, 0.3),   # 3 Ночь: тёмно-серые, еле видны
]
const LIGHT_STATES = [
	Color(0.92, 0.88, 0.98),     # Утро
	Color(1.0, 1.0, 1.0),        # День
	Color(0.95, 0.65, 0.45),     # Вечер
	Color(0.35, 0.35, 0.55),     # Ночь — тёмный, но видимый
]

func _process(_delta: float) -> void:
	# Обработка системных команд продвижения времени из JSON-сценариев
	var passed = Variables.get_variable("system_pass_time", 0)
	if passed > 0:
		Variables.add_variable("system_pass_time", 0)
		for i in range(passed):
			_advance_time_action()

# Мгновенное обновление визуала погоды (без плавной интерполяции)
func _update_weather_visuals_instant(time_idx: int) -> void:
	if time_idx < 0 or time_idx > 3: time_idx = 0
	
	var cloud_layer = map_background.get_node_or_null("CloudLayer")
	if cloud_layer:
		cloud_layer.modulate = CLOUD_STATES[time_idx]
	
	var time_modulate = get_node_or_null("DayNightModulate")
	if time_modulate:
		# Плавный переход через tween вместо мгновенного
		var tw = create_tween()
		tw.tween_property(time_modulate, "color", LIGHT_STATES[time_idx], 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# === BACKGROUND MUSIC (via AudioManager) ===
const LOCATION_MUSIC = {
	"warsaw_center": "res://Assets/Audio/Music/WorldMap",
	"oboyan_center": "res://Assets/Audio/Music/WorldMap",
}

func _start_map_music() -> void:
	var music_folder = LOCATION_MUSIC.get(current_location_id, "res://Assets/Audio/Music/WorldMap")
	
	# Scan folder for first available track
	var d = DirAccess.open(music_folder)
	if not d:
		return
	
	var tracks: Array[String] = []
	d.list_dir_begin()
	var file = d.get_next()
	while file != "":
		if not d.current_is_dir() and not file.begins_with("."):
			var clean = file.replace(".import", "").replace(".remap", "")
			if clean.ends_with(".ogg") or clean.ends_with(".mp3") or clean.ends_with(".wav"):
				var full_path = music_folder + "/" + clean
				if not tracks.has(full_path):
					tracks.append(full_path)
		file = d.get_next()
	
	if tracks.is_empty():
		return
	
	tracks.shuffle()
	AudioManager.play_bgm(tracks[0])

# === AMBIENT BARKS ===
var _ambient_bark_timer: Timer

func _setup_ambient_barks() -> void:
	_ambient_bark_timer = Timer.new()
	_ambient_bark_timer.wait_time = randf_range(15.0, 25.0)
	_ambient_bark_timer.one_shot = true
	_ambient_bark_timer.timeout.connect(_on_ambient_bark_timer_timeout)
	add_child(_ambient_bark_timer)
	_ambient_bark_timer.start()

func _on_ambient_bark_timer_timeout() -> void:
	# Restart timer with random interval
	_ambient_bark_timer.wait_time = randf_range(15.0, 30.0)
	_ambient_bark_timer.start()
	
	# Only show bark if not in another scene
	if get_tree().get_nodes_in_group("ScenePlayer").size() > 0 or has_node("TutorialScenePlayer"):
		return
		
	var h = int(Variables.get_variable("hunger", 100))
	var e = int(Variables.get_variable("energy", 100))
	var is_night = Variables.get_variable("current_time", 0) == 3
	
	var bark_text = ""
	var bark_expr = "neutral"
	
	var r = randf()
	if h < 30 and r < 0.6:
		bark_text = "Живот крутит... Надо бы перекусить в пиццерии."
		bark_expr = "sad"
	elif e < 30 and r < 0.6:
		bark_text = "Как же я устал... Сколы скоро отвалятся от недосыпа."
		bark_expr = "tired"
	elif is_night and r < 0.5:
		bark_text = "Варшава ночью красивая, но всё закрыто. Пора домой."
		bark_expr = "thinking"
	else:
		var generic = [
			{"t": "Хороший день для заработка. Нужно 500 злотых.", "e": "danila_determined_fabric"},
			{"t": "Интересно, как там пацаны в детдоме?", "e": "sad"},
			{"t": "Надо быть осторожнее, тут не все дружелюбные.", "e": "serious"},
			{"t": "Воздух другой... Не такой, как дома.", "e": "neutral"},
			{"t": "Иногда кажется, что за мной следят...", "e": "worried"}
		]
		var choice = generic[randi() % generic.size()]
		bark_text = choice.t
		bark_expr = choice.e
	
	_show_map_bark(bark_text, bark_expr)

func _show_map_bark(text: String, expr: String) -> void:
	# Avoid overlapping barks
	if has_node("AmbientBark"):
		get_node("AmbientBark").queue_free()
		
	var canvas = CanvasLayer.new()
	canvas.name = "AmbientBark"
	canvas.layer = 90
	add_child(canvas)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hbox.position = Vector2(-550, -250) # Bottom right corner slightly offset
	canvas.add_child(hbox)
	
	# Bubble
	var bubble = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.95, 0.95)
	style.border_width_left = 3; style.border_width_top = 3; style.border_width_right = 3; style.border_width_bottom = 3
	style.border_color = Color(0.1, 0.1, 0.1, 1)
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12; style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.content_margin_left = 15; style.content_margin_right = 15; style.content_margin_top = 10; style.content_margin_bottom = 10
	bubble.add_theme_stylebox_override("panel", style)
	bubble.size_flags_vertical = Control.SIZE_SHRINK_END
	
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(200, 0)
	bubble.add_child(lbl)
	hbox.add_child(bubble)
	
	# Portrait
	var portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(160, 160)
	
	var expr_paths = {
		"neutral": "res://Characters/Danila/danila_neutral.png",
		"sad": "res://Characters/Danila/danila_sad.png",
		"tired": "res://Characters/Danila/danila_tired_but_happy_factory.png",
		"thinking": "res://Characters/Danila/danila_thinking.png",
		"serious": "res://Characters/Danila/danila_serious.png",
		"worried": "res://Characters/Danila/danila_worried.png",
		"danila_determined_fabric": "res://Characters/Danila/danila_determined_fabric.png"
	}
	var tex_path = expr_paths.get(expr, expr_paths["neutral"])
	if ResourceLoader.exists(tex_path):
		portrait.texture = load(tex_path)
	hbox.add_child(portrait)
	
	# Animate bounce/fade
	hbox.modulate.a = 0.0
	hbox.position.y += 20
	var tw = create_tween()
	tw.tween_property(hbox, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(hbox, "position:y", hbox.position.y - 20, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	tw.tween_interval(4.0)
	
	tw.tween_property(hbox, "modulate:a", 0.0, 0.3)
	tw.tween_callback(canvas.queue_free)
