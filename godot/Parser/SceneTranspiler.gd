## Receives a `SceneParser.SyntaxTree` and produces a `DialogueTree`, an object
## representing a scene, which a `ScenePlayer` instance can read.
##
## Use the `transpile()` method to get a `DialogueTree`.
class_name SceneTranspiler
extends RefCounted

# We assign a number to every step in a generated `DialogueTree`.
# We use the numbers below to offset the index number of choices and conditional
# blocks. This helps us to group them in the `DialogueTree.nodes` dictionary.
const UNIQUE_CHOICE_ID_MODIFIER = 1000000000
const UNIQUE_CONDITIONAL_ID_MODIFIER = 2100000000

const ERROR_NONEXISTENT_JUMP_POINT := -3

# A mapping of named jump points to a corresponding node in the tree.
var _jump_points := {}
# Store jump nodes with unknown jump points
var _unresolved_jump_nodes := []


## A tree of nodes representing a scene. It stores nodes in its `nodes` dictionary.
## See the node types below.
class DialogueTree:
	var nodes := {}
	var index := 0

	## Add a new node to the tree and assign it a unique index in the tree
	func append_node(node: BaseNode) -> void:
		nodes[index] = node
		index += 1


## Base type for all other node types below.
class BaseNode:
	var next: int

	func _init(_next: int) -> void:
		self.next = _next


## Node with a line of text optional parameters.
class DialogueNode:
	extends BaseNode

	var line: String
	var character: String
	var expression: String
	var animation: String
	var side: String

	func _init(_next: int, _line: String) -> void:
		super(next)
		self.next = _next
		self.line = _line


## Node type for a command that changes the displayed background, with an
## optional transition animation.
class BackgroundCommandNode:
	extends BaseNode

	var background: String
	var transition: String

	func _init(_next: int, _background: String) -> void:
		super(_next)
		self.background = _background
	
	func _to_string() -> String:
		return "{next: %s, bg: %s, tr: %s}" % [next, background, transition]


## Node type for a command that makes the game jump to another scene (or restart
## the current one).
class SceneCommandNode:
	extends BaseNode

	var scene_path: String

	func _init(_next: int, _scene_path: String) -> void:
		super(_next)
		self.scene_path = _scene_path


## Node type for a command that runs a scene transition animation, like a fade
## to black.
class TransitionCommandNode:
	extends BaseNode

	var transition: String

	func _init(_next: int, _transition: String) -> void:
		super(_next)
		self.transition = _transition


## Node type for a command that plays a video cutscene.
class CutsceneCommandNode:
	extends BaseNode

	var video_path: String
	var can_skip: bool
	var auto_continue: bool

	func _init(_next: int, _video_path: String) -> void:
		super(_next)
		self.video_path = _video_path
		self.can_skip = true
		self.auto_continue = true


## Node type for a command that plays a minigame.
class MinigameCommandNode:
	extends BaseNode

	var minigame_name: String

	func _init(_next: int, _minigame_name: String) -> void:
		super(_next)
		self.minigame_name = _minigame_name


## Node type representing a player choice.
class ChoiceTreeNode:
	extends BaseNode

	var choices: Array

	func _init(_next: int, _choices: Array) -> void:
		super(_next)
		self.next = _next
		self.choices = _choices


## Represents one conditional block, starting with an `if`, `elif`, or `else`
## keyword.
class ConditionalBlockNode:
	extends BaseNode

	var condition: SceneParser.BaseExpression

	func _init(_next: int, _condition: SceneParser.BaseExpression) -> void:
		super(_next)
		self.condition = _condition


## Node type representing a tree of if, elifs, and else blocks in the script.
class ConditionalTreeNode:
	extends BaseNode

	var if_block: ConditionalBlockNode
	# There can be multiple `elif` blocks in a row, which is why we store them
	# in an array.
	var elif_blocks: Array
	var else_block: ConditionalBlockNode

	func _init(_next: int, _if_block: ConditionalBlockNode) -> void:
		super(_next)
		self.if_block = _if_block


## Represents a command that creates or modify a persistent variable. These
## variables are saved in the player's save file.
class SetCommandNode:
	extends BaseNode

	var symbol: String
	var value

	func _init(_next: int, _symbol: String, _value) -> void:
		super(_next)
		self.symbol = _symbol
		self.value = _value


## Node type for a command that will advance to any existing jump point.
class JumpCommandNode:
	extends BaseNode

	var jump_point: String

	func _init(_next: int) -> void:
		super(_next)


## Node type for a command that will break out of any running code block.
class PassCommandNode:
	extends BaseNode

	func _init(_next: int) -> void:
		super(_next)


## Node type for unlocking a card/dossier entry
class UnlockCommandNode:
	extends BaseNode
	
	var card_id: String
	
	func _init(_next: int, _card_id: String) -> void:
		super(_next)
		self.card_id = _card_id


