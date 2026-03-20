extends Control

const MANIFEST_PATH = "res://Story/Manifests/main_story.json"
const PHONE_HUD_SCENE = preload("res://PhoneHUD.tscn")

var manifest_data: Dictionary = {}
var current_location_id: String = "warsaw_center"
var _tooltip_panel: PanelContainer
var _tooltip_label: Label
var _hovered_node_data: Dictionary = {}

@onready var map_background: TextureRect = $MapBackground
@onready var nodes_container: Control = $MapNodes
@onready var location_label: Label = %LocationLabel
@onready var time_label: Label = %TimeLabel
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
	_load_manifest()
	if phone_button: phone_button.pressed.connect(_on_phone_pressed)
	if get_node_or_null("%ToggleSidePanelButton"):
		%ToggleSidePanelButton.pressed.connect(_toggle_side_panel)
	
	_create_tooltip_ui()
	_refresh_map()
	_update_side_panel_locations()
	_update_time_hud()
	
	# Tutorial: first time on map
	if Variables.get_variable("map_tutorial_done") != 1:
		_run_map_tutorial()
	elif Variables.get_variable("prologue_act_3_done") == 1:
		# 20% chance of random street event each time player enters map
		if randi() % 5 == 0:
			_trigger_random_event()

func _run_map_tutorial() -> void:
	Variables.add_variable("map_tutorial_done", 1)
	# Launch a mini-dialogue as a scene
	var tutorial_path = "res://Story/00_Warsaw/00_map_tutorial.json"
	if FileAccess.file_exists(tutorial_path):
		# Small delay to let map render first
		await get_tree().create_timer(0.5).timeout
		scene_requested.emit(tutorial_path)

func _create_tooltip_ui() -> void:
	# Build tooltip panel programmatically (it lives in the UI layer)
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.name = "TooltipPanel"
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.visible = false
	_tooltip_panel.z_index = 100
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 1.0, 0.7)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_tooltip_panel.add_theme_stylebox_override("panel", style)
	
	_tooltip_label = Label.new()
	_tooltip_label.name = "TooltipLabel"
	_tooltip_label.add_theme_font_size_override("font_size", 18)
	_tooltip_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.custom_minimum_size = Vector2(250, 0)
	_tooltip_panel.add_child(_tooltip_label)
	
	add_child(_tooltip_panel)

