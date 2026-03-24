extends Control

@export var location_id: String = ""

signal node_clicked(scene_path)
signal node_hovered(title, desc, icon, pos, chibi, chibi_path)
signal node_unhovered()

var data: Dictionary
var chibi_path: String
var _setup_done := false

func _ready() -> void:
	var btn = find_child("Button", true, false)
	if btn:
		btn.pressed.connect(_on_button_pressed)
		btn.mouse_entered.connect(_on_button_mouse_entered)
		btn.mouse_exited.connect(_on_button_mouse_exited)
	# Если setup() был вызван до _ready(), применяем данные сейчас
	if _setup_done:
		_apply_data()

func setup(node_data: Dictionary, p_chibi_path: String) -> void:
	data = node_data
	chibi_path = p_chibi_path
	_setup_done = true
	# Если нода уже в дереве — применяем сразу
	if is_inside_tree():
		_apply_data()

func _apply_data() -> void:
	var name_label = find_child("NameLabel", true, false)
	var portrait_rect = find_child("Portrait", true, false)
	
	if name_label:
		name_label.text = data.get("name", "???")
	
	if portrait_rect and ResourceLoader.exists(chibi_path):
		portrait_rect.texture = load(chibi_path)

func _on_button_pressed() -> void:
	node_clicked.emit(data.get("scene", ""))

func _on_button_mouse_entered() -> void:
	var title = data.get("name", "")
	var desc = data.get("description", "")
	var icon = data.get("icon", "❗️")
	var chibi = data.get("chibi", "")
	node_hovered.emit(title, desc, icon, global_position, chibi, chibi_path)

func _on_button_mouse_exited() -> void:
	node_unhovered.emit()