## Takes in a syntax tree from the SceneParser and turns it into a
## `DialogueTree` for the `ScenePlayer` to play.
func transpile(syntax_tree: SceneParser.SyntaxTree, start_index: int) -> DialogueTree:
	var dialogue_tree := DialogueTree.new()
	dialogue_tree.index = start_index

	while not syntax_tree.is_at_end():
		var expression: SceneParser.BaseExpression = syntax_tree.move_to_next_expression()

		if expression.type == SceneParser.EXPRESSION_TYPES.COMMAND:
			var node := _transpile_command(dialogue_tree, expression)
			# There's currently no proper error handling for commands, we skip invalid ones.
			if node == null:
				continue
			dialogue_tree.append_node(node)

		elif expression.type == SceneParser.EXPRESSION_TYPES.DIALOGUE:
			# A dialogue node only needs the dialogue text, anything else is optional
			var node := _transpile_dialogue(dialogue_tree, expression)
			dialogue_tree.append_node(node)

		elif expression.type == SceneParser.EXPRESSION_TYPES.CHOICE:
			var choices := []

			# Stores the position for the choice tree node which has pointers to the actual choice
			# blocks that are stored at a unique place
			var original_value: int = dialogue_tree.index

			# Store the choice nodes at a normally unreacheable place in the dialogue tree
			dialogue_tree.index += UNIQUE_CHOICE_ID_MODIFIER
			for block in expression.value:
				var subtree := SceneParser.SyntaxTree.new()
				subtree.values = block.value

				dialogue_tree.index += 1

				# Any jump points, variables that get declared in the block's tree don't need to be
				# handled since the jump_points, variables are constants that are shared between all
				# DialogueTree instances
				# We pass in the current index tree's index here so the subtree can transpile
				# properly
				var block_dialogue_tree: DialogueTree = transpile(subtree, dialogue_tree.index)

				# Add the pointer to this code block in the choice tree
				choices.append({label = block.label, target = dialogue_tree.index})

				# Add the block's tree's nodes to the main dialogue tree
				_copy_nodes(original_value, block_dialogue_tree.nodes.keys(), dialogue_tree, block_dialogue_tree)

			# Reset the index
			dialogue_tree.index = original_value
			dialogue_tree.append_node(ChoiceTreeNode.new(dialogue_tree.index + 1, choices))

		# Parsing sequences of conditional blocks (if, elif, else)
		elif expression.type == SceneParser.EXPRESSION_TYPES.CONDITIONAL_TREE:
			# TODO: If the conditional is incorrect, it's the parser that should error out.
			if expression.if_block == null:
				push_error("Invalid conditional tree")
				continue

			# We parse conditional trees by calling the `transpile()` method recursively.
			# This is because conditional trees can contain about anything.
			#
			# We first store the index of the conditional tree.
			var original_value := dialogue_tree.index

			# We then offset the conditional nodes at a normally unreacheable
			# place in the dialogue tree, apart from the choice nodes
			dialogue_tree.index += UNIQUE_CONDITIONAL_ID_MODIFIER + 1

			# The conditional tree only needs a pointer to the `if` block to be
			# proper, elifs and else are optional
			var tree_node = ConditionalTreeNode.new(
				original_value + 1,
				ConditionalBlockNode.new(
					# The pointer to the if block's index in the dialogue tree
					dialogue_tree.index,
					# The if's condition
					expression.if_block
					)
				)

			# Transpile the if block
			var if_subtree := SceneParser.SyntaxTree.new()
			if_subtree.values = expression.if_block.block
			var if_block_dialogue_tree: DialogueTree = transpile(if_subtree, dialogue_tree.index)

			# Add the if block's tree's nodes to the main dialogue tree
			_copy_nodes(original_value, if_block_dialogue_tree.nodes.keys(), dialogue_tree, if_block_dialogue_tree)

			# Transpile the elif blocks
			if not expression.elif_block.is_empty():
				var elif_blocks := []

				for elif_block in expression.elif_block:
					var elif_subtree := SceneParser.SyntaxTree.new()
					elif_subtree.values = elif_block.block
					var elif_block_dialogue_tree: DialogueTree = transpile(
						elif_subtree, dialogue_tree.index
					)

					# Store pointer to the elif block in the choice tree node
					elif_blocks.append(ConditionalBlockNode.new(dialogue_tree.index, elif_block))
					# copy the elif block's tree nodes to the main dialogue tree
					_copy_nodes(original_value, elif_block_dialogue_tree.nodes.keys(), dialogue_tree, elif_block_dialogue_tree)
				tree_node.elif_blocks = elif_blocks

			# Transpile the else block
			if expression.else_block != null:
				var else_subtree := SceneParser.SyntaxTree.new()
				else_subtree.values = expression.else_block.block

				var else_block_dialogue_tree: DialogueTree = transpile(
					else_subtree, dialogue_tree.index
				)
				# Store pointer to the else block in the choice tree node
				tree_node.else_block = ConditionalBlockNode.new(dialogue_tree.index, null)
				# Add the else block's tree's nodes to the main dialogue tree
				_copy_nodes(original_value, else_block_dialogue_tree.nodes.keys(), dialogue_tree, else_block_dialogue_tree)
			# Reset the index
			dialogue_tree.index = original_value
			dialogue_tree.append_node(tree_node)

		else:
			push_error("Unrecognized expression of type: %s with value: %s" % [expression.type, expression.value])

	return dialogue_tree


