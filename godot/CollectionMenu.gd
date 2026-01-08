extends Control

signal back_requested


@onready var character_list = %CharacterList
@onready var detail_content = %DetailContent
@onready var detail_tex = %DetailTexture
@onready var detail_name = %DetailName
@onready var detail_desc = %DetailDesc
@onready var empty_label = %EmptyLabel

func _ready():
	_update_list()
	$BackButton.pressed.connect(_on_back_pressed)

func _update_list():
	# Clear List
	for child in character_list.get_children():
		child.queue_free()
	
	# Populate List
	for card_id in GameGlobal.CARD_DATABASE:
		# Duplicate the data to avoid read-only issues
		var default_data = {"name": "?", "texture_path": "", "unlock_type": "event", "description": ""}
		var data = GameGlobal.CARD_DATABASE[card_id].duplicate()
		
		# Merge defaults for missing fields
		for key in default_data:
			if not data.has(key):
				data[key] = default_data[key]
		
		var is_unlocked = GameGlobal.is_card_unlocked(card_id)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if is_unlocked:
			btn.text = "   " + data["name"]
			btn.pressed.connect(_on_character_selected.bind(card_id))
		else:
			btn.text = "   ???"
			btn.disabled = true # Or allow clicking for "Locked" info
			
		character_list.add_child(btn)

func _on_character_selected(card_id):
	var data = GameGlobal.CARD_DATABASE[card_id]
	
	detail_tex.texture = load(data["texture_path"])
	detail_name.text = data["name"]
	detail_desc.text = data.get("description", "Нет описания.")
	
	detail_content.visible = true
	empty_label.visible = false

func _on_back_pressed():
	back_requested.emit()
	queue_free()
