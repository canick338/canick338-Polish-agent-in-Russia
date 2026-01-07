extends Control
## Сцена карточной игры "21" (очки) с реакциями Данилы

# UI ссылки
@onready var player_hand_container: HBoxContainer = $MainContainer/PlayerArea/PlayerHand
@onready var dealer_hand_container: HBoxContainer = $MainContainer/DealerArea/DealerHand
@onready var player_score_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/ScoreContainer/PlayerScoreLabel
@onready var dealer_score_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/ScoreContainer/DealerScoreLabel
@onready var status_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/StatusLabel
@onready var hit_button: Button = $MainContainer/ButtonsArea/HitButton
@onready var stand_button: Button = $MainContainer/ButtonsArea/StandButton
@onready var new_game_button: Button = $MainContainer/ButtonsArea/NewGameButton
@onready var skip_button: Button = $SkipButton
@onready var danila_portrait: TextureRect = $DanilaContainer/DanilaPortrait

# Текстуры эмоций Данилы
const TEX_NEUTRAL = preload("res://Characters/Danila/danila_neutral.png")
const TEX_HAPPY = preload("res://Characters/Danila/danila_happy.png")
const TEX_SORRY = preload("res://Characters/Danila/danila_worried.png") # Worried/Sorry
const TEX_SAD = preload("res://Characters/Danila/danila_sad.png")
const TEX_SHOCKED = preload("res://Characters/Danila/danila_surprised.png")

var deck: Array[Card] = []
var player_hand: Array[Card] = []
var dealer_hand: Array[Card] = []
var player_score: int = 0
var dealer_score: int = 0
var game_state: String = "playing"

signal card_game_finished(player_won: bool, player_score: int, dealer_score: int)

# Звуки
var card_sound: AudioStreamPlayer