## Вспомогательная функция для извлечения значения из аргумента
func _get_argument_value(arg, default = ""):
	"""Извлекает значение из аргумента (может быть BaseExpression или токен)"""
	if arg is SceneParser.BaseExpression:
		return arg.value
	elif arg is SceneLexer.Token:
		return arg.value
	else:
		return arg if arg != null else default

# Transpiles a command expression and returns the approriate command node type.
func _transpile_command(dialogue_tree: DialogueTree, expression: SceneParser.BaseExpression) -> BaseNode:
	var command_node: BaseNode = null

	if expression.value == SceneLexer.BUILT_IN_COMMANDS.BACKGROUND:
		var background: String = _get_argument_value(expression.arguments[0] if expression.arguments.size() > 0 else null, "")

		command_node = BackgroundCommandNode.new(dialogue_tree.index + 1, background)
		command_node.transition = _get_argument_value(expression.arguments[1] if expression.arguments.size() > 1 else null, "")

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.SCENE:
		# For now, the command only works when next_scene is used as an argument.
		var new_scene: String = _get_argument_value(expression.arguments[0] if expression.arguments.size() > 0 else null, "")
		command_node = SceneCommandNode.new(dialogue_tree.index + 1, new_scene)

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.PASS:
		# Using `pass` is just syntactic sugar since a `pass` node
		# is always appended at the end of each code block anyways
		# to allow the blocks to escape to its parent properly when
		# it's finished.
		pass

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.JUMP:
		# Jump to an existing jump point
		var jump_point: String = _get_argument_value(expression.arguments[0] if expression.arguments.size() > 0 else null, "")
		if _jump_points.has(jump_point):
			var target: int = _get_jump_point(jump_point)
			command_node = JumpCommandNode.new(target)
		# Store as an unresolved jump node
		# TODO: remove allowing for unresolved jumps?
		else:
			var jump_node := JumpCommandNode.new(-1)
			jump_node.jump_point = jump_point
			command_node = jump_node
			# Pass in the instance by reference so we can modify this later
			_unresolved_jump_nodes.append(jump_node)

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.TRANSITION:
		var transition: String = _get_argument_value(expression.arguments[0] if expression.arguments.size() > 0 else null, "")
		command_node = TransitionCommandNode.new(dialogue_tree.index + 1, transition)

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.CUTSCENE:
		if expression.arguments.size() < 1:
			push_error("CUTSCENE command requires at least 1 argument: video path")
			return null
		
		var video_path: String = _get_argument_value(expression.arguments[0], "")
		# Добавить префикс res:// если его нет
		if not video_path.begins_with("res://"):
			video_path = "res://Cutscenes/" + video_path
		# Добавить расширение .ogv если его нет
		if not video_path.ends_with(".ogv") and not video_path.ends_with(".webm"):
			video_path += ".ogv"
		
		command_node = CutsceneCommandNode.new(dialogue_tree.index + 1, video_path)
		
		# Опциональные параметры
		if expression.arguments.size() > 1:
			var can_skip_val = _get_argument_value(expression.arguments[1], "false")
			command_node.can_skip = can_skip_val == "true" or can_skip_val == true
		if expression.arguments.size() > 2:
			var auto_continue_val = _get_argument_value(expression.arguments[2], "false")
			command_node.auto_continue = auto_continue_val == "true" or auto_continue_val == true

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.MINIGAME:
		if expression.arguments.size() < 1:
			push_error("MINIGAME command requires at least 1 argument: minigame name")
			return null
		
		var minigame_name: String = _get_argument_value(expression.arguments[0], "")
		command_node = MinigameCommandNode.new(dialogue_tree.index + 1, minigame_name)

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.SET:
		if expression.arguments.size() < 2:
			push_error("SET command requires 2 arguments: variable name and value. Got %d arguments." % expression.arguments.size())
			return null
		
		# Получаем значения из аргументов
		var symbol: String = _get_argument_value(expression.arguments[0], "")
		var value = _get_argument_value(expression.arguments[1] if expression.arguments.size() > 1 else null, null)
		
		if symbol == "":
			push_error("SET command: variable name is empty")
			return null
		
		command_node = SetCommandNode.new(dialogue_tree.index + 1, symbol, value)

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.MARK:
		var new_jump_point: String = _get_argument_value(expression.arguments[0] if expression.arguments.size() > 0 else null, "")
		_add_jump_point(new_jump_point, dialogue_tree.index)

		# Handle any unresolved jump nodes that point to this jump point
		# Use a `temp` variable because modifying an array while also looping
		# through it can get buggy.
		var temp := _unresolved_jump_nodes
		for jump_node in _unresolved_jump_nodes:
			if jump_node.jump_point == new_jump_point:
				jump_node.next = dialogue_tree.index
				temp.erase(jump_node)

		_unresolved_jump_nodes = temp

	elif expression.value == SceneLexer.BUILT_IN_COMMANDS.UNLOCK:
		var card_id: String = _get_argument_value(expression.arguments[0] if expression.arguments.size() > 0 else null, "")
		if card_id == "":
			push_error("UNLOCK command requires a card_id argument")
		else:
			command_node = UnlockCommandNode.new(dialogue_tree.index + 1, card_id)

	else:
		push_error("Unrecognized command type `%s`" % expression.value)

	return command_node


