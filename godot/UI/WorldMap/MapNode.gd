extends Control

@export var location_id: String = ""

signal node_clicked(scene_path)
signal node_hovered(title, desc, icon, pos, chibi, chibi_path)
signal node_unhovered()

var data: Dictionary
var chibi_path: String

# Обязательно добавь эти узлы в своей сцене MapNode.tscn:
# - Label с именем "NameLabel"
# - TextureRect с именем "Portrait" (где будет чибик)
# - Button с именем "Button" (чтобы можно было кликать и наводить)

@onready var name_label: Label = find_child("NameLabel", true, false)
@onready var portrait_rect: TextureRect = find_child("Portrait", true, false)
@onready var button: Button = find_child("Button", true, false)

func _ready() -> void:
	if button:
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(_on_button_mouse_entered)
		button.mouse_exited.connect(_on_button_mouse_exited)

func setup(node_data: Dictionary, p_chibi_path: String) -> void:
	data = node_data
	chibi_path = p_chibi_path
	
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