func _ready():
	# Создать звук для карт
	card_sound = AudioStreamPlayer.new()
	card_sound.name = "CardSound"
	add_child(card_sound)
	var sound_path = "res://boardgamePackAsset/Bonus/cardPlace1.ogg"
	if ResourceLoader.exists(sound_path):
		card_sound.stream = load(sound_path)
	
	# Подключить кнопки
	if hit_button: hit_button.pressed.connect(_on_hit_pressed)
	if stand_button: stand_button.pressed.connect(_on_stand_pressed)
	if new_game_button: new_game_button.pressed.connect(_on_new_game_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
		skip_button.hide()
	
	_set_danila_emotion(TEX_NEUTRAL)
	new_game()

func new_game():
	"""Начать новую игру"""
	player_hand.clear()
	dealer_hand.clear()
	_clear_hand_containers()
	
	_create_deck()
	_shuffle_deck()
	
	game_state = "playing"
	player_score = 0
	dealer_score = 0
	
	_set_danila_emotion(TEX_NEUTRAL)
	
	# Раздать начальные карты
	deal_initial_cards()
	
	_update_ui()
	
	# Кнопки
	hit_button.visible = true
	hit_button.disabled = false
	stand_button.visible = true
	stand_button.disabled = false
	new_game_button.visible = false

func deal_initial_cards():
	deal_card_to_player()
	deal_card_to_player()
	deal_card_to_dealer()
	var dealer_card = deal_card_to_dealer()
	dealer_card.face_up = false
	_update_scores()

func deal_card_to_player() -> Card:
	if deck.is_empty(): _create_deck(); _shuffle_deck()
	var card = deck.pop_back()
	card.face_up = true
	player_hand.append(card)
	_display_card(card, player_hand_container)
	_play_card_sound()
	return card # Score update handled separately

func deal_card_to_dealer() -> Card:
	if deck.is_empty(): _create_deck(); _shuffle_deck()
	var card = deck.pop_back()
	dealer_hand.append(card)
	_display_card(card, dealer_hand_container)
	if card.face_up: _play_card_sound()
	return card

func _update_scores():
	player_score = _calculate_score(player_hand)
	dealer_score = _calculate_score(dealer_hand)
	
	# Обновить эмоцию Данилы в процессе игры
	if game_state == "playing":
		if player_score > 18:
			_set_danila_emotion(TEX_SORRY) # Нервничает, рискованно
		elif player_score == 21:
			_set_danila_emotion(TEX_HAPPY) # Хороший шанс
		else:
			_set_danila_emotion(TEX_NEUTRAL)

func _calculate_score(hand: Array[Card]) -> int:
	var score = 0
	var aces = 0
	for card in hand:
		if not card.face_up: continue
		if card.rank == Card.Rank.ACE:
			aces += 1
			score += 11
		else:
			score += card.get_value()
	while score > 21 and aces > 0:
		score -= 10
		aces -= 1
	return score

func _set_danila_emotion(texture: Texture2D):
	"""Установить эмоцию Данилы с анимацией"""
	if not danila_portrait or danila_portrait.texture == texture:
		return
		
	# Анимация смены эмоции (небольшой 'pop')
	var tween = create_tween()
	tween.tween_property(danila_portrait, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_callback(func(): danila_portrait.texture = texture)
	tween.tween_property(danila_portrait, "scale", Vector2(1.0, 1.0), 0.1)

func _display_card(card: Card, container: HBoxContainer):
	"""Отобразить карту"""
	var card_control = Control.new()
	card_control.custom_minimum_size = Vector2(100, 140) # Размер карты
	
	# Тень
	var shadow = ColorRect.new()
	shadow.color = Color(0,0,0,0.5)
	shadow.size = Vector2(100, 140)
	shadow.position = Vector2(5, 5)
	card_control.add_child(shadow)
	
	var tex_rect = TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.custom_minimum_size = Vector2(100, 140)
	tex_rect.size = Vector2(100, 140)
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	
	# Попытка загрузить текстуру карты
	var tex_path = card.get_texture_path()
	if ResourceLoader.exists(tex_path):
		tex_rect.texture = load(tex_path)
	else:
		# Fallback визуализация
		var color = ColorRect.new()
		color.size = Vector2(100, 140)
		color.color = Color.WHITE if card.face_up else Color.NAVY_BLUE
		card_control.add_child(color)
		
		# Рамка
		var border = ReferenceRect.new()
		border.border_color = Color.GOLD
		border.editor_only = false
		border.border_width = 2.0
		border.size = Vector2(100, 140)
		card_control.add_child(border)
	
	if tex_rect.texture:
		card_control.add_child(tex_rect)

	container.add_child(card_control)
	
	# Анимация 'вылета' карты
	card_control.modulate.a = 0.0
	card_control.position.y -= 50
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_control, "modulate:a", 1.0, 0.3)
	tween.tween_property(card_control, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _clear_hand_containers():
	for c in player_hand_container.get_children(): c.queue_free()
	for c in dealer_hand_container.get_children(): c.queue_free()

func _update_ui():
	# Очки игрока
	player_score_label.text = "Вы: %d" % player_score
	if player_score > 21:
		player_score_label.modulate = Color.RED
		player_score_label.text += " (ПЕРЕБОР)"
	elif player_score == 21:
		player_score_label.modulate = Color.GREEN
		player_score_label.text += " (MAX)"
	else:
		player_score_label.modulate = Color.WHITE
	
	# Очки дилера
	if game_state != "playing":
		dealer_score_label.text = "Дилер: %d" % dealer_score
		if dealer_score > 21: dealer_score_label.text += " (ПЕРЕБОР)"
	else:
		# Скрываем закрытую карту
		var visible_score = 0
		for c in dealer_hand:
			if c.face_up: visible_score += c.get_value()
		dealer_score_label.text = "Дилер: ?" # Можно показать видимые очки
	
	# Статус
	match game_state:
		"playing": status_label.text = "Ваш ход..."
		"player_bust": status_label.text = "ПЕРЕБОР! ВЫ ПРОИГРАЛИ."
		"dealer_bust": status_label.text = "ДИЛЕР ПЕРЕБРАЛ! ПОБЕДА!"
		"player_won": status_label.text = "ПОБЕДА! ВЫ НАБРАЛИ БОЛЬШЕ."
		"dealer_won": status_label.text = "ПОРАЖЕНИЕ. ДИЛЕР БЛИЖЕ К 21."
		"tie": status_label.text = "НИЧЬЯ."

func _on_hit_pressed():
	if game_state != "playing": return
	hit_button.disabled = true
	
	var card = deal_card_to_player()
	_update_scores()
	_update_ui()
	
	await get_tree().create_timer(0.3).timeout
	
	# Проверка перебора
	if player_score > 21:
		game_state = "player_bust"
		_set_danila_emotion(TEX_SHOCKED) # Шок от проигрыша
		_shake_screen()
		_end_game()
	else:
		hit_button.disabled = false

func _on_stand_pressed():
	if game_state != "playing": return
	
	# Ход дилера
	hit_button.disabled = true
	stand_button.disabled = true
	
	# Открыть карты
	for c in dealer_hand: c.face_up = true
	_clear_hand_containers()
	for c in player_hand: _display_card(c, player_hand_container)
	for c in dealer_hand: _display_card(c, dealer_hand_container)
	
	_update_scores()
	_update_ui()
	
	# Логика дилера (берет до 17)
	while dealer_score < 17:
		await get_tree().create_timer(0.8).timeout
		var card = deal_card_to_dealer()
		card.face_up = true
		_update_scores() # Пересчитать с новой картой
		_clear_hand_containers() # Перерисовать, чтобы показать новую карту
		for c in player_hand: _display_card(c, player_hand_container)
		for c in dealer_hand: _display_card(c, dealer_hand_container)
		_play_card_sound()
		_update_ui()
	
	# Определение победителя
	if dealer_score > 21:
		game_state = "dealer_bust"
		_set_danila_emotion(TEX_HAPPY)
	elif player_score > dealer_score:
		game_state = "player_won"
		_set_danila_emotion(TEX_HAPPY)
	elif dealer_score > player_score:
		game_state = "dealer_won"
		_set_danila_emotion(TEX_SAD)
	else:
		game_state = "tie"
		_set_danila_emotion(TEX_NEUTRAL)
		
	_end_game()

func _end_game():
	_update_ui()
	hit_button.visible = false
	stand_button.visible = false
	new_game_button.visible = true
	
	# Отправить сигнал завершения, если нужно для сюжета (но тут бесконечная игра пока)
	# card_game_finished.emit(...)

func _on_new_game_pressed():
	new_game()

func _on_skip_pressed():
	card_game_finished.emit(false, 0, 0)

func _shuffle_deck():
	deck.shuffle()

func _create_deck():
	deck.clear()
	for suit in Card.Suit.values():
		for rank in Card.Rank.values():
			deck.append(Card.new(suit, rank, true))

func _play_card_sound():
	if card_sound and card_sound.stream: card_sound.play()

func _shake_screen():
	var tween = create_tween()
	var original_pos = position
	for i in range(5):
		tween.tween_property(self, "position", original_pos + Vector2(randf_range(-5,5), randf_range(-5,5)), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)