func _transpile_dialogue(dialogue_tree: DialogueTree, expression: SceneParser.BaseExpression) -> DialogueNode:
	var node := DialogueNode.new(dialogue_tree.index + 1, expression.value)
	
	if expression.arguments.is_empty():
		return node
	
	# Формат: [character, expression, animation?, side?, text]
	# character всегда первый (SYMBOL)
	var char_arg = expression.arguments[0] if expression.arguments.size() > 0 else null
	if char_arg:
		if char_arg is SceneParser.BaseExpression:
			node.character = str(char_arg.value)
		elif char_arg is SceneLexer.Token:
			node.character = str(char_arg.value)
		else:
			node.character = str(char_arg)
	
	# Определяем остальные аргументы по типу и позиции
	var arg_index := 1
	var expression_found := false
	var animation_found := false
	var side_found := false
	
	# Проходим по аргументам и определяем их тип
	while arg_index < expression.arguments.size():
		var arg = expression.arguments[arg_index]
		var arg_type = ""
		var arg_value = null
		
		# Определяем тип и значение аргумента
		if arg is SceneParser.BaseExpression:
			arg_type = arg.type
			arg_value = arg.value
		elif arg is SceneLexer.Token:
			arg_type = arg.type
			arg_value = arg.value
		else:
			arg_value = arg
		
		# Последний аргумент - это всегда текст диалога (STRING_LITERAL, не пустой)
		if arg_index == expression.arguments.size() - 1 and arg_type == SceneLexer.TOKEN_TYPES.STRING_LITERAL and str(arg_value) != "":
			# Это текст диалога - уже в expression.value
			break
		
		# Если это пустая строка - это animation
		if arg_type == SceneLexer.TOKEN_TYPES.STRING_LITERAL and str(arg_value) == "":
			if not animation_found:
				node.animation = ""
				animation_found = true
		# Если это SYMBOL и это "left" или "right" - это side
		elif arg_type == SceneLexer.TOKEN_TYPES.SYMBOL and (str(arg_value) == "left" or str(arg_value) == "right"):
			if not side_found:
				node.side = str(arg_value)
				side_found = true
		# Иначе это expression (если еще не найден)
		elif not expression_found:
			node.expression = str(arg_value)
			expression_found = true
		# Если expression уже найден, то следующий символ - это animation (если еще не найден)
		elif not animation_found:
			node.animation = str(arg_value)
			animation_found = true
		
		arg_index += 1
	
	return node


## Adds node from a source tree to a target tree
func _copy_nodes(
	original_value: int, nodes: Array, target_tree: DialogueTree, source_tree: DialogueTree
) -> void:
	# Append a `pass` node to the end of the block to make sure it'll properly
	# end and continue to its parent block.
	source_tree.append_node(PassCommandNode.new(original_value + 1))
	nodes.append(source_tree.nodes.keys().back())

	# Add the source tree's nodes to the target tree
	for node in nodes:
		target_tree.nodes[node] = source_tree.nodes[node]
		target_tree.index += 1


func _add_jump_point(name: String, index: int) -> void:
	if _jump_points.has(name):
		push_error("Jump point %s already exists. Can't re-create it." % name)
		return

	_jump_points[name] = index


func _get_jump_point(name: String) -> int:
	if _jump_points.has(name):
		return _jump_points[name]

	# -3 because -1, -2 are already used in the ScenePlayer interpreter
	return ERROR_NONEXISTENT_JUMP_POINT
