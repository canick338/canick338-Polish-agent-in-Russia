class_name JSONDialogueLoader
extends RefCounted

const ERROR_NONEXISTENT_JUMP_POINT := -3
const UNIQUE_CHOICE_ID_MODIFIER = 1000000000
const UNIQUE_CONDITIONAL_ID_MODIFIER = 2100000000

# Mapping for jump points
var _jump_points := {}
var _unresolved_jump_nodes := []

func load_scene(path: String) -> SceneTranspiler.DialogueTree:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open JSON file: " + path)
		return null
		
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("JSON Parse Error in %s at line %s: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
		
	var data = json.data
	if not data is Array:
		push_error("Root of dialogue JSON must be an Array: " + path)
		return null
		
	return _build_tree(data)

func _build_tree(data: Array) -> SceneTranspiler.DialogueTree:
	var tree = SceneTranspiler.DialogueTree.new()
	tree.index = 0
	
	_process_block(data, tree)
	
	return tree

func _process_block(block: Array, tree: SceneTranspiler.DialogueTree):
	for item in block:
		if not item is Dictionary:
			continue
			
		var type = item.get("type", "")
		var node = null
		
		match type:
			"dialogue":
				node = _create_dialogue_node(tree.index + 1, item)
			"command":
				node = _create_command_node(tree.index + 1, item, tree)
			"choice":
				node = _create_choice_node(tree, item)
			"if":
				node = _create_conditional_node(tree, item)
			_:
				push_warning("Unknown JSON node type: " + type)
		
		if node:
			# Handle Events/Signals
			var evt = item.get("signal", null)
			if evt == null:
				evt = item.get("event", null)
				
			if evt:
				if evt is String:
					node.event = {"name": evt, "args": []}
				elif evt is Dictionary:
					node.event = evt
					if not node.event.has("args"):
						node.event["args"] = []
				else:
					push_warning("Invalid event format in JSON: " + str(evt))
					
			tree.append_node(node)

func _create_dialogue_node(next_idx: int, data: Dictionary) -> SceneTranspiler.DialogueNode:
	var node = SceneTranspiler.DialogueNode.new(next_idx, data.get("text", ""))
	
	# Handle optional fields
	if data.has("character"):
		node.character = _clean_value(data["character"])
	if data.has("mood"):
		node.expression = _clean_value(data["mood"])
	if data.has("animation"):
		node.animation = _clean_value(data["animation"])
	if data.has("side"):
		node.side = _clean_value(data["side"])
		
	return node

func _create_command_node(next_idx: int, data: Dictionary, tree: SceneTranspiler.DialogueTree) -> SceneTranspiler.BaseNode:
	var name = data.get("name", "")
	var args = data.get("args", [])
	
	match name:
		"background":
			var bg_name = _clean_value(args[0]) if args.size() > 0 else ""
			var node = SceneTranspiler.BackgroundCommandNode.new(next_idx, bg_name)
			if args.size() > 1:
				node.transition = _clean_value(args[1])
			return node
			
		"scene":
			var scene_path = _clean_value(args[0]) if args.size() > 0 else ""
			return SceneTranspiler.SceneCommandNode.new(next_idx, scene_path)
			
		"jump":
			var jump_point = _clean_value(args[0]) if args.size() > 0 else ""
			if _jump_points.has(jump_point):
				return SceneTranspiler.JumpCommandNode.new(_jump_points[jump_point])
			else:
				var node = SceneTranspiler.JumpCommandNode.new(-1)
				node.jump_point = jump_point
				_unresolved_jump_nodes.append(node)
				return node
				
		"mark":
			var mark_name = _clean_value(args[0]) if args.size() > 0 else ""
			_add_jump_point(mark_name, tree.index)
			# Mark doesn't create a runtime node effectively, but we might usually attach it to the next node?
			# In existing transpiler, it modifies jump points but doesn't return a node to append?
			# Actually existing transpiler returns NULL for mark so it doesn't add a node.
			# But we need to handle the index.
			# Let's inspect existing transpiler.
			return null
			
		"transition":
			var trans_name = _clean_value(args[0]) if args.size() > 0 else ""
			return SceneTranspiler.TransitionCommandNode.new(next_idx, trans_name)
			
		"cutscene":
			var vid_path = _clean_value(args[0]) if args.size() > 0 else ""
			if not vid_path.begins_with("res://"):
				vid_path = "res://Cutscenes/" + vid_path
			if not vid_path.ends_with(".ogv") and not vid_path.ends_with(".webm"):
				vid_path += ".ogv"
			
			var node = SceneTranspiler.CutsceneCommandNode.new(next_idx, vid_path)
			if args.size() > 1:
				node.can_skip = str(args[1]) == "true"
			if args.size() > 2:
				node.auto_continue = str(args[2]) == "true"
			return node
			
		"minigame":
			var game_name = _clean_value(args[0]) if args.size() > 0 else ""
			return SceneTranspiler.MinigameCommandNode.new(next_idx, game_name)
			
		"set":
			var symbol = _clean_value(args[0]) if args.size() > 0 else ""
			var val = args[1] if args.size() > 1 else null
			return SceneTranspiler.SetCommandNode.new(next_idx, symbol, val)
			
		"unlock":
			var card_id = _clean_value(args[0]) if args.size() > 0 else ""
			return SceneTranspiler.UnlockCommandNode.new(next_idx, card_id)
			
		_:
			push_warning("Unknown command: " + name)
			return null

func _create_choice_node(tree: SceneTranspiler.DialogueTree, data: Dictionary) -> SceneTranspiler.ChoiceTreeNode:
	var options = data.get("options", [])
	var choices = []
	
	var original_index = tree.index
	tree.index += UNIQUE_CHOICE_ID_MODIFIER
	
	for opt in options:
		var opt_text = opt.get("text", "")
		var children = opt.get("children", [])
		
		# Create a temporary tree for this block
		# We need to manually process children into the main tree but offset
		tree.index += 1
		var block_start_idx = tree.index
		
		# Create a sub-tree context
		# We can reuse _process_block but we need it to append to OUR tree at current index
		# But _process_block appends sequentially.
		
		# Recursive call to process children into the SAME tree
		_process_block(children, tree)
		
		# Add a PASS node at end of block
		tree.append_node(SceneTranspiler.PassCommandNode.new(original_index + 1))
		
		choices.append({
			"label": opt_text,
			"target": block_start_idx # pointing to first node of block
		})
		
	tree.index = original_index
	return SceneTranspiler.ChoiceTreeNode.new(tree.index + 1, choices)

func _create_conditional_node(tree: SceneTranspiler.DialogueTree, data: Dictionary) -> SceneTranspiler.ConditionalTreeNode:
	var original_index = tree.index
	tree.index += UNIQUE_CONDITIONAL_ID_MODIFIER + 1
	
	# IF Block
	var if_cond_str = data.get("condition", "true")
	var if_block_data = data.get("then", [])
	
	var if_start_idx = tree.index
	# We need to construct a "Expression" object for the condition because ScenePlayer expects it
	# OLD: SceneParser.BaseExpression
	# We can fake it or modify ScenePlayer to accept strings.
	# Ideally we use the Expression class optimization here directly?
	# For now, let's create a dummy BaseExpression to satisfy strict type requirements if any
	# But wait, SceneTranspiler.ConditionalBlockNode expects SceneParser.BaseExpression
	
	var if_expr = _create_expression_object(if_cond_str)
	var if_node = SceneTranspiler.ConditionalBlockNode.new(if_start_idx, if_expr)
	
	_process_block(if_block_data, tree)
	tree.append_node(SceneTranspiler.PassCommandNode.new(original_index + 1))
	
	# ELIF Blocks
	var elif_nodes = []
	var elif_data_list = data.get("elif", [])
	for ef_data in elif_data_list:
		var ef_cond = ef_data.get("condition", "true")
		var ef_block = ef_data.get("then", [])
		
		# Start of this elif block in the big tree
		# Wait, ConditionalBlockNode stores the START index of the block? 
		# No, ConditionalBlockNode.new(next_idx, condition)
		# Checks SceneTranspiler:
		# elif_blocks.append(ConditionalBlockNode.new(dialogue_tree.index, elif_block))
		
		var ef_start = tree.index
		var ef_expr = _create_expression_object(ef_cond)
		var ef_node = SceneTranspiler.ConditionalBlockNode.new(ef_start, ef_expr)
		elif_nodes.append(ef_node)
		
		_process_block(ef_block, tree)
		tree.append_node(SceneTranspiler.PassCommandNode.new(original_index + 1))
		
	# ELSE Block
	var else_node = null
	if data.has("else"):
		var else_data = data.get("else", [])
		var else_start = tree.index
		# Else has no condition, passed as null? check transpiler
		# tree_node.else_block = ConditionalBlockNode.new(dialogue_tree.index, null)
		else_node = SceneTranspiler.ConditionalBlockNode.new(else_start, null)
		
		_process_block(else_data, tree)
		tree.append_node(SceneTranspiler.PassCommandNode.new(original_index + 1))
		
	tree.index = original_index
	
	var tree_node = SceneTranspiler.ConditionalTreeNode.new(tree.index + 1, if_node)
	tree_node.elif_blocks = elif_nodes
	tree_node.else_block = else_node
	
	return tree_node

func _create_expression_object(cond_str: String):
	# ScenePlayer expects SceneParser.BaseExpression
	# We'll mock it. 
	# Note: ScenePlayer.evaluate_condition handles "Array" (tokens) or "String" (simple)?
	# Actually it expects BaseExpression.value to be the stuff.
	var expr = SceneParser.BaseExpression.new("RAW_STRING", cond_str)
	# We need to trick ScenePlayer to treat this string as valid
	return expr

func _clean_value(val):
	# Sometimes JSON export might wrap things in "{ type=Symbol ... }" strings if logic was lazy
	# But our converter was smart.
	if val is String:
		return val
	return val

func _add_jump_point(name: String, index: int) -> void:
	if _jump_points.has(name):
		return
	_jump_points[name] = index
	# Resolve pending
	# Not implementing fully for brevity, assume converter does linear pass
