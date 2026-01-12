extends Control

signal back_requested


@onready var character_list = %CharacterList
@onready var detail_content = %DetailContent
@onready var detail_tex = %DetailTexture
@onready var detail_name = %DetailName
@onready var detail_desc = %DetailDesc
@onready var empty_label = %EmptyLabel

# References to new UI elements
@onready var bio_label = %BioLabel
@onready var rel_label = %RelationshipLabel
@onready var gallery_grid = %GalleryGrid

func _ready():
	_update_list()
	$BackButton.pressed.connect(_on_back_pressed)
	
	# Initial state
	detail_content.visible = false
	empty_label.visible = true
	empty_label.modulate.a = 0.5

func _update_list():
	# Clear List
	for child in character_list.get_children():
		child.queue_free()
	
	# Populate List
	for card_id in GameGlobal.CARD_DATABASE:
		var default_data = {"name": "?", "texture_path": "", "unlock_type": "event", "description": "", "bio": "", "relationships": "", "gallery": []}
		var data = GameGlobal.CARD_DATABASE[card_id].duplicate()
		
		# Merge defaults
		for key in default_data:
			if not data.has(key): data[key] = default_data[key]
		
		var is_unlocked = GameGlobal.is_card_unlocked(card_id)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if is_unlocked:
			btn.text = "   " + tr(data["name"])
			btn.pressed.connect(_on_character_selected.bind(card_id))
		else:
			btn.text = "   ???"
			btn.disabled = true
			
		character_list.add_child(btn)

func _on_character_selected(card_id):
	var data = GameGlobal.CARD_DATABASE[card_id]
	
	# 1. Update Content
	detail_tex.texture = load(data["texture_path"])
	detail_name.text = tr(data["name"])
	detail_desc.text = tr(data.get("description", "Нет описания."))
	
	bio_label.text = data.get("bio", "Информация отсутствует.")
	rel_label.text = data.get("relationships", "Нет данных о взаимодействии.")
	
	# 2. Update Gallery
	for child in gallery_grid.get_children():
		child.queue_free()
		
	var gallery = data.get("gallery", [])
	if gallery.is_empty() and data["texture_path"] != "":
		gallery = [data["texture_path"]]
	
	for img_path in gallery:
		var tex = load(img_path)
		if tex:
			var btn = TextureButton.new()
			btn.texture_normal = tex
			btn.ignore_texture_size = true
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			btn.custom_minimum_size = Vector2(80, 80)
			# Effect on click
			btn.pressed.connect(func(): 
				detail_tex.texture = tex
				_animate_image_change()
			)
			gallery_grid.add_child(btn)
	
	# 3. Animate Entry
	empty_label.visible = false
	detail_content.visible = true
	
	# Simple slide + fade animation
	detail_content.modulate.a = 0.0
	detail_content.position.x = 20 # Offset slightly
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(detail_content, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(detail_content, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _animate_image_change():
	# Small pop effect when changing image from gallery
	detail_tex.scale = Vector2(0.95, 0.95)
	var tween = create_tween()
	tween.tween_property(detail_tex, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_back_pressed():
	back_requested.emit()
	queue_free()
