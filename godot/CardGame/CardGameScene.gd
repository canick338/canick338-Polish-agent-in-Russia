extends Control
## Сцена карточной игры "21" (очки) с реакциями Данилы и Рабочего

# UI ссылки
@onready var player_hand_container: HBoxContainer = $MainContainer/PlayerArea/PlayerHand
@onready var dealer_hand_container: HBoxContainer = $MainContainer/DealerArea/DealerHand
@onready var player_score_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/ScoreContainer/PlayerScoreLabel
@onready var dealer_score_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/ScoreContainer/DealerScoreLabel
@onready var match_score_label: Label = %MatchScoreLabel
@onready var status_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/StatusLabel
@onready var hit_button: Button = $MainContainer/ButtonsArea/HitButton
@onready var stand_button: Button = $MainContainer/ButtonsArea/StandButton
@onready var next_round_button: Button = %NextRoundButton
@onready var new_game_button: Button = $MainContainer/ButtonsArea/NewGameButton
@onready var skip_button: Button = $SkipButton
@onready var danila_portrait: TextureRect = $DanilaContainer/DanilaPortrait
@onready var worker_portrait: TextureRect = $WorkerContainer/WorkerPortrait
@onready var balance_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/MoneyInfo/BalanceLabel
@onready var current_bet_label: Label = $MainContainer/InfoArea/InfoPanel/VBox/MoneyInfo/BetLabel
@onready var betting_overlay: Control = %BettingOverlay
@onready var bets_hbox: HBoxContainer = %BetsHBox

# Текстуры эмоций Данилы
const TEX_DANI_NEUTRAL = preload("res://Characters/Danila/danila_neutral.png")
const TEX_DANI_HAPPY = preload("res://Characters/Danila/danila_happy.png")
const TEX_DANI_SORRY = preload("res://Characters/Danila/danila_worried.png")
const TEX_DANI_SAD = preload("res://Characters/Danila/danila_sad.png")
const TEX_DANI_SHOCKED = preload("res://Characters/Danila/danila_surprised.png")

# Текстуры эмоций Рабочего (заглушки загружаются по путям)
const WORKER_PATH = "res://Characters/Worker/"
var tex_worker_neutral: Texture2D
var tex_worker_happy: Texture2D
var tex_worker_angry: Texture2D
var tex_worker_smug: Texture2D

var deck: Array[Card] = []
var player_hand: Array[Card] = []
var dealer_hand: Array[Card] = []
var player_score: int = 0
var dealer_score: int = 0
var current_bet: int = 0
var game_state: String = "betting" # betting, playing, match_ended

# Match System
var player_match_wins: int = 0
var dealer_match_wins: int = 0
const WINS_NEEDED: int = 3

signal card_game_finished(player_won: bool, player_score: int, dealer_score: int)

# Звуки
var card_sound: AudioStreamPlayer
var coin_sound: AudioStreamPlayer

var loans_taken: int = 0
const MAX_LOANS: int = 1

func _ready():
	_load_worker_assets()
	_setup_audio()
	
	# Подключить кнопки игрового процесса
	if hit_button: hit_button.pressed.connect(_on_hit_pressed)
	if stand_button: stand_button.pressed.connect(_on_stand_pressed)
	if next_round_button: next_round_button.pressed.connect(_start_next_round)
	if new_game_button: new_game_button.pressed.connect(_on_new_game_pressed)
	if skip_button: skip_button.pressed.connect(_on_skip_pressed)
	
	# Кнопки меню
	%StartGameButton.pressed.connect(_on_intro_start_pressed)
	%ExitButton.pressed.connect(func(): card_game_finished.emit(false, 0, 0)) # Выход
	
	# Подключить кнопки ставок
	for btn in bets_hbox.get_children():
		if btn is Button:
			btn.pressed.connect(_on_bet_pressed.bind(btn))
			
	if %BegButton:
		%BegButton.pressed.connect(_on_beg_pressed)
	if %StealButton:
		%StealButton.pressed.connect(_on_steal_pressed)
	if %BossContinueButton:
		%BossContinueButton.pressed.connect(_on_boss_continue_pressed)
	if %RestartButton:
		%RestartButton.pressed.connect(_on_restart_pressed)
	
	_set_danila_emotion(TEX_DANI_NEUTRAL)
	_set_worker_emotion(tex_worker_neutral)
	
	# Показать интро
	%IntroOverlay.visible = true
	betting_overlay.visible = false
	
# ... (rest of the file until _on_beg_pressed)

