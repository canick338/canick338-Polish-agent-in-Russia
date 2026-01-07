extends Control

signal back_requested

@onready var grid = %GridContainer
@onready var balance_label = %BalanceLabel

func _ready():
	_update_ui()
	$BackButton.pressed.connect(_on_back_pressed)

func _update_ui():
	# Update Balance
	balance_label.text = "Баланс: %d$" % GameGlobal.player_money
	
	# Clear Grid
	for child in grid.get_children():
		child.queue_free()
	
	# Populate Grid
	for card_id in GameGlobal.CARD_DATABASE:
		var data = GameGlobal.CARD_DATABASE[card_id]
		var is_unlocked = GameGlobal.is_card_unlocked(card_id)
		
		var card_node = _create_card_node(card_id, data, is_unlocked)
		grid.add_child(card_node)

func _create_card_node(id: String, data: Dictionary, unlocked: bool) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(200, 300)
	
	# 1. Image Area
	var rect = TextureRect.new()
	rect.custom_minimum_size = Vector2(200, 200)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture = load(data["texture_path"])
	
	if not unlocked:
		rect.modulate = Color(0, 0, 0, 1) # Silhouette
	
	container.add_child(rect)
	
	# 2. Name Label
	var name_lbl = Label.new()
	name_lbl.text = data["name"] if unlocked else "???"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_lbl)
	
	# 3. Action Button / Info
	if unlocked:
		var info_lbl = Label.new()
		info_lbl.text = "Открыто"
		info_lbl.modulate = Color(0.5, 1, 0.5)
		info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(info_lbl)
	else:
		if data["unlock_type"] == "buy":
			var btn = Button.new()
			var cost = data["cost"]
			btn.text = "Купить (%d$)" % cost
			
			if GameGlobal.player_money >= cost:
				btn.pressed.connect(_on_buy_pressed.bind(id))
			else:
				btn.disabled = true
				
			container.add_child(btn)
		else:
			var lock_lbl = Label.new()
			lock_lbl.text = "Закрыто"
			lock_lbl.modulate = Color(1, 0.5, 0.5)
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			container.add_child(lock_lbl)
			
	return container

func _on_buy_pressed(card_id):
	if GameGlobal.buy_card(card_id):
		# Refresh UI to show unlocked state and new balance
		_update_ui()

func _on_back_pressed():
	back_requested.emit()
	queue_free()
