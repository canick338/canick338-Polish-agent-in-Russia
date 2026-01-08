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
			var info = GameGlobal.get_slot_info(i)
			if info["empty"]:
				btn.text = "Пустой слот " + str(i)
			else:
				btn.text = "Слот %d\n%s\nДеньги: %d" % [i, info["timestamp"], info["money"]]
			
			# Disconnect old signals to avoid duplicates
			if btn.pressed.is_connected(_on_slot_pressed):
				btn.pressed.disconnect(_on_slot_pressed)
				
			btn.pressed.connect(_on_slot_pressed.bind(i))

func _on_slot_pressed(slot_id):
	if mode == "save":
		GameGlobal.save_game(slot_id)
		_update_ui() # Refresh to show new save
	else:
		if GameGlobal.load_game(slot_id):
			# Success load
			# If called from MainMenu, we should start the game.
			# If called from Game, we just resume state (todo).
			# For now, simplistic approach:
			if get_parent().has_method("start_game_from_load"):
				get_parent().start_game_from_load()
			else:
				# Just close menu if in game?
				# Reload current scene? This is complex.
				# For VNs, usually means transitioning to the saved scene.
				# Since we store meta-data only right now, it just loads money.
				# The user wanted a proper save tab.
				queue_free()

func _on_close_pressed():
	queue_free()