func _on_beg_pressed():
	# Trigger Boss Warning instead of immediate money
	%BossOverlay.visible = true
	var boss_tex = load("res://Characters/boss_of_factory/boss_of_factory_suspicious.png")
	%BossOverlay/BossSprite.texture = boss_tex
	%BossOverlay/BossText.text = "ЕЩЕ АВАНС? ЭТО КРАЙНИЙ РАЗ! (%d/%d)" % [loans_taken + 1, MAX_LOANS]
	%BossContinueButton.visible = true

func _on_boss_continue_pressed():
	%BossOverlay.visible = false
	loans_taken += 1
	GameGlobal.add_money(30)
	status_label.text = "Босс дал аванс, но он недоволен..."
	_set_danila_emotion(TEX_DANI_SORRY)
	start_betting_phase()

func _on_steal_pressed():
	# Trigger angry boss instantly
	_show_boss_game_over()

func _on_intro_start_pressed():
	%IntroOverlay.visible = false
	start_betting_phase()

func _load_worker_assets():
	if ResourceLoader.exists(WORKER_PATH + "worker_neutral.png"):
		tex_worker_neutral = load(WORKER_PATH + "worker_neutral.png")
	if ResourceLoader.exists(WORKER_PATH + "worker_happy.png"):
		tex_worker_happy = load(WORKER_PATH + "worker_happy.png")
	if ResourceLoader.exists(WORKER_PATH + "worker_angry.png"):
		tex_worker_angry = load(WORKER_PATH + "worker_angry.png")
	if ResourceLoader.exists(WORKER_PATH + "worker_smug.png"):
		tex_worker_smug = load(WORKER_PATH + "worker_smug.png")

func _setup_audio():
	card_sound = AudioStreamPlayer.new()
	card_sound.name = "CardSound"
	add_child(card_sound)
	if ResourceLoader.exists("res://boardgamePackAsset/Bonus/cardPlace1.ogg"):
		card_sound.stream = load("res://boardgamePackAsset/Bonus/cardPlace1.ogg")

func start_betting_phase():
	game_state = "betting"
	current_bet = 0
	player_match_wins = 0
	dealer_match_wins = 0
	_update_money_ui()
	_update_match_score_ui()
	
	betting_overlay.visible = true
	betting_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(betting_overlay, "modulate:a", 1.0, 0.3)
	
	%InternalBalanceLabel.text = "ВАШ БАЛАНС: %d$" % GameGlobal.player_money
	
	hit_button.visible = false
	stand_button.visible = false
	new_game_button.visible = false
	next_round_button.visible = false
	
	# Bankruptcy Check
	if GameGlobal.player_money < 10:
		%BetsHBox.visible = false
		
		# If we have loans left, show Beg button.
		if loans_taken < MAX_LOANS:
			%BegButton.visible = true
			%StealButton.visible = false
			status_label.text = "У вас нет денег..."
			%InternalBalanceLabel.text = "ДЕНЕГ НЕТ!"
			_set_danila_emotion(TEX_DANI_SORRY)
			_set_worker_emotion(tex_worker_smug)
		
		# If no loans left, show Steal button.
		else:
			%BegButton.visible = false
			%StealButton.visible = true
			status_label.text = "Кредит исчерпан. Но есть вариант..."
			%InternalBalanceLabel.text = "ВЫ БАНКРОТ"
			_set_danila_emotion(TEX_DANI_SHOCKED)
			_set_worker_emotion(tex_worker_happy)

	else:
		%BegButton.visible = false
		%StealButton.visible = false
		%BetsHBox.visible = true
		status_label.text = "Сделайте вашу ставку на матч..."
		_update_bet_buttons()
		_set_worker_emotion(tex_worker_smug)

# Update _show_boss_game_over
func _show_boss_game_over():
	%BegButton.visible = false
	%StealButton.visible = false
	status_label.text = ""
	%BossOverlay.visible = true
	%BossContinueButton.visible = false
	%GameOverLabel.visible = false
	%RestartButton.visible = false
	
	var boss_tex = load("res://Characters/boss_of_factory/boss_of_factory_angry.png")
	%BossOverlay/BossSprite.texture = boss_tex
	%BossOverlay/BossText.text = "ТЫ ЧТО ТВОРИШЬ?! Я ВИЖУ ВСЁ!! ВОР!! \nУВОЛЕН!!!"
	
	# Glitch Effect
	var mat = %BossOverlay/BossSprite.material as ShaderMaterial
	if mat:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(mat, "shader_parameter/shake_power", 0.1, 0.5).set_trans(Tween.TRANS_BOUNCE) # More intense
		tween.tween_property(mat, "shader_parameter/color_rate", 0.05, 1.0)
	
	# Camera Zoom & Shake
	var cam = $Camera2D
	if cam:
		# Center camera on screen for the effect
		cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
		cam.position = get_viewport_rect().size / 2
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(cam, "zoom", Vector2(1.2, 1.2), 3.0).set_trans(Tween.TRANS_SINE) # Slow zoom in
		# Simple shake loop simulation
		for i in range(20):
			var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
			tween.tween_property(cam, "offset", offset, 0.05)
		tween.tween_property(cam, "offset", Vector2.ZERO, 0.1)

	# Show Game Over UI
	await get_tree().create_timer(4.0).timeout
	%BossOverlay/BossText.visible = false
	%GameOverLabel.visible = true
	%RestartButton.visible = true

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://Main.tscn")