func _update_time_hud() -> void:
	if not time_label: return
	var day = Variables.get_variable("current_day")
	if day == 0: day = 1
	var time_idx = Variables.get_variable("current_time")
	if time_idx < 0 or time_idx > 3: time_idx = 0
	
	var hud_text = "День %d — %s" % [day, TIME_NAMES[time_idx]]
	
	# Hunger / Energy bars
	var hunger = Variables.get_variable("hunger", -1)
	var energy = Variables.get_variable("energy", -1)
	if hunger >= 0:
		var hunger_icon = "🍖" if hunger > 30 else "💀"
		hud_text += "  %s%d" % [hunger_icon, hunger]
	if energy >= 0:
		var energy_icon = "⚡" if energy > 30 else "😴"
		hud_text += "  %s%d" % [energy_icon, energy]
	
	# Days left countdown
	var days_left = Variables.get_variable("days_left", -1)
	if days_left >= 1:
		hud_text += "  ⏰ %d дн." % days_left
	elif days_left == 0 and Variables.get_variable("warsaw_ticket_bought") != 1:
		hud_text = "⚠️ ВРЕМЯ ВЫШЛО! Миссия провалена."
	
	# Money display
	var money = Variables.get_variable("money", -1)
	if money >= 0 and Variables.get_variable("warsaw_prologue_stage") == 1:
		hud_text += "  💰 %d zł" % money
	
	time_label.text = hud_text
	
	# Tint time label color
	if time_idx >= 0 and time_idx <= 3:
		time_label.add_theme_color_override("font_color", TIME_COLORS[time_idx])

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
	for child in nodes_container.get_children():
		child.queue_free()
	
	# Map background color
	var fallback = map_background.get_node_or_null("MapColorFallback")
	if fallback:
		if current_location_id == "warsaw_center":
			fallback.color = Color(0.12, 0.14, 0.22)
		elif current_location_id == "oboyan_center":
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
				_create_map_node(node)

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
	# Container for icon + label
	var container = Control.new()
	container.name = "Node_" + data.get("id", "unknown")
	
	var node_name = data.get("name", "???")
	var node_desc = data.get("description", "")
	var node_icon = data.get("icon", "📍")
	
	# --- Icon circle ---
	var icon_size := Vector2(90, 90)
	
	# Background circle
	var circle_bg = ColorRect.new()
	circle_bg.size = icon_size
	circle_bg.color = Color(0.15, 0.2, 0.35, 0.9)
	circle_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(circle_bg)
	
	# Try to load real chibi texture
	var tex_path = _get_chibi_texture(data.get("chibi", ""))
	if ResourceLoader.exists(tex_path):
		var tex = TextureRect.new()
		tex.texture = load(tex_path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size = icon_size
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(tex)
		circle_bg.color = Color(0.1, 0.1, 0.15, 0.6)
	else:
		# Emoji fallback
		var emoji = Label.new()
		emoji.text = node_icon
		emoji.add_theme_font_size_override("font_size", 40)
		emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emoji.size = icon_size
		emoji.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(emoji)
	
	# --- Name label below icon ---
	var name_label = Label.new()
	name_label.text = node_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-30, icon_size.y + 4)
	name_label.size = Vector2(icon_size.x + 60, 25)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(name_label)
	
	# --- Clickable button overlay ---
	var btn = Button.new()
	btn.flat = true
	btn.size = icon_size
	btn.position = Vector2.ZERO
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Hover effects
	btn.mouse_entered.connect(func():
		# Glow effect
		circle_bg.color.a = 1.0
		container.modulate = Color(1.2, 1.2, 1.3)
		# Show tooltip
		_show_tooltip(node_name, node_desc, node_icon, container.global_position + Vector2(icon_size.x + 10, 0))
	)
	btn.mouse_exited.connect(func():
		circle_bg.color.a = 0.85
		container.modulate = Color(1.0, 1.0, 1.0)
		_hide_tooltip()
	)
	btn.pressed.connect(func():
		_hide_tooltip()
		scene_requested.emit(data.get("scene", ""))
	)
	container.add_child(btn)
	
	# Position
	var pos_data = data.get("position", {"x": 0, "y": 0})
	container.position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0)) - icon_size / 2
	
	# Bobbing animation
	var base_y = container.position.y
	var tw = create_tween().set_loops()
	tw.tween_property(container, "position:y", base_y - 8, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(container, "position:y", base_y, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Pulse for "quest critical" nodes
	if data.get("id", "") in ["hq", "home_finale", "streets", "academy"]:
		var pulse_tw = create_tween().set_loops()
		pulse_tw.tween_property(container, "modulate:a", 0.7, 0.8).set_trans(Tween.TRANS_SINE)
		pulse_tw.tween_property(container, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	
	nodes_container.add_child(container)

func _show_tooltip(title: String, desc: String, icon: String, pos: Vector2) -> void:
	if not _tooltip_panel or not _tooltip_label: return
	var text = "%s %s" % [icon, title]
	if desc != "":
		text += "\n%s" % desc
	_tooltip_label.text = text
	_tooltip_panel.position = pos
	_tooltip_panel.visible = true

func _hide_tooltip() -> void:
	if _tooltip_panel:
		_tooltip_panel.visible = false

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

func _trigger_random_event() -> void:
	var event_type = (randi() % 4) + 1  # 1 to 4
	Variables.add_variable("random_event_type", event_type)
	await get_tree().create_timer(0.8).timeout
	var event_path = "res://Story/00_Warsaw/random_event.json"
	if FileAccess.file_exists(event_path):
		scene_requested.emit(event_path)
