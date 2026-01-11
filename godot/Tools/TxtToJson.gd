extends SceneTree

func _init():
	print("Starting TXT to JSON conversion...")
	var source_dir = "res://Story/"
	var dir = DirAccess.open(source_dir)
	
	if not dir:
		print("Error: Could not open directory " + source_dir)
		quit(1)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".txt"):
			var full_path = source_dir + file_name
			print("Converting: " + full_path)
			convert_file(full_path)
		file_name = dir.get_next()
	
	print("Conversion complete!")
	quit()

func convert_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Failed to open file: " + path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	var lexer = SceneLexer.new()
	var tokens = lexer.tokenize(content)
	
	var parser = SceneParser.new()
	var tree = parser.parse(tokens)
	
	var json_data = serialize_tree(tree)
	
	var json_string = JSON.stringify(json_data, "\t")
	var new_path = path.replace(".txt", ".json")
	
	var out_file = FileAccess.open(new_path, FileAccess.WRITE)
	if out_file:
		out_file.store_string(json_string)
		out_file.close()
		print("Saved to: " + new_path)
	else:
		print("Failed to save to: " + new_path)

func serialize_tree(tree: SceneParser.SyntaxTree) -> Array:
	var result = []
	for expr in tree.values:
		var serialized = serialize_expression(expr)
		if serialized:
			result.append(serialized)
	return result

func serialize_expression(expr):
	if expr == null:
		return null
		
	# Check type using string comparison since we can't easily access the const enum from an instance sometimes
	var type = expr.type
	
	match type:
		"Dialogue":
			return serialize_dialogue(expr)
		"Command":
			return serialize_command(expr)
		"Choice":
			return serialize_choice(expr)
		"ConditionalTree":
			return serialize_conditional(expr)
		_:
			# Fallback for simpler expressions
			if expr.value is Array:
				return expr.value # Should not happen for top level?
			return {"type": "unknown", "raw_type": type, "value": str(expr.value)}

func serialize_dialogue(expr: SceneParser.FunctionExpression) -> Dictionary:
	# Format: [character, expression?, animation?, side?, text]
	var node = {
		"type": "dialogue",
		"text": expr.value
	}
	
	# Arguments handling mirrors SceneTranspiler logic
	var args = expr.arguments
	if args.size() > 0:
		node["character"] = get_arg_value(args[0])
		
		var arg_index = 1
		var expression_found = false
		var animation_found = false
		var side_found = false
		
		while arg_index < args.size():
			var val = get_arg_value(args[arg_index])
			var str_val = str(val)
			
			if str_val == "": # Empty string is animation placeholder sometimes? Or explicit empty string
				if not animation_found:
					node["animation"] = ""
					animation_found = true
			elif str_val == "left" or str_val == "right":
				if not side_found:
					node["side"] = str_val
					side_found = true
			elif not expression_found:
				node["mood"] = str_val # We call it "mood" in JSON usually, "expression" in engine
				expression_found = true
			elif not animation_found:
				node["animation"] = str_val
				animation_found = true
			
			arg_index += 1
			
	return node

func serialize_command(expr: SceneParser.FunctionExpression) -> Dictionary:
	var args = []
	for arg in expr.arguments:
		args.append(get_arg_value(arg))
		
	return {
		"type": "command",
		"name": expr.value,
		"args": args
	}

func serialize_choice(expr: SceneParser.BaseExpression) -> Dictionary:
	var options = []
	for block in expr.value: # Array of ChoiceBlockExpression
		var option = {
			"text": block.label,
			"children": serialize_block(block.value)
		}
		options.append(option)
	
	return {
		"type": "choice",
		"options": options
	}

func serialize_conditional(expr: SceneParser.ConditionalTreeExpression) -> Dictionary:
	var node = {
		"type": "if",
		"condition": get_condition_string(expr.if_block.value),
		"then": serialize_block(expr.if_block.block)
	}
	
	# Elif
	if expr.elif_block and expr.elif_block.size() > 0:
		node["elif"] = []
		for block in expr.elif_block:
			node["elif"].append({
				"condition": get_condition_string(block.value),
				"then": serialize_block(block.block)
			})
			
	# Else
	if expr.else_block:
		node["else"] = serialize_block(expr.else_block.block)
		
	return node

func serialize_block(block_content: Array) -> Array:
	var result = []
	for item in block_content:
		var serialized = serialize_expression(item)
		if serialized:
			result.append(serialized)
	return result

func get_arg_value(arg):
	# Handle BaseExpression
	if arg is SceneParser.BaseExpression:
		return arg.value
	
	# Handle Token via Duck Typing or property access
	# Checking "type" and "value" properties existence
	if typeof(arg) == TYPE_OBJECT:
		if "value" in arg:
			return arg.value
			
	return str(arg)

func get_condition_string(val) -> String:
	# val is Array of expressions/tokens
	if val is Array:
		var parts = []
		for item in val:
			var arg_val = get_arg_value(item)
			# Only quote strings that contain spaces and aren't numbers or operators?
			# Actually for condition strings in Expression class, strings need quotes.
			# But variable names (Symbols) do NOT.
			# Token does not tell us easily if it was a String Literal or Symbol here except by checking type property if available.
			
			var is_string_literal = false
			if typeof(item) == TYPE_OBJECT and "type" in item:
				if item.type == "String": # SceneLexer.TOKEN_TYPES.STRING_LITERAL
					is_string_literal = true
			
			if is_string_literal:
				parts.append('"' + str(arg_val) + '"')
			else:
				parts.append(str(arg_val))
				
		return "".join(parts)
	return str(val)
