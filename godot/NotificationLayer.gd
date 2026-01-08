extends CanvasLayer

@onready var panel = %Panel
@onready var icon = %Icon
@onready var name_label = %Name

func _ready():
	GameGlobal.card_unlocked.connect(_on_card_unlocked)
	panel.position.y = -100 # Hide initially

func _on_card_unlocked(card_id):
	if card_id not in GameGlobal.CARD_DATABASE:
		return
		
	var data = GameGlobal.CARD_DATABASE[card_id]
	
	icon.texture = load(data["texture_path"])
	name_label.text = data["name"]
	
	_play_animation()

func _play_animation():
	var tween = create_tween()
	# Slide Down
	tween.tween_property(panel, "position:y", 10.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Wait
	tween.tween_interval(3.0)
	# Slide Up
	tween.tween_property(panel, "position:y", -100.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
