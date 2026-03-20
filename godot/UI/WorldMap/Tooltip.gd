extends Control

@onready var title_label: Label = find_child("Title", true, false)
@onready var desc_label: Label = find_child("Desc", true, false)
@onready var portrait_rect: TextureRect = find_child("Portrait", true, false)

func show_info(p_title: String, p_desc: String, chibi_id: String, chibi_path: String) -> void:
	if title_label: title_label.text = p_title
	
	if desc_label:
		desc_label.text = p_desc if p_desc != "" else "Нет задач."
		
	if portrait_rect:
		if chibi_id != "" and chibi_path != "" and ResourceLoader.exists(chibi_path):
			portrait_rect.texture = load(chibi_path)
			portrait_rect.get_parent().visible = true
		else:
			portrait_rect.get_parent().visible = false

	show()

func hide_info() -> void:
	hide()
