extends Control

const SAVE_LOAD_SCENE = preload("res://SaveLoadMenu.tscn")

func _ready():
	# Make sure this menu works even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pause the game when this menu opens
	get_tree().paused = true

func _on_resume_pressed():
	get_tree().paused = false
	queue_free()

func _on_save_pressed():
	var menu = SAVE_LOAD_SCENE.instantiate()
	menu.set_mode("save")
	add_child(menu)
	# We don't hide this menu, the save menu will overlay it

func _on_load_pressed():
	var menu = SAVE_LOAD_SCENE.instantiate()
	menu.set_mode("load")
	add_child(menu)

func _on_exit_pressed():
	get_tree().paused = false
	
	var main_node = get_parent()
	if main_node and main_node.has_method("return_to_main_menu"):
		main_node.return_to_main_menu()
	else:
		get_tree().change_scene_to_file("res://Main.tscn")
		
	queue_free()
