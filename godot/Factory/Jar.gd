extends Control
## Банка повидла на конвейере

signal jar_clicked()

var _is_labeled: bool = false

func _ready():
	# Сделать банку кликабельной
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Убедиться, что банка может получать события
	process_mode = Node.PROCESS_MODE_INHERIT

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not _is_labeled:
				label_jar()
				jar_clicked.emit()
				# Остановить распространение события
				accept_event()

func is_labeled() -> bool:
	"""Проверить, помечена ли банка"""
	return _is_labeled

func label_jar():
	"""Наклеить наклейку на банку"""
	if _is_labeled:
		return
	
	_is_labeled = true
	
	# Показать наклейку если она есть
	if has_node("Sticker"):
		$Sticker.visible = true
		# Анимация наклейки
		var tween = create_tween()
		$Sticker.modulate = Color(1, 1, 1, 0)
		tween.tween_property($Sticker, "modulate", Color(1, 1, 1, 0.8), 0.2)
