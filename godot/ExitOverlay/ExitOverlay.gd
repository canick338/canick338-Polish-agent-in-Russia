extends Control

signal confirmed
signal cancelled

func _ready():
	# Connect internal buttons to emit signals
	$ButtonsBox/ConfirmExitButton.pressed.connect(_on_confirm)
	$ButtonsBox/CancelExitButton.pressed.connect(_on_cancel)

func _on_confirm():
	confirmed.emit()

func _on_cancel():
	cancelled.emit()
