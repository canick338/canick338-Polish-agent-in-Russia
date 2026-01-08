extends Control

# Mode: "save" or "load"
var mode = "load"

@onready var title_label = $Panel/TitleLabel
@onready var grid = $Panel/GridContainer
@onready var close_button = $Panel/CloseButton

# Slot button template (we'll just duplicate buttons in editor or code)
# For simplicity, we'll assume 6 buttons named Slot1...Slot6 in the scene

func _ready():
	_update_ui()
	
func set_mode(new_mode: String):
	mode = new_mode
	if is_node_ready():
		_update_ui()

func _update_ui():
	if mode == "save":
		title_label.text = "СОХРАНИТЬ ИГРУ"
	else:
		title_label.text = "ЗАГРУЗИТЬ ИГРУ"
		
	# Refresh slots
	for i in range(1, 7):
		var btn = grid.get_node_or_null("Slot" + str(i))
		if btn:
			# Clear existing children (for screenshots/labels)
			for child in btn.get_children():
				child.queue_free()
			
			var info = GameGlobal.get_slot_info(i)
			
			# Create HBoxContainer for layout
			var hbox = HBoxContainer.new()
			hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			hbox.offset_left = 5
			hbox.offset_top = 5
			hbox.offset_right = -5
			hbox.offset_bottom = -5
			btn.add_child(hbox)
			
			# Add screenshot thumbnail
			var screenshot_rect = TextureRect.new()
			screenshot_rect.custom_minimum_size = Vector2(160, 90)  # 16:9 aspect
			screenshot_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			screenshot_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			
			if not info["empty"]:
				# Try to load screenshot
				var screenshot_path = GameGlobal.get_screenshot_path(i)
				if FileAccess.file_exists(screenshot_path):
					var img = Image.load_from_file(screenshot_path)
					if img and img.get_size() != Vector2i.ZERO:
						var tex = ImageTexture.create_from_image(img)
						if tex:
							screenshot_rect.texture = tex
						else:
							# Fallback if texture creation fails
							screenshot_rect.modulate = Color(0.3, 0.3, 0.3)
					else:
						# Placeholder for corrupted/invalid screenshot
						screenshot_rect.modulate = Color(0.3, 0.3, 0.3)
				else:
					# Placeholder for no screenshot
					screenshot_rect.modulate = Color(0.3, 0.3, 0.3)
			else:
				# Empty slot placeholder
				screenshot_rect.modulate = Color(0.2, 0.2, 0.2)
			
			hbox.add_child(screenshot_rect)
			
			# Add spacer
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(10, 0)
			hbox.add_child(spacer)
			
			# Add text info
			var vbox = VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var slot_label = Label.new()
			slot_label.add_theme_font_size_override("font_size", 16)
			
			if info["empty"]:
				slot_label.text = "Пустой слот %d" % i
				btn.text = ""  # Clear button text since we're using custom layout
			else:
				var timestamp = info.get("timestamp", "???")
				var money = info.get("money", 0)
				slot_label.text = "Слот %d\n%s\nДеньги: %d₽" % [i, timestamp, money]
				btn.text = ""
			
			vbox.add_child(slot_label)
			hbox.add_child(vbox)
			
			# Disconnect old signals to avoid duplicates
			if btn.pressed.is_connected(_on_slot_pressed):
				btn.pressed.disconnect(_on_slot_pressed)
				
			btn.pressed.connect(_on_slot_pressed.bind(i))


func _on_slot_pressed(slot_id):
	if mode == "save":
		GameGlobal.save_game(slot_id)
		await get_tree().process_frame  # Wait for screenshot
		_update_ui() # Refresh to show new save
	else:
		if GameGlobal.load_game(slot_id):
			# Success - game state is now restored
			get_tree().paused = false  # Unpause if we were paused
			
			# Close this menu and any parent pause menu
			var parent = get_parent()
			if parent and parent.has_method("queue_free"):
				parent.queue_free()
			queue_free()


func _on_close_pressed():
	queue_free()