func _update_bet_buttons():
	var balance = GameGlobal.player_money
	for btn in bets_hbox.get_children():
		var amount = 0
		var txt = btn.text
		
		# Strict check order or exact match to avoid "10" matching "100"
		if "100" in txt: amount = 100
		elif "50" in txt: amount = 50
		elif "10" in txt: amount = 10
		elif "BANK" in txt: amount = balance
		
		if "BANK" in txt:
			btn.disabled = (balance <= 0)
		else:
			btn.disabled = (amount > balance)

func _on_bet_pressed(btn: Button):
	var amount = 0
	var txt = btn.text
	
	if "100" in txt: amount = 100
	elif "50" in txt: amount = 50
	elif "10" in txt: amount = 10
	elif "BANK" in txt: amount = GameGlobal.player_money
	
	if amount > 0 and GameGlobal.remove_money(amount):
		current_bet = amount
		_start_first_round_of_match()



func _start_first_round_of_match():
	# Скрыть ставки
	var tween = create_tween()
	tween.tween_property(betting_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): betting_overlay.visible = false)
	
	_update_money_ui()
	_start_next_round()

func _start_next_round():
	# Сброс стола
	player_hand.clear()
	dealer_hand.clear()
	_clear_hand_containers()
	_create_deck()
	_shuffle_deck()
	
	game_state = "playing"
	player_score = 0
	dealer_score = 0
	
	_set_danila_emotion(TEX_DANI_NEUTRAL)
	_set_worker_emotion(tex_worker_neutral)
	
	# Скрыть кнопку след раунда
	next_round_button.visible = false
	new_game_button.visible = false
	
	# Раздача
	await get_tree().create_timer(0.3).timeout
	deal_initial_cards()
	_update_ui()
	
	hit_button.visible = true
	hit_button.disabled = false
	stand_button.visible = true
	stand_button.disabled = false
	status_label.text = "Новый раунд! Побед нужно: %d" % WINS_NEEDED

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
	return card

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
	
	if game_state == "playing":
		if player_score > 18:
			_set_danila_emotion(TEX_DANI_SORRY)
			_set_worker_emotion(tex_worker_smug)
		elif player_score == 21:
			_set_danila_emotion(TEX_DANI_HAPPY)
			_set_worker_emotion(tex_worker_angry)
		else:
			_set_danila_emotion(TEX_DANI_NEUTRAL)
			_set_worker_emotion(tex_worker_neutral)

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
	if not danila_portrait or danila_portrait.texture == texture: return
	_animate_portrait_change(danila_portrait, texture)

func _set_worker_emotion(texture: Texture2D):
	if not worker_portrait or worker_portrait.texture == texture or not texture: return
	_animate_portrait_change(worker_portrait, texture)

