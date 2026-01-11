@tool
extends Control

@onready var file_tree: Tree = $HSplitContainer/FilePanel/FileTree
@onready var graph_edit: GraphEdit = $HSplitContainer/GraphPanel/GraphEdit
@onready var refresh_btn: Button = $HSplitContainer/FilePanel/RefreshButton
@onready var save_btn: Button = $HSplitContainer/GraphPanel/Toolbar/SaveButton
@onready var add_node_btn: MenuButton = $HSplitContainer/GraphPanel/Toolbar/AddNodeButton
# We need to add the Export Button dynamically or assume it exists. 
# Since I can't edit the Tscn easily here without coordinate guessing, I'll add it via code to the Toolbar HBox.
var export_csv_btn: Button

var current_file_path: String = ""
var save_popup: AcceptDialog
var file_dialog: EditorFileDialog

# Cache for resources
var _character_ids: Array = []
var _background_ids: Array = []

func _ready():
	if not refresh_btn or not file_tree:
		return
		
	# Create popup for save feedback
	save_popup = AcceptDialog.new()
	add_child(save_popup)
	save_popup.title = "Dialogue Editor"
	
	# Create File Dialog for picking assets
	file_dialog = EditorFileDialog.new()
	add_child(file_dialog)
	
	# Scan resources initially
	_scan_resources()
		
	refresh_btn.pressed.connect(_refresh_file_list)
	# Also refresh resources when refreshing files
	refresh_btn.pressed.connect(_scan_resources)
	
	file_tree.item_selected.connect(_on_file_selected)
	file_tree.item_selected.connect(_on_file_selected)
	save_btn.pressed.connect(_save_current_file)
	add_node_btn.get_popup().id_pressed.connect(_on_add_node_pressed)
	
	# Create Export CSV Button programmatically
	export_csv_btn = Button.new()
	export_csv_btn.text = "Export Translations (CSV)"
	# Add to the same container as save_btn (Toolbar)
	save_btn.get_parent().add_child(export_csv_btn)
	export_csv_btn.pressed.connect(_export_translations_to_csv)
	
	# Setup Add Node Menu
	var popup = add_node_btn.get_popup()
	popup.clear()
	popup.add_item("Dialogue Block", 0)
	popup.add_separator("Commands")
	popup.add_item("Background Change", 10)
	popup.add_item("Start Minigame", 11)
	popup.add_item("Set Variable", 12)
	popup.add_item("Jump / Loop", 13)
	popup.add_item("Wait", 14)
	
	# GraphEdit signals
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	
	_refresh_file_list()

func _scan_resources():
	_character_ids.clear()
	_background_ids.clear()
	
	# Scan Characters
	var char_dir = DirAccess.open("res://Characters")
	if char_dir:
		char_dir.list_dir_begin()
		var file = char_dir.get_next()
		while file != "":
			if (file.ends_with(".tres") or file.ends_with(".res")) and not char_dir.current_is_dir():
				# Assuming ID is basename for now, or we could load resource. 
				# Loading is safer but slower. Let's use basename which matches ID convention usually.
				var id = file.get_basename()
				_character_ids.append(id)
			file = char_dir.get_next()
	_character_ids.sort()
	
	# Scan Backgrounds
	var bg_dir = DirAccess.open("res://Backgrounds")
	if bg_dir:
		bg_dir.list_dir_begin()
		var file = bg_dir.get_next()
		while file != "":
			if (file.ends_with(".tres") or file.ends_with(".res")) and not bg_dir.current_is_dir():
				var id = file.get_basename()
				_background_ids.append(id)
			file = bg_dir.get_next()
	_background_ids.sort()
	
	print("Scanned Resources: ", _character_ids.size(), " Characters, ", _background_ids.size(), " Backgrounds.")

func _refresh_file_list():
	file_tree.clear()
	var root = file_tree.create_item()
	var dir = DirAccess.open("res://Story")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var item = file_tree.create_item(root)
				item.set_text(0, file_name)
				item.set_metadata(0, "res://Story/" + file_name)
			file_name = dir.get_next()

