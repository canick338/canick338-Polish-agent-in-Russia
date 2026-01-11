@tool
extends Control

@onready var file_tree: Tree = $HSplitContainer/FilePanel/FileTree
@onready var graph_edit: GraphEdit = $HSplitContainer/GraphPanel/GraphEdit
@onready var refresh_btn: Button = $HSplitContainer/FilePanel/RefreshButton
@onready var save_btn: Button = $HSplitContainer/GraphPanel/Toolbar/SaveButton
@onready var add_node_btn: MenuButton = $HSplitContainer/GraphPanel/Toolbar/AddNodeButton

var current_file_path: String = ""
var save_popup: AcceptDialog

func _ready():
	if not refresh_btn or not file_tree:
		return
		
	# Create popup for save feedback
	save_popup = AcceptDialog.new()
	add_child(save_popup)
	save_popup.title = "Dialogue Editor"
		
	refresh_btn.pressed.connect(_refresh_file_list)
	file_tree.item_selected.connect(_on_file_selected)
	save_btn.pressed.connect(_save_current_file)
	add_node_btn.get_popup().id_pressed.connect(_on_add_node_pressed)
	
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
	
	var vbox = VBoxContainer.new()
	node.add_child(vbox)
	
	var text_edit = TextEdit.new()
	text_edit.name = "Content"
	text_edit.custom_minimum_size = Vector2(400, 300)
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	var raw_text = ""
	for item in items:
		var char_name = item.get("character", "")
		var line = item.get("text", "")
		if char_name != "":
			raw_text += char_name + ": " + line + "\n\n"
		else:
			raw_text += line + "\n\n"
	
	text_edit.text = raw_text.strip_edges()
	vbox.add_child(text_edit)
	
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
					var label = Label.new()
					label.text = "Image Path:"
					vbox.add_child(label)
					
					var path_edit = LineEdit.new()
					path_edit.name = "Arg0"
					path_edit.text = args[0] if args.size() > 0 else ""
					vbox.add_child(path_edit)
					
				"minigame":
					node.title = "Start Minigame"
					node.set_meta("command_type", "minigame")
					var label = Label.new()
					label.text = "Game Name:"
					vbox.add_child(label)
					
					var game_edit = LineEdit.new()
					game_edit.name = "Arg0"
					game_edit.text = args[0] if args.size() > 0 else ""
					vbox.add_child(game_edit)
					
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
		
		# CASE 1: Dialogue Block (Regenerate)
		if meta_type == "dialogue_block":
			var content_node = node.find_child("Content", true, false)
			if content_node:
				var text = content_node.text
				var lines = text.split("\n")
				for line in lines:
					line = line.strip_edges()
					if line == "": continue
					
					var parts = line.split(":", true, 1)
					var char_name = ""
					var dialogue_text = ""
					
					if parts.size() > 1:
						char_name = parts[0].strip_edges()
						dialogue_text = parts[1].strip_edges()
					else:
						dialogue_text = parts[0].strip_edges()
						
					final_json_array.append({
						"type": "dialogue",
						"character": char_name,
						"text": dialogue_text
					})

		# CASE 2: Editable Command (Regenerate)
		elif meta_type == "command":
			var cmd_type = node.get_meta("command_type", "")
			# Only reconstruct if we support editing perfectly
			if cmd_type in ["background", "minigame", "set", "jump", "wait"]:
				var args = []
				var arg0 = node.find_child("Arg0", true, false)
				var arg1 = node.find_child("Arg1", true, false)
				if arg0: args.append(arg0.text)
				if arg1: args.append(arg1.text)
				
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
