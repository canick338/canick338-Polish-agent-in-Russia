extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var close_btn: Button = %CloseButton
@onready var apps_grid: GridContainer = %AppsContainer
@onready var content_area: Control = %ContentArea
@onready var header_label: Label = %HeaderLabel
@onready var back_btn: Button = %BackButton

var _current_app: String = ""

func _ready() -> void:
	close_btn.pressed.connect(hide_phone)
	if back_btn:
		back_btn.pressed.connect(_go_home)
		back_btn.visible = false
	
	# Slide in
	panel.position.y = 1080
	var tw = create_tween()
	tw.tween_property(panel, "position:y", 100, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	_build_home_screen()

func toggle() -> void:
	if visible:
		hide_phone()
	else:
		show()
		panel.position.y = 1080
		var tw = create_tween()
		tw.tween_property(panel, "position:y", 100, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		_build_home_screen()

func hide_phone() -> void:
	var tw = create_tween()
	tw.tween_property(panel, "position:y", 1080, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_callback(hide)

func _go_home() -> void:
	_current_app = ""
	_build_home_screen()

func _build_home_screen() -> void:
	_current_app = ""
	if back_btn: back_btn.visible = false
	
	# Update header with time
	var day = Variables.get_variable("current_day")
	if day == 0: day = 1
	var time_names = ["🌅 Утро", "☀️ День", "🌇 Вечер", "🌙 Ночь"]
	var time_idx = Variables.get_variable("current_time")
	if time_idx < 0 or time_idx > 3: time_idx = 0
	if header_label:
		header_label.text = time_names[time_idx]
	
	# Clear content area
	_clear_content()
	
	# Build app grid
	if apps_grid:
		for child in apps_grid.get_children():
			child.queue_free()
		
		_add_app_button("📬", "Уведомления", "_open_notifications")
		_add_app_button("🏦", "PKO Bank", "_open_bank")
		_add_app_button("🏛️", "ePUAP", "_open_gov_services")
		_add_app_button("🛒", "Шломо", "_open_shop")

func _add_app_button(icon: String, label_text: String, callback: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn = Button.new()
	btn.text = icon
	btn.add_theme_font_size_override("font_size", 36)
	btn.custom_minimum_size = Vector2(90, 90)
	btn.pressed.connect(Callable(self, callback))
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	
	vbox.add_child(btn)
	vbox.add_child(lbl)
	apps_grid.add_child(vbox)

func _clear_content() -> void:
	if not content_area: return
	for child in content_area.get_children():
		child.queue_free()

func _show_app_header(title: String) -> void:
	_current_app = title
	if header_label: header_label.text = title
	if back_btn: back_btn.visible = true
	if apps_grid:
		for child in apps_grid.get_children():
			child.queue_free()

# ========================
# 📬 NOTIFICATIONS APP
# ========================
func _open_notifications() -> void:
	_show_app_header("📬 Уведомления")
	_clear_content()
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	
	# Generate notifications based on game state
	var notifications: Array = []
	
	if Variables.get_variable("warsaw_prologue_stage") != 1:
		notifications.append({"icon": "🏙️", "text": "Исследуй Улицы Варшавы, чтобы начать."})
	
	if Variables.get_variable("prologue_act_2_done") == 1 and Variables.get_variable("prologue_act_3_done") != 1:
		notifications.append({"icon": "🏛️", "text": "Явитесь в Офис Главы Разведки для получения задания."})
	
	var days_left = Variables.get_variable("days_left", -1)
	if days_left >= 1:
		notifications.append({"icon": "⚠️", "text": "Деньги украдены! Осталось %d дней до вылета." % days_left})
	elif days_left == 0 and Variables.get_variable("warsaw_ticket_bought") != 1:
		notifications.append({"icon": "🔴", "text": "ВРЕМЯ ВЫШЛО! Миссия провалена."})
	
	var money = Variables.get_variable("money", 0)
	if money >= 500 and Variables.get_variable("warsaw_ticket_bought") != 1:
		notifications.append({"icon": "💰", "text": "У вас достаточно денег (%d zł). Идите к Шломо за билетом!" % money})
	
	if Variables.get_variable("warsaw_ticket_bought") == 1 and Variables.get_variable("prologue_intro_done") != 1:
		notifications.append({"icon": "✅", "text": "Билет куплен! Идите домой и ложитесь спать."})
	
	if notifications.is_empty():
		notifications.append({"icon": "💤", "text": "Нет новых уведомлений."})
	
	for notif in notifications:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		var icon_lbl = Label.new()
		icon_lbl.text = notif["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 24)
		
		var text_lbl = Label.new()
		text_lbl.text = notif["text"]
		text_lbl.add_theme_font_size_override("font_size", 16)
		text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		hbox.add_child(icon_lbl)
		hbox.add_child(text_lbl)
		vbox.add_child(hbox)
	
	scroll.add_child(vbox)
	content_area.add_child(scroll)

# ========================
# 🏦 PKO BANK APP
# ========================
func _open_bank() -> void:
	_show_app_header("🏦 PKO Bank Polski")
	_clear_content()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Balance card
	var balance_panel = PanelContainer.new()
	var balance_style = StyleBoxFlat.new()
	balance_style.bg_color = Color(0.0, 0.25, 0.5, 0.8)
	balance_style.corner_radius_top_left = 16
	balance_style.corner_radius_top_right = 16
	balance_style.corner_radius_bottom_left = 16
	balance_style.corner_radius_bottom_right = 16
	balance_style.content_margin_left = 20
	balance_style.content_margin_right = 20
	balance_style.content_margin_top = 20
	balance_style.content_margin_bottom = 20
	balance_panel.add_theme_stylebox_override("panel", balance_style)
	
	var balance_vbox = VBoxContainer.new()
	balance_vbox.add_theme_constant_override("separation", 8)
	
	var account_lbl = Label.new()
	account_lbl.text = "Konto osobiste"
	account_lbl.add_theme_font_size_override("font_size", 16)
	account_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	
	var money = Variables.get_variable("money", 0)
	var amount_lbl = Label.new()
	amount_lbl.text = "%d,00 PLN" % money
	amount_lbl.add_theme_font_size_override("font_size", 36)
	amount_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var card_lbl = Label.new()
	card_lbl.text = "Karta: **** **** **** 4721"
	card_lbl.add_theme_font_size_override("font_size", 14)
	card_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	
	balance_vbox.add_child(account_lbl)
	balance_vbox.add_child(amount_lbl)
	balance_vbox.add_child(card_lbl)
	balance_panel.add_child(balance_vbox)
	vbox.add_child(balance_panel)
	
	# Transaction history
	var history_lbl = Label.new()
	history_lbl.text = "Historia operacji"
	history_lbl.add_theme_font_size_override("font_size", 18)
	history_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	vbox.add_child(history_lbl)
	
	var transactions = [
		{"desc": "Wypłata — Fabryka Obłomowa", "amount": "+80,00 PLN", "color": Color(0.3, 0.9, 0.3)},
		{"desc": "Pizzeria U Mario", "amount": "+60,00 PLN", "color": Color(0.3, 0.9, 0.3)},
		{"desc": "Sklep — Napój energetyczny", "amount": "-20,00 PLN", "color": Color(0.9, 0.3, 0.3)},
	]
	
	for tx in transactions:
		var tx_hbox = HBoxContainer.new()
		var tx_desc = Label.new()
		tx_desc.text = tx["desc"]
		tx_desc.add_theme_font_size_override("font_size", 14)
		tx_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var tx_amount = Label.new()
		tx_amount.text = tx["amount"]
		tx_amount.add_theme_font_size_override("font_size", 14)
		tx_amount.add_theme_color_override("font_color", tx["color"])
		
		tx_hbox.add_child(tx_desc)
		tx_hbox.add_child(tx_amount)
		vbox.add_child(tx_hbox)
	
	content_area.add_child(vbox)

# ========================
# 🏛️ ePUAP (GOV SERVICES)
# ========================
func _open_gov_services() -> void:
	_show_app_header("🏛️ ePUAP — Usługi publiczne")
	_clear_content()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Welcome
	var welcome = Label.new()
	welcome.text = "Witaj, Danila Markowski"
	welcome.add_theme_font_size_override("font_size", 20)
	welcome.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(welcome)
	
	# Status cards
	var services = [
		{"icon": "📋", "title": "Status meldunkowy", "status": "Zameldowany: Warszawa, ul. Praga 14/3"},
		{"icon": "🪪", "title": "Dowód osobisty", "status": "Ważny do: 2028-03-15"},
		{"icon": "🏥", "title": "Ubezpieczenie zdrowotne", "status": "NFZ — aktywne"},
		{"icon": "📊", "title": "Rozliczenie PIT", "status": "PIT-37 złożony za 2024 r."},
	]
	
	for svc in services:
		var svc_panel = PanelContainer.new()
		var svc_style = StyleBoxFlat.new()
		svc_style.bg_color = Color(0.12, 0.15, 0.22, 0.9)
		svc_style.corner_radius_top_left = 10
		svc_style.corner_radius_top_right = 10
		svc_style.corner_radius_bottom_left = 10
		svc_style.corner_radius_bottom_right = 10
		svc_style.content_margin_left = 14
		svc_style.content_margin_right = 14
		svc_style.content_margin_top = 10
		svc_style.content_margin_bottom = 10
		svc_panel.add_theme_stylebox_override("panel", svc_style)
		
		var svc_hbox = HBoxContainer.new()
		svc_hbox.add_theme_constant_override("separation", 12)
		
		var icon_lbl = Label.new()
		icon_lbl.text = svc["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 28)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title_lbl = Label.new()
		title_lbl.text = svc["title"]
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		
		var status_lbl = Label.new()
		status_lbl.text = svc["status"]
		status_lbl.add_theme_font_size_override("font_size", 13)
		status_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.7))
		status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		info_vbox.add_child(title_lbl)
		info_vbox.add_child(status_lbl)
		svc_hbox.add_child(icon_lbl)
		svc_hbox.add_child(info_vbox)
		svc_panel.add_child(svc_hbox)
		vbox.add_child(svc_panel)
	
	content_area.add_child(vbox)

# ========================
# 🛒 SHLOMO SHOP APP
# ========================
func _open_shop() -> void:
	_show_app_header("🛒 Лавка Шломо")
	_clear_content()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var intro = Label.new()
	intro.text = "Каталог товаров Шломо. Для покупки — приходите лично."
	intro.add_theme_font_size_override("font_size", 15)
	intro.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(intro)
	
	var items = [
		{"name": "🎫 Билет + документы", "price": "500 zł", "desc": "Поддельный паспорт и билет на поезд до Обояни."},
		{"name": "⚡ Энергетик", "price": "20 zł", "desc": "Придаёт бодрости на весь день."},
		{"name": "🥪 Сэндвич", "price": "10 zł", "desc": "Утоляет голод."},
	]
	
	for item in items:
		var item_panel = PanelContainer.new()
		var item_style = StyleBoxFlat.new()
		item_style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
		item_style.corner_radius_top_left = 10
		item_style.corner_radius_top_right = 10
		item_style.corner_radius_bottom_left = 10
		item_style.corner_radius_bottom_right = 10
		item_style.content_margin_left = 14
		item_style.content_margin_right = 14
		item_style.content_margin_top = 10
		item_style.content_margin_bottom = 10
		item_panel.add_theme_stylebox_override("panel", item_style)
		
		var item_vbox = VBoxContainer.new()
		item_vbox.add_theme_constant_override("separation", 4)
		
		var top_hbox = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = item["name"]
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var price_lbl = Label.new()
		price_lbl.text = item["price"]
		price_lbl.add_theme_font_size_override("font_size", 18)
		price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		
		top_hbox.add_child(name_lbl)
		top_hbox.add_child(price_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = item["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		item_vbox.add_child(top_hbox)
		item_vbox.add_child(desc_lbl)
		item_panel.add_child(item_vbox)
		vbox.add_child(item_panel)
	
	content_area.add_child(vbox)