# --- UI Helper Components ---
func _create_dropdown_property(label_text: String, options: Array, current_val: String, node_name: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	hbox.add_child(label)
	
	var opt = OptionButton.new()
	opt.name = node_name
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add empty/custom option
	opt.add_item("[ Custom / None ]", 0)
	var selected_idx = 0
	
	for i in range(options.size()):
		opt.add_item(options[i], i + 1)
		if options[i] == current_val:
			selected_idx = i + 1
			
	opt.selected = selected_idx
	hbox.add_child(opt)
	return hbox

func _create_file_picker_property(label_text: String, current_path: String, mode: EditorFileDialog.FileMode, filters: PackedStringArray, node_name: String) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	vbox.add_child(label)
	
	var hbox = HBoxContainer.new()
	var line_edit = LineEdit.new()
	line_edit.name = node_name
	line_edit.text = current_path
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(line_edit)
	
	var btn = Button.new()
	btn.text = "..."
	btn.pressed.connect(func():
		file_dialog.file_mode = mode
		file_dialog.filters = filters
		file_dialog.current_path = line_edit.text
		
		# Disconnect old signals to avoid multiple connections if reused (though we create new btn here)
		if file_dialog.file_selected.is_connected(_on_file_picked):
			file_dialog.file_selected.disconnect(_on_file_picked)
			
		file_dialog.file_selected.connect(_on_file_picked.bind(line_edit))
		file_dialog.popup_centered_ratio(0.6)
	)
	hbox.add_child(btn)
	
	vbox.add_child(hbox)
	return vbox

func _on_file_picked(path: String, target_line_edit: LineEdit):
	target_line_edit.text = path

func _on_file_selected():
	var item = file_tree.get_selected()
	if item:
		var path = item.get_metadata(0)
		_load_json_file(path)

func _load_json_file(path: String):
	print("Loading file: ", path)
	current_file_path = path
	graph_edit.clear_connections()
	# Clear existing nodes
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.queue_free()
			
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
		
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		if json.data is Array:
			_build_graph(json.data)
			print("File loaded successfully. Nodes count: ", json.data.size())
		else:
			print("JSON root is not array")

func _build_graph(data: Array):
	var previous_node_name = ""
	var offset_y = 0
	
	var dialogue_buffer = []
	
	for i in range(data.size()):
		var item = data[i]
		var type = item.get("type", "unknown")
		
		# Accumulate dialogue
		if type == "dialogue":
			dialogue_buffer.append(item)
			continue
			
		# Flush buffer
		if not dialogue_buffer.is_empty():
			var block_node = _create_dialogue_block_node(dialogue_buffer.duplicate())
			graph_edit.add_child(block_node)
			block_node.position_offset = Vector2(100, offset_y)
			block_node.name = "Node_" + str(graph_edit.get_child_count())
			
			if previous_node_name != "":
				graph_edit.connect_node(previous_node_name, 0, block_node.name, 0)
			
			previous_node_name = block_node.name
			offset_y += 300
			dialogue_buffer.clear()
			
		# Process non-dialogue
		var node = _create_graph_node(item)
		if node:
			graph_edit.add_child(node)
			node.position_offset = Vector2(100, offset_y)
			node.name = "Node_" + str(graph_edit.get_child_count())
			
			if previous_node_name != "":
				graph_edit.connect_node(previous_node_name, 0, node.name, 0)
			
			previous_node_name = node.name
			offset_y += 200
	
	# Final flush
	if not dialogue_buffer.is_empty():
		var block_node = _create_dialogue_block_node(dialogue_buffer)
		graph_edit.add_child(block_node)
		block_node.position_offset = Vector2(100, offset_y)
		block_node.name = "Node_" + str(graph_edit.get_child_count())
		if previous_node_name != "":
			graph_edit.connect_node(previous_node_name, 0, block_node.name, 0)

func _create_dialogue_block_node(items: Array) -> GraphNode:
	var node = GraphNode.new()
	node.title = "Dialogue Scene"
	node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	node.set_meta("node_type", "dialogue_block")
	node.resizable = true
	
	var vbox = VBoxContainer.new()
	node.add_child(vbox)
	
	# Header logic
	var header_hbox = HBoxContainer.new()
	var add_line_btn = Button.new()
	add_line_btn.text = "+ Add Line"
	header_hbox.add_child(add_line_btn)
	vbox.add_child(header_hbox)
	
	# Use VBoxContainer for rows
	var lines_container = VBoxContainer.new()
	lines_container.name = "Lines"
	vbox.add_child(lines_container)
	
	# Function to add a single dialogue row
	var add_row_func = func(char_id: String, text: String):
		var row = HBoxContainer.new()
		row.set_meta("is_dialogue_row", true)
		
		# DELETE BUTTON
		var del_btn = Button.new()
		del_btn.text = "X"
		del_btn.modulate = Color(1, 0.6, 0.6)
		del_btn.pressed.connect(func(): row.queue_free())
		row.add_child(del_btn)
		
		# CHARACTER DROPDOWN
		var char_opt = OptionButton.new()
		char_opt.name = "Char"
		char_opt.custom_minimum_size.x = 100
		char_opt.add_item("...", 0)
		var sel_idx = 0
		for i in range(_character_ids.size()):
			char_opt.add_item(_character_ids[i], i + 1)
			if _character_ids[i] == char_id:
				sel_idx = i + 1
		
		if sel_idx == 0 and char_id != "":
			# Custom character
			char_opt.add_item(char_id, 999)
			char_opt.selected = char_opt.item_count - 1
			char_opt.set_meta("custom_char", char_id)
		else:
			char_opt.selected = sel_idx
			
		row.add_child(char_opt)
		
		# TEXT EDIT
		var text_edit = LineEdit.new()
		text_edit.name = "Text"
		text_edit.text = text
		text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_edit.custom_minimum_size.x = 200
		row.add_child(text_edit)
		
		lines_container.add_child(row)
		
	# Populate existing
	for item in items:
		add_row_func.call(item.get("character", ""), item.get("text", ""))
		
	# Connect Add Button
	add_line_btn.pressed.connect(func(): add_row_func.call("", ""))
	
	if node.has_signal("close_request"):
		node.close_request.connect(func(): _delete_node(node))
		
	return node

func _create_graph_node(item: Dictionary) -> GraphNode:
	var node = GraphNode.new()
	var type = item.get("type", "unknown")
	node.title = type.capitalize()
	
	# Default to generic/passthrough for unknown types (Choice, If, etc)
	node.set_meta("node_type", "generic")
	node.set_meta("original_data", item)
	
	if type == "command":
		node.set_meta("node_type", "command")
		node.set_meta("command_type", item.get("name", "unknown"))
	
	if node.has_signal("close_request"):
		node.close_request.connect(func(): _delete_node(node))
	
	node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	
	var vbox = VBoxContainer.new()
	node.add_child(vbox)
	
	match type:
		"command":
			var cmd_name = item.get("name", "")
			var args = item.get("args", [])
			
			match cmd_name:
				"background":
					node.title = "Change Background"
					node.set_meta("command_type", "background")
					
					# Use Dropdown for Background IDs instead of manual path
					var dropdown = _create_dropdown_property("Background ID:", _background_ids, args[0] if args.size() > 0 else "", "Arg0")
					vbox.add_child(dropdown)
					
					# Optional Transition
					var trans_edit = LineEdit.new()
					trans_edit.name = "Arg1"
					trans_edit.placeholder_text = "Transition (optional)"
					trans_edit.text = args[1] if args.size() > 1 else ""
					vbox.add_child(trans_edit)
					
				"cinematic":
					node.title = "Cinematic Event"
					node.set_meta("command_type", "cinematic")
					
					# Image Path Picker
					var picker = _create_file_picker_property("Image Path:", args[0] if args.size() > 0 else "", EditorFileDialog.FILE_MODE_OPEN_FILE, ["*.png", "*.jpg", "*.jpeg", "*.webp"], "Arg0")
					vbox.add_child(picker)
					
					# Effect Dropdown
					var effects = ["zoom_in", "pan_right", "breathing", "shake", "handheld", "heartbeat", "wiggle", "bounce", "impact", "flash_white", "flash_red", "sepia", "danger"]
					var effect_dd = _create_dropdown_property("Effect:", effects, args[1] if args.size() > 1 else "", "Arg1")
					vbox.add_child(effect_dd)
					
					# Duration
					var dur_label = Label.new()
					dur_label.text = "Duration/Intensity:"
					vbox.add_child(dur_label)
					var dur_edit = LineEdit.new()
					dur_edit.name = "Arg2"
					dur_edit.text = str(args[2]) if args.size() > 2 else "0"
					vbox.add_child(dur_edit)

				"minigame":
					node.title = "Start Minigame"
					node.set_meta("command_type", "minigame")
					
					# Minigames Dropdown (Hardcoded for now + Scanned later?)
					var games = ["factory_jam", "card_game"]
					var game_dd = _create_dropdown_property("Game:", games, args[0] if args.size() > 0 else "", "Arg0")
					vbox.add_child(game_dd)
					
				"set":
					node.title = "Set Variable"
					node.set_meta("command_type", "set")
					
					var var_edit = LineEdit.new()
					var_edit.name = "Arg0"
					var_edit.placeholder_text = "Variable"
					var_edit.text = args[0] if args.size() > 0 else ""
					vbox.add_child(var_edit)
					
					var val_edit = LineEdit.new()
					val_edit.name = "Arg1"
					val_edit.placeholder_text = "Value"
					val_edit.text = str(args[1]) if args.size() > 1 else ""
					vbox.add_child(val_edit)
					
				"jump":
					node.title = "Jump To"
					node.set_meta("command_type", "jump")
					
					var target_edit = LineEdit.new()
					target_edit.name = "Arg0"
					target_edit.placeholder_text = "Label ID"
					target_edit.text = args[0] if args.size() > 0 else ""
					vbox.add_child(target_edit)
					
				"wait":
					node.title = "Wait"
					node.set_meta("command_type", "wait")
					var label = Label.new()
					label.text = "Seconds:"
					vbox.add_child(label)
					var time_edit = LineEdit.new()
					time_edit.name = "Arg0"
					time_edit.text = args[0] if args.size() > 0 else "1.0"
					vbox.add_child(time_edit)

				_:
					node.title = cmd_name.capitalize()
					var name_edit = LineEdit.new()
					name_edit.name = "GenericCmd"
					name_edit.text = cmd_name + " " + " ".join(args)
					name_edit.editable = false # Prevent editing generic cmds to avoid breaking args
					vbox.add_child(name_edit)
		"choice":
			node.title = "Choice Branch (Read-Only)"
			var label = Label.new()
			# Show options count for visual confirmation
			var opts = item.get("options", [])
			label.text = "Options: " + str(opts.size())
			vbox.add_child(label)
			
		"if":
			node.title = "Condition (Read-Only)"
			var label = Label.new()
			label.text = "Check: " + str(item.get("condition", "???"))
			vbox.add_child(label)
					
	return node

func _delete_node(node):
	graph_edit.disconnect_node(node.name, 0, "", 0)
	node.queue_free()

func _on_connection_request(from_node, from_port, to_node, to_port):
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node, from_port, to_node, to_port):
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _on_add_node_pressed(id):
	var template = {}
	match id:
		0: template = {"type": "dialogue", "text": "New Text", "character": ""}
		10: template = {"type": "command", "name": "background", "args": [""]}
		11: template = {"type": "command", "name": "minigame", "args": ["factory_jam"]}
		12: template = {"type": "command", "name": "set", "args": ["variable_name", "value"]}
		13: template = {"type": "command", "name": "jump", "args": ["target_label"]}
		14: template = {"type": "command", "name": "wait", "args": ["1.0"]}
	
	if id == 0:
		var node = _create_dialogue_block_node([template])
		graph_edit.add_child(node)
		node.position_offset = graph_edit.scroll_offset + Vector2(200, 200)
		node.name = "Node_" + str(graph_edit.get_child_count())
	else:
		var node = _create_graph_node(template)
		graph_edit.add_child(node)
		node.position_offset = graph_edit.scroll_offset + Vector2(200, 200)
		node.name = "Node_" + str(graph_edit.get_child_count())