func _animate_portrait_change(rect: TextureRect, texture: Texture2D):
	var tween = create_tween()
	tween.tween_property(rect, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_callback(func(): rect.texture = texture)
	tween.tween_property(rect, "scale", Vector2(1.0, 1.0), 0.1)

func _display_card(card: Card, container: HBoxContainer):
	var card_control = Control.new()
	card_control.custom_minimum_size = Vector2(100, 140)
	
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
	
	var tex_path = card.get_texture_path()
	if ResourceLoader.exists(tex_path):
		tex_rect.texture = load(tex_path)
	else:
		var color = ColorRect.new()
		color.size = Vector2(100, 140)
		color.color = Color.WHITE if card.face_up else Color.NAVY_BLUE
		card_control.add_child(color)
	
	if tex_rect.texture:
		card_control.add_child(tex_rect)

	container.add_child(card_control)
	
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
	_update_money_ui()
	_update_match_score_ui()
	
	player_score_label.text = "Вы: %d" % player_score
	if player_score > 21:
		player_score_label.modulate = Color.RED
		player_score_label.text += " (ПЕРЕБОР)"
	elif player_score == 21:
		player_score_label.modulate = Color.GREEN
		player_score_label.text += " (MAX)"
	else:
		player_score_label.modulate = Color.WHITE
	
	if game_state == "betting":
		dealer_score_label.text = ""
	elif game_state != "playing":
		dealer_score_label.text = "Рабочий: %d" % dealer_score
		if dealer_score > 21: dealer_score_label.text += " (ПЕРЕБОР)"
	else:
		dealer_score_label.text = "Рабочий: ?"

func _update_money_ui():
	balance_label.text = "Баланс: %d$" % GameGlobal.player_money
	current_bet_label.text = "Ставка: %d$" % current_bet

func _update_match_score_ui():
	match_score_label.text = "СЧЕТ МАТЧА: %d - %d" % [player_match_wins, dealer_match_wins]

func _on_hit_pressed():
	if game_state != "playing": return
	hit_button.disabled = true
	
	var card = deal_card_to_player()
	_update_scores()
	_update_ui()
	
	await get_tree().create_timer(0.3).timeout
	
	if player_score > 21:
		_process_round_result("player_bust")
	else:
		hit_button.disabled = false

func _on_stand_pressed():
	if game_state != "playing": return
	
	hit_button.disabled = true
	stand_button.disabled = true
	
	# Открыть карты
	for c in dealer_hand: c.face_up = true
	_redraw_field()
	_update_scores()
	_update_ui()
	
	while dealer_score <= 21:
		var must_hit = false
		if dealer_score < 17: must_hit = true
		if dealer_score < player_score and dealer_score < 21: must_hit = true
			
		if not must_hit: break
			
		_set_worker_emotion(tex_worker_smug)
		await get_tree().create_timer(1.0).timeout
		var card = deal_card_to_dealer()
		card.face_up = true
		_update_scores()
		_redraw_field()
		_play_card_sound()
		_update_ui()
	
	# Определение результата раунда
	if dealer_score > 21:
		_process_round_result("dealer_bust")
	elif player_score > dealer_score:
		_process_round_result("player_won")
	elif dealer_score > player_score:
		_process_round_result("dealer_won")
	else:
		_process_round_result("tie")

func _process_round_result(result_code: String):
	game_state = "round_ended"
	var round_winner = "none"
	
	match result_code:
		"player_bust":
			round_winner = "dealer"
			status_label.text = "ПЕРЕБОР! Раунд за Рабочим."
		"dealer_bust":
			round_winner = "player"
			status_label.text = "РАБОЧИЙ ПЕРЕБРАЛ! Раунд за Вами."
		"player_won":
			round_winner = "player"
			status_label.text = "У вас больше! Раунд за Вами."
		"dealer_won":
			round_winner = "dealer"
			status_label.text = "У Рабочего больше. Раунд за ним."
		"tie":
			status_label.text = "Ничья в раунде."
	
	if round_winner == "player":
		player_match_wins += 1
		_set_danila_emotion(TEX_DANI_HAPPY)
		_set_worker_emotion(tex_worker_angry)
	elif round_winner == "dealer":
		dealer_match_wins += 1
		_set_danila_emotion(TEX_DANI_SORRY)
		_set_worker_emotion(tex_worker_happy)
	else:
		_set_danila_emotion(TEX_DANI_NEUTRAL)
		_set_worker_emotion(tex_worker_neutral)
		
	_update_match_score_ui()
	_end_round_ui_state()
	
	# Проверка победы в матче
	if player_match_wins >= WINS_NEEDED:
		await get_tree().create_timer(1.0).timeout
		_finish_match(true)
	elif dealer_match_wins >= WINS_NEEDED:
		await get_tree().create_timer(1.0).timeout
		_finish_match(false)

func _finish_match(player_won_match: bool):
	game_state = "match_ended"
	hit_button.visible = false
	stand_button.visible = false
	next_round_button.visible = false
	new_game_button.visible = true
	
	if player_won_match:
		status_label.text = "ПОБЕДА В МАТЧЕ! ВЫ ЗАБИРАЕТЕ КУШ!"
		GameGlobal.add_money(current_bet * 2)
		_set_danila_emotion(TEX_DANI_HAPPY)
		_set_worker_emotion(tex_worker_angry)
	else:
		status_label.text = "ПОРАЖЕНИЕ В МАТЧЕ. ДЕНЬГИ УШЛИ."
		_set_danila_emotion(TEX_DANI_SAD)
		_set_worker_emotion(tex_worker_smug)
	
	_update_money_ui()

func _end_round_ui_state():
	hit_button.visible = false
	stand_button.visible = false
	if game_state == "round_ended":
		next_round_button.visible = true

func _redraw_field():
	_clear_hand_containers()
	for c in player_hand: _display_card(c, player_hand_container)
	for c in dealer_hand: _display_card(c, dealer_hand_container)

func _on_new_game_pressed():
	start_betting_phase()

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
	# Screen shake implementation
	pass