func _save_current_file():
	print("DEBUG: Save button pressed. Path: ", current_file_path)
	if current_file_path == "":
		if save_popup:
			save_popup.dialog_text = "No file selected! Please select a file from list."
			save_popup.popup_centered()
		return
		
	var nodes_list = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			nodes_list.append(child)
			
	nodes_list.sort_custom(func(a, b): return a.position_offset.y < b.position_offset.y)
	
	var final_json_array = []
	
	for node in nodes_list:
		var meta_type = node.get_meta("node_type", "generic")
		
		# CASE 1: Dialogue Block (Regenerate from Rows)
		if meta_type == "dialogue_block":
			# Find the "Lines" container
			var lines_container = node.find_child("Lines", true, false)
			if lines_container:
				for row in lines_container.get_children():
					if row.has_meta("is_dialogue_row"):
						var char_opt = row.find_child("Char", true, false)
						var text_edit = row.find_child("Text", true, false)
						
						var char_id = ""
						if char_opt:
							if char_opt.selected > 0:
								if char_opt.has_meta("custom_char") and char_opt.selected == char_opt.item_count - 1:
									char_id = char_opt.get_meta("custom_char")
								else:
									char_id = char_opt.get_item_text(char_opt.selected)
						
						var text_line = ""
						if text_edit:
							text_line = text_edit.text.strip_edges()
							
						if text_line != "":
							final_json_array.append({
								"type": "dialogue",
								"character": char_id,
								"text": text_line,
								"translation_key": _generate_translation_key(char_id, text_line)
							})

		# CASE 2: Editable Command (Regenerate)
		elif meta_type == "command":
			var cmd_type = node.get_meta("command_type", "")
			# Only reconstruct if we support editing perfectly
			if cmd_type in ["background", "minigame", "set", "jump", "wait", "cinematic"]:
				var args = []
				
				# Helper to extract value from any control type (LineEdit or OptionButton)
				var get_val = func(arg_name):
					var control = node.find_child(arg_name, true, false)
					if control:
						if control is LineEdit:
							return control.text
						elif control is OptionButton:
							if control.selected > 0:
								return control.get_item_text(control.selected)
							# Return empty string or handle custom input? 
							# For now dropdowns return text at index
							return ""
					return null

				var arg0 = get_val.call("Arg0")
				var arg1 = get_val.call("Arg1")
				var arg2 = get_val.call("Arg2")
				
				if arg0 != null: args.append(arg0)
				if arg1 != null: args.append(arg1)
				if arg2 != null: args.append(arg2)
				
				final_json_array.append({
					"type": "command",
					"name": cmd_type,
					"args": args
				})
			else:
				# Unknown command - Passthrough
				if node.has_meta("original_data"):
					final_json_array.append(node.get_meta("original_data"))

		# CASE 3: Generic / Choice / If (Passthrough)
		else:
			if node.has_meta("original_data"):
				final_json_array.append(node.get_meta("original_data"))
			else:
				print("WARNING: Skipping generic node without original data")
			
	var file = FileAccess.open(current_file_path, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(final_json_array, "\t")
		file.store_string(json_str)
		file.close()
		print("Saved JSON to: ", current_file_path, " | Items: ", final_json_array.size())
		if save_popup:
			save_popup.dialog_text = "File saved successfully!\nItems: " + str(final_json_array.size())
			save_popup.popup_centered()
	else:
		push_error("Failed to save file: " + current_file_path)
		if save_popup:
			save_popup.dialog_text = "FAILED to save file!"
			save_popup.popup_centered()

func _generate_translation_key(char_name: String, text: String) -> String:
	# Generate a unique key based on content.
	# Format: FILE_PREFIX_MD5
	# We use current filename as prefix to avoid collisions between files with same text.
	var prefix = current_file_path.get_file().get_basename().to_upper()
	var content = char_name + ":" + text
	var hash_str = content.md5_text().substr(0, 8) # 8 chars is enough for short collisions usually
	return prefix + "_" + hash_str

func _export_translations_to_csv():
	var dir = DirAccess.open("res://Story")
	if not dir: return
	
	var all_keys = {} # key -> text
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Scan all JSONs
		if not dir.current_is_dir() and file_name.ends_with(".json") and file_name != "translations.csv":
			var path = "res://Story/" + file_name
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var json = JSON.new()
				if json.parse(f.get_as_text()) == OK and json.data is Array:
					for item in json.data:
						# Ensure item is dictionary
						if item is Dictionary and "translation_key" in item and "text" in item:
							all_keys[item.translation_key] = item.text
		file_name = dir.get_next()
	
	# Write to CSV
	# Format: keys, ru, en
	# Write to CSV
	# Format: keys, ru, en, pl
	var csv_path = "res://translations.csv"
	
	var preserved_en = {} # key -> text
	var preserved_pl = {} # key -> text
	
	if FileAccess.file_exists(csv_path):
		var csv_file = FileAccess.open(csv_path, FileAccess.READ)
		if csv_file:
			while not csv_file.eof_reached():
				# Use standard comma for Godot compatibility
				var line = csv_file.get_csv_line()
				if line.size() >= 1:
					var k = line[0]
					if k == "keys": continue
					
					if line.size() >= 3:
						preserved_en[k] = line[2]
					if line.size() >= 4:
						preserved_pl[k] = line[3]
		else:
			print("Warning: Could not read existing CSV (maybe locked by Excel?): ", csv_path)
	
	var out = FileAccess.open(csv_path, FileAccess.WRITE)
	if out:
		# Write UTF-8 BOM for Excel compatibility
		out.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))
		
		# Now support RU, EN, PL (Use semicolon delimiter)
		out.store_csv_line(["keys", "ru", "en", "pl"])
		
		for key in all_keys:
			var ru = all_keys[key]
			var en = preserved_en.get(key, "")
			var pl = preserved_pl.get(key, "")
			
			out.store_csv_line([key, ru, en, pl])
		out.close()
		
		if save_popup:
			save_popup.dialog_text = "Key Export Complete!\nkeys: " + str(all_keys.size())
			save_popup.popup_centered()
