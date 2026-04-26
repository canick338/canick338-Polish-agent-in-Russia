extends CanvasLayer

@onready var panel: Panel = $BezelPanel
@onready var close_btn: Button = %CloseButton
@onready var apps_grid: GridContainer = %AppsContainer
@onready var dock_grid: GridContainer = %DockGrid
@onready var content_area: Control = %ContentArea
@onready var header_label: Label = %HeaderLabel
@onready var back_btn: Button = %BackButton
@onready var right_spacer: Control = %RightSpacer

var _current_app: String = ""

func _ready() -> void:
	close_btn.pressed.connect(hide_phone)
	if back_btn:
		back_btn.pressed.connect(_go_home)
		back_btn.visible = false
	# Slide in
	panel.position.y = 1080
	var tw = create_tween()
	tw.tween_property(panel, "position:y", 180, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	_build_home_screen()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if panel.position.y < 500: # only if it's fully or mostly on screen
			hide_phone()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if visible:
		hide_phone()
	else:
		show()
		panel.position.y = 1080
		var tw = create_tween()
		tw.tween_property(panel, "position:y", 180, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		_build_home_screen()

func hide_phone() -> void:
	var tw = create_tween()
	tw.tween_property(panel, "position:y", 1080, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_callback(hide)

func _go_home() -> void:
	_current_app = ""
	_build_home_screen()

# Live clock refresh
var _clock_refresh_timer: float = 0.0
func _process(delta: float) -> void:
	_clock_refresh_timer += delta
	if _clock_refresh_timer >= 1.0:
		_clock_refresh_timer = 0.0
		_refresh_phone_clock()

func _refresh_phone_clock() -> void:
	if not visible or not header_label: return
	if _current_app != "": return
	var time_icons = ["🌅", "☀️", "🌇", "🌙"]
	var time_idx = int(Variables.get_variable("current_time", 0))
	if time_idx < 0 or time_idx > 3: time_idx = 0
	
	# Статичные часы для каждого периода (action-based, время не тикает)
	var period_hours = ["07:30", "13:00", "19:45", "23:30"]
	header_label.text = "%s %s" % [time_icons[time_idx], period_hours[time_idx]]

func _build_home_screen() -> void:
	_current_app = ""
	if back_btn: back_btn.visible = false
	if right_spacer: right_spacer.visible = false
	
	# Update header with time
	var day = Variables.get_variable("current_day")
	if day == 0: day = 1
	var time_clocks = ["06:30", "12:00", "19:45", "23:30"]
	var time_icons = ["🌅", "☀️", "🌇", "🌙"]
	var time_names_ru = ["Утро", "День", "Вечер", "Ночь"]
	var time_idx = Variables.get_variable("current_time")
	if time_idx < 0 or time_idx > 3: time_idx = 0
	if header_label:
		header_label.text = time_icons[time_idx] + " " + time_clocks[time_idx]
	
	# Clear content area
	_clear_content()
	
	# Build app grid
	if apps_grid:
		for child in apps_grid.get_children():
			child.queue_free()
	if dock_grid:
		for child in dock_grid.get_children():
			child.queue_free()
		
	# Add apps to home screen (4 columns, 1 row)
	if apps_grid:
		apps_grid.columns = 4
		_add_app_button("res://Assets/Textures/Phone/icon_shop.png", "Магазин", "_open_shop", apps_grid)
		_add_app_button("res://Assets/Textures/Phone/icon_mail.png", "Миссии", "_open_missions", apps_grid)
		_add_app_button("res://Assets/Textures/Phone/icon_gallery.png", "Галерея", "_open_gallery", apps_grid)
		_add_app_button("res://Assets/Textures/Phone/icon_games.png", "Игры", "_open_games", apps_grid)
	
	# Add apps to the bottom dock (4 columns)
	if dock_grid:
		_add_app_button("res://Assets/Textures/Phone/icon_mail.png", "Инфо", "_open_notifications", dock_grid)
		_add_app_button("res://Assets/Textures/Phone/icon_bank.png", "Bank", "_open_bank", dock_grid)
		_add_app_button("res://Assets/Textures/Phone/icon_gov.png", "ePUAP", "_open_gov_services", dock_grid)
		_add_app_button("res://Assets/Textures/Phone/icon_radio.png", "Радио", "_open_radio", dock_grid)

func _add_app_button(icon_path: String, label_text: String, callback: String, parent_node: Node) -> void:
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 5)
	
	var btn = TextureButton.new()
	btn.texture_normal = load(icon_path)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = Vector2(90, 90)
	btn.pressed.connect(Callable(self, callback))
	
	# Hover scaling effect
	btn.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "custom_minimum_size", Vector2(95, 95), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "custom_minimum_size", Vector2(90, 90), 0.1)
	)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	
	vbox.add_child(btn)
	vbox.add_child(lbl)
	if parent_node:
		parent_node.add_child(vbox)

func _clear_content() -> void:
	if not content_area: return
	for child in content_area.get_children():
		child.queue_free()

func _show_app_header(title: String) -> void:
	_current_app = title
	if header_label: header_label.text = title
	if back_btn: back_btn.visible = true
	if right_spacer: right_spacer.visible = true
	if apps_grid:
		for child in apps_grid.get_children():
			child.queue_free()

# ========================
# GALLERY APP
# ========================
var _gallery_current_category := "Все"

func _open_gallery() -> void:
	_show_app_header("Галерея")
	_clear_content()
	
	var gallery_data = GameGlobal.get_gallery_data()
	# ТЕСТ: Временно все фото открыты
	var unlocked = gallery_data.keys()
	
	var categories := ["Все"]
	for photo_id in gallery_data:
		var cat = gallery_data[photo_id].get("category", "Другое")
		if cat not in categories:
			categories.append(cat)
	
	var outer_scroll = ScrollContainer.new()
	outer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	outer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	
	# === Banner ===
	var banner = PanelContainer.new()
	banner.custom_minimum_size = Vector2(0, 100)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.12, 0.1, 0.2, 0.95)
	bs.corner_radius_top_left = 12
	bs.corner_radius_top_right = 12
	bs.corner_radius_bottom_left = 12
	bs.corner_radius_bottom_right = 12
	banner.add_theme_stylebox_override("panel", bs)
	var btex = TextureRect.new()
	btex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	btex.custom_minimum_size = Vector2(0, 100)
	if ResourceLoader.exists("res://danilassets/characters/Daniel/testart.png"):
		btex.texture = load("res://danilassets/characters/Daniel/testart.png")
	btex.modulate = Color(1, 1, 1, 0.3)
	banner.add_child(btex)
	var bov = VBoxContainer.new()
	bov.anchors_preset = Control.PRESET_FULL_RECT
	bov.alignment = BoxContainer.ALIGNMENT_CENTER
	var bt = Label.new()
	bt.text = "Фотоальбом агента"
	bt.add_theme_font_size_override("font_size", 17)
	bt.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	bt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	bt.add_theme_constant_override("shadow_offset_y", 2)
	bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bov.add_child(bt)
	var bst = Label.new()
	bst.text = "Собрано %d из %d" % [unlocked.size(), gallery_data.size()]
	bst.add_theme_font_size_override("font_size", 12)
	bst.add_theme_color_override("font_color", Color(0.7, 0.65, 0.9))
	bst.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	bst.add_theme_constant_override("shadow_offset_y", 1)
	bst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bov.add_child(bst)
	banner.add_child(bov)
	main_vbox.add_child(banner)
	
	# === Category tabs ===
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for cat in categories:
		var tb = Button.new()
		tb.text = cat
		tb.custom_minimum_size = Vector2(0, 28)
		tb.add_theme_font_size_override("font_size", 12)
		var ts = StyleBoxFlat.new()
		ts.corner_radius_top_left = 14
		ts.corner_radius_top_right = 14
		ts.corner_radius_bottom_left = 14
		ts.corner_radius_bottom_right = 14
		ts.content_margin_left = 12
		ts.content_margin_right = 12
		ts.bg_color = Color(0.42, 0.3, 0.9, 0.95) if cat == _gallery_current_category else Color(0.18, 0.18, 0.22, 0.7)
		tb.add_theme_stylebox_override("normal", ts)
		var hs = ts.duplicate()
		hs.bg_color = Color(0.5, 0.38, 1.0, 0.95)
		tb.add_theme_stylebox_override("hover", hs)
		tb.pressed.connect(func():
			_gallery_current_category = cat
			_open_gallery()
		)
		tabs.add_child(tb)
	main_vbox.add_child(tabs)
	
	# === Photo grid ===
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	
	for photo_id in gallery_data:
		var photo = gallery_data[photo_id]
		if _gallery_current_category != "Все" and photo.get("category", "") != _gallery_current_category:
			continue
		var is_unlocked = photo_id in unlocked
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 125)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs = StyleBoxFlat.new()
		cs.corner_radius_top_left = 10
		cs.corner_radius_top_right = 10
		cs.corner_radius_bottom_left = 10
		cs.corner_radius_bottom_right = 10
		if is_unlocked:
			cs.bg_color = Color(0.14, 0.13, 0.2, 0.9)
			cs.border_width_bottom = 2
			cs.border_color = Color(0.42, 0.3, 0.9, 0.6)
		else:
			cs.bg_color = Color(0.08, 0.08, 0.1, 0.85)
		card.add_theme_stylebox_override("panel", cs)
		
		var cv = VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		var tr = TextureRect.new()
		tr.custom_minimum_size = Vector2(0, 85)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if is_unlocked:
			var tp = photo.get("texture_path", "")
			if ResourceLoader.exists(tp):
				tr.texture = load(tp)
		else:
			tr.modulate = Color(0.1, 0.1, 0.12, 1)
		cv.add_child(tr)
		
		var tl = Label.new()
		tl.text = photo.get("title", "???") if is_unlocked else "[Закрыто]"
		tl.add_theme_font_size_override("font_size", 11)
		tl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95) if is_unlocked else Color(0.3, 0.28, 0.35))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cv.add_child(tl)
		
		var mg = MarginContainer.new()
		mg.add_theme_constant_override("margin_left", 4)
		mg.add_theme_constant_override("margin_right", 4)
		mg.add_theme_constant_override("margin_top", 4)
		mg.add_theme_constant_override("margin_bottom", 4)
		mg.add_child(cv)
		card.add_child(mg)
		
		if is_unlocked:
			var cb = Button.new()
			cb.flat = true
			cb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			cb.anchors_preset = Control.PRESET_FULL_RECT
			cb.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			cb.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
			cb.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
			cb.pressed.connect(func(): _open_photo_viewer(photo_id))
			card.add_child(cb)
		grid.add_child(card)
	
	main_vbox.add_child(grid)
	outer_scroll.add_child(main_vbox)
	content_area.add_child(outer_scroll)

func _open_photo_viewer(photo_id: String) -> void:
	"""Opens a fullscreen view of a single photo with description."""
	var gallery_data = GameGlobal.get_gallery_data()
	var photo = gallery_data.get(photo_id, {})
	if photo.is_empty(): return
	
	_show_app_header(photo.get("title", "???"))
	_clear_content()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	
	# Photo display
	var tex_rect = TextureRect.new()
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex_path = photo.get("texture_path", "")
	if ResourceLoader.exists(tex_path):
		tex_rect.texture = load(tex_path)
	vbox.add_child(tex_rect)
	
	# Info panel
	var info_panel = PanelContainer.new()
	var info_style = StyleBoxFlat.new()
	info_style.bg_color = Color(0.12, 0.11, 0.18, 0.95)
	info_style.corner_radius_top_left = 10
	info_style.corner_radius_top_right = 10
	info_style.corner_radius_bottom_left = 10
	info_style.corner_radius_bottom_right = 10
	info_panel.add_theme_stylebox_override("panel", info_style)
	
	var info_margin = MarginContainer.new()
	info_margin.add_theme_constant_override("margin_left", 12)
	info_margin.add_theme_constant_override("margin_right", 12)
	info_margin.add_theme_constant_override("margin_top", 8)
	info_margin.add_theme_constant_override("margin_bottom", 10)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	
	var title_lbl = Label.new()
	title_lbl.text = photo.get("title", "")
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 1.0))
	info_vbox.add_child(title_lbl)
	
	var cat_lbl = Label.new()
	cat_lbl.text = photo.get("category", "")
	cat_lbl.add_theme_font_size_override("font_size", 11)
	cat_lbl.add_theme_color_override("font_color", Color(0.5, 0.45, 0.75))
	info_vbox.add_child(cat_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = photo.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.75))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_lbl)
	
	info_margin.add_child(info_vbox)
	info_panel.add_child(info_margin)
	vbox.add_child(info_panel)
	
	# Back to gallery button
	var back_gallery_btn = Button.new()
	back_gallery_btn.text = "← Назад к галерее"
	back_gallery_btn.custom_minimum_size = Vector2(0, 36)
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.3, 0.25, 0.55, 0.8)
	back_style.corner_radius_top_left = 8
	back_style.corner_radius_top_right = 8
	back_style.corner_radius_bottom_left = 8
	back_style.corner_radius_bottom_right = 8
	back_gallery_btn.add_theme_stylebox_override("normal", back_style)
	back_gallery_btn.add_theme_font_size_override("font_size", 13)
	back_gallery_btn.pressed.connect(func(): _open_gallery())
	vbox.add_child(back_gallery_btn)
	
	content_area.add_child(vbox)

# ========================
# NOTIFICATIONS APP
# ========================
func _open_notifications() -> void:
	_show_app_header("Уведомления")
	_clear_content()
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	
	var notifications: Array = []
	
	if Variables.get_variable("warsaw_prologue_stage") != 1:
		notifications.append({"color": Color(0.2, 0.6, 1.0), "text": "Исследуй Улицы Варшавы, чтобы начать."})
	
	if Variables.get_variable("prologue_act_2_done") == 1 and Variables.get_variable("prologue_act_3_done") != 1:
		notifications.append({"color": Color(0.6, 0.3, 0.9), "text": "Явитесь в Офис Разведки для получения задания."})
	
	var days_left = Variables.get_variable("days_left", -1)
	if days_left >= 1:
		notifications.append({"color": Color(0.9, 0.7, 0.1), "text": "Внимание! Осталось %d дней до вылета." % days_left})
	elif days_left == 0 and Variables.get_variable("warsaw_ticket_bought") != 1:
		notifications.append({"color": Color(0.9, 0.2, 0.2), "text": "ВРЕМЯ ВЫШЛО! Миссия провалена."})
	
	var money = GameGlobal.player_money
	if money >= 500 and Variables.get_variable("warsaw_ticket_bought") != 1:
		notifications.append({"color": Color(0.2, 0.8, 0.3), "text": "Накоплено %d zł. Можно идти к Шломо за билетом." % money})
	
	if Variables.get_variable("warsaw_ticket_bought") == 1 and Variables.get_variable("prologue_intro_done") != 1:
		notifications.append({"color": Color(0.2, 0.8, 0.3), "text": "Билет куплен! Идите домой и ложитесь спать."})
	
	if notifications.is_empty():
		notifications.append({"color": Color(0.4, 0.4, 0.4), "text": "Новых уведомлений нет."})
	
	# Напоминание о сне ночью
	var time_idx = int(Variables.get_variable("current_time", 0))
	if time_idx == 3:
		notifications.insert(0, {"color": Color(0.3, 0.3, 0.9), "text": "🌙 Ночь. Всё закрыто! Иди домой и ложись спать."})
	
	# Счётчик дней
	var day = int(Variables.get_variable("current_day", 1))
	notifications.insert(0, {"color": Color(0.7, 0.7, 0.8), "text": "📅 День %d из 7" % day})
	
	for notif in notifications:
		var panel = PanelContainer.new()
		var pstyle = StyleBoxFlat.new()
		pstyle.bg_color = Color(0.12, 0.15, 0.22, 0.8)
		pstyle.corner_radius_top_left = 6
		pstyle.corner_radius_top_right = 6
		pstyle.corner_radius_bottom_left = 6
		pstyle.corner_radius_bottom_right = 6
		pstyle.content_margin_left = 15
		pstyle.content_margin_right = 15
		pstyle.content_margin_top = 12
		pstyle.content_margin_bottom = 12
		pstyle.border_width_left = 4
		pstyle.border_color = notif["color"]
		panel.add_theme_stylebox_override("panel", pstyle)
		
		var text_lbl = Label.new()
		text_lbl.text = notif["text"]
		text_lbl.add_theme_font_size_override("font_size", 14)
		text_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		panel.add_child(text_lbl)
		vbox.add_child(panel)
	
	scroll.add_child(vbox)
	content_area.add_child(scroll)

# ========================
# 📋 MISSIONS APP
# ========================
func _open_missions() -> void:
	_show_app_header("Миссии")
	_clear_content()
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	
	# === ГЛАВНАЯ ЦЕЛЬ ===
	var main_header = Label.new()
	main_header.text = "🎯 ГЛАВНАЯ ЦЕЛЬ"
	main_header.add_theme_font_size_override("font_size", 18)
	main_header.add_theme_color_override("font_color", Color(0.95, 0.3, 0.4))
	vbox.add_child(main_header)
	
	var main_quest := "Неизвестно"
	if Variables.get_variable("warsaw_prologue_stage") != 1:
		main_quest = "Выйти на улицы Варшавы"
	elif Variables.get_variable("prologue_act_2_done") != 1:
		main_quest = "Пройти обучение в Академии Разведки"
	elif Variables.get_variable("factory_done") != 1:
		main_quest = "Устроиться на Завод Обломова"
	elif Variables.get_variable("prologue_act_3_done") != 1:
		main_quest = "Явиться в Офис Разведки"
	elif Variables.get_variable("warsaw_ticket_bought") != 1:
		main_quest = "Заработать 500zł и купить билет у Шломо"
	elif Variables.get_variable("warsaw_prologue_done") != 1:
		main_quest = "Отправиться в Обоянь"
	elif Variables.get_variable("oboyan_act1_done") != 1:
		main_quest = "Прибыть в Обоянь и зарегистрироваться"
	elif Variables.get_variable("oboyan_act2_done") != 1:
		main_quest = "Войти в доверие к местным"
	else:
		main_quest = "Продолжить миссию в Обояни"
	
	_add_mission_card(vbox, main_quest, Color(0.95, 0.2, 0.3), true)
	
	# === РАЗВЕДДАННЫЕ ===
	var intel_header = Label.new()
	intel_header.text = "📂 РАЗВЕДДАННЫЕ"
	intel_header.add_theme_font_size_override("font_size", 16)
	intel_header.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	vbox.add_child(intel_header)
	
	var has_intel := false
	if Variables.get_variable("cafe_overheard_factory") == 1:
		_add_mission_card(vbox, "☕ Рабочие в кафе обсуждали подозрительные поставки на завод.", Color(0.3, 0.6, 0.9), false)
		has_intel = true
	if Variables.get_variable("bar_oblomov_hint") == 1:
		_add_mission_card(vbox, "🍺 Коллега видел Бронислава говорящим по-русски ночью.", Color(0.3, 0.6, 0.9), false)
		has_intel = true
	if Variables.get_variable("oblomov_secret_found") == 1:
		_add_mission_card(vbox, "📄 ДОКУМЕНТ: Карл Обломов — куратор Варшавской линии, контактное лицо Обоянского отделения.", Color(0.9, 0.2, 0.2), false)
		has_intel = true
	if not has_intel:
		_add_mission_card(vbox, "Пока ничего не найдено. Исследуй мир.", Color(0.4, 0.4, 0.4), false)
	
	# === СООБЩЕНИЯ ОТ ГЕНЕРАЛА ===
	var msg_header = Label.new()
	msg_header.text = "💬 СООБЩЕНИЯ"
	msg_header.add_theme_font_size_override("font_size", 16)
	msg_header.add_theme_color_override("font_color", Color(0.2, 0.8, 0.4))
	vbox.add_child(msg_header)
	
	if Variables.get_variable("prologue_act_2_done") == 1 and Variables.get_variable("prologue_act_3_done") != 1:
		_add_message_card(vbox, "Генерал Джонни", "Марек, не забудь явиться в офис после смены на заводе. Есть что обсудить.", "🎖️")
	if Variables.get_variable("prologue_act_3_done") == 1 and Variables.get_variable("warsaw_ticket_bought") != 1:
		_add_message_card(vbox, "Генерал Джонни", "Помни: 500zł и к Шломо! Время не ждёт, агент.", "🎖️")
	if Variables.get_variable("worker_trust") == 1:
		_add_message_card(vbox, "Рабочий с завода", "Привет, заходи в бар вечером. Есть разговор.", "👷")
	if Variables.get_variable("oboyan_act1_done") == 1:
		_add_message_card(vbox, "Генерал Джонни", "Марек, доклад по обстановке. Не высовывайся и не спеши. Разведка — это терпение.", "🎖️")
	
	scroll.add_child(vbox)
	content_area.add_child(scroll)

func _add_mission_card(parent: Control, text: String, color: Color, is_main: bool) -> void:
	var panel = PanelContainer.new()
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	pstyle.corner_radius_top_left = 8; pstyle.corner_radius_top_right = 8
	pstyle.corner_radius_bottom_left = 8; pstyle.corner_radius_bottom_right = 8
	pstyle.border_width_left = 5
	pstyle.border_color = color
	pstyle.content_margin_left = 14; pstyle.content_margin_right = 14
	pstyle.content_margin_top = 10; pstyle.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", pstyle)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15 if is_main else 13)
	lbl.add_theme_color_override("font_color", Color.WHITE if is_main else Color(0.8, 0.85, 0.9))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(lbl)
	parent.add_child(panel)

func _add_message_card(parent: Control, sender: String, text: String, icon: String) -> void:
	var panel = PanelContainer.new()
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.08, 0.15, 0.1, 0.9)
	pstyle.corner_radius_top_left = 10; pstyle.corner_radius_top_right = 10
	pstyle.corner_radius_bottom_left = 10; pstyle.corner_radius_bottom_right = 10
	pstyle.content_margin_left = 12; pstyle.content_margin_right = 12
	pstyle.content_margin_top = 8; pstyle.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", pstyle)
	
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	
	var sender_lbl = Label.new()
	sender_lbl.text = icon + " " + sender
	sender_lbl.add_theme_font_size_override("font_size", 14)
	sender_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	v.add_child(sender_lbl)
	
	var msg_lbl = Label.new()
	msg_lbl.text = text
	msg_lbl.add_theme_font_size_override("font_size", 13)
	msg_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.85))
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(msg_lbl)
	
	panel.add_child(v)
	parent.add_child(panel)

# ========================
# 🛒 SHOP APP (DELIVERY)
# ========================
func _open_shop() -> void:
	_show_app_header("Доставка Еды")
	_clear_content()
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	
	# Intro
	var lbl = Label.new()
	lbl.text = "Быстрая доставка еды и напитков.\n(Восстанавливает Сытость и Энергию)"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(lbl)
	
	_add_shop_item(vbox, "☕ Эспрессо", "Бодрит. Восстанавливает энергию.", 15, "energy")
	_add_shop_item(vbox, "🌯 Шаурма", "Пища богов. Восстанавливает всю сытость.", 25, "hunger")
	_add_shop_item(vbox, "🍱 Бизнес-ланч", "Восстанавливает всё.", 50, "both")
	
	scroll.add_child(vbox)
	content_area.add_child(scroll)

func _add_shop_item(parent: Control, item_name: String, desc: String, base_price: int, restore_type: String) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title = Label.new()
	title.text = item_name
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(title)
	
	var d_lbl = Label.new()
	d_lbl.text = desc
	d_lbl.add_theme_font_size_override("font_size", 12)
	d_lbl.add_theme_color_override("font_color", Color.GRAY)
	v.add_child(d_lbl)
	hbox.add_child(v)
	
	var buy_btn = Button.new()
	var final_price = GameGlobal.get_karma_price(base_price)
	buy_btn.text = "%d$" % final_price
	if final_price < base_price:
		buy_btn.add_theme_color_override("font_color", Color.GREEN) # Скидка от кармы
	elif final_price > base_price:
		buy_btn.add_theme_color_override("font_color", Color.RED) # Наценка от кармы
		
	buy_btn.custom_minimum_size = Vector2(80, 40)
	buy_btn.pressed.connect(func():
		if GameGlobal.purchase_with_karma(base_price):
			buy_btn.text = "Куплено"
			buy_btn.disabled = true
			if restore_type == "energy" or restore_type == "both":
				Variables.add_variable("energy", 100)
			if restore_type == "hunger" or restore_type == "both":
				Variables.add_variable("hunger", 100)
			
			if get_parent() and get_parent().has_method("_update_time_hud"):
				get_parent()._update_time_hud()
		else:
			buy_btn.text = "Нет $"
			var tw = create_tween()
			tw.tween_interval(1.0)
			tw.tween_callback(func(): buy_btn.text = "%d$" % final_price)
	)
	hbox.add_child(buy_btn)
	panel.add_child(hbox)
	parent.add_child(panel)

# ========================
# 🏦 PKO BANK APP
# ========================
func _open_bank() -> void:
	_show_app_header("PKO Bank Polski")
	_clear_content()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Balance card
	var balance_panel = PanelContainer.new()
	var balance_style = StyleBoxFlat.new()
	balance_style.bg_color = Color(0.05, 0.2, 0.4, 0.9)
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
	balance_vbox.add_theme_constant_override("separation", 10)
	
	var top_card_hbox = HBoxContainer.new()
	top_card_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var account_lbl = Label.new()
	account_lbl.text = "Личный счёт"
	account_lbl.add_theme_font_size_override("font_size", 16)
	account_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	account_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# MasterCart Logo
	var logo_hbox = HBoxContainer.new()
	logo_hbox.add_theme_constant_override("separation", -10)
	logo_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var red_circle = Panel.new()
	red_circle.custom_minimum_size = Vector2(24, 24)
	var rstyle = StyleBoxFlat.new()
	rstyle.bg_color = Color(0.9, 0.1, 0.1, 0.9)
	rstyle.corner_radius_top_left = 12
	rstyle.corner_radius_top_right = 12
	rstyle.corner_radius_bottom_left = 12
	rstyle.corner_radius_bottom_right = 12
	red_circle.add_theme_stylebox_override("panel", rstyle)
	
	var yellow_circle = Panel.new()
	yellow_circle.custom_minimum_size = Vector2(24, 24)
	var ystyle = StyleBoxFlat.new()
	ystyle.bg_color = Color(0.9, 0.7, 0.1, 0.9)
	ystyle.corner_radius_top_left = 12
	ystyle.corner_radius_top_right = 12
	ystyle.corner_radius_bottom_left = 12
	ystyle.corner_radius_bottom_right = 12
	yellow_circle.add_theme_stylebox_override("panel", ystyle)
	
	logo_hbox.add_child(red_circle)
	logo_hbox.add_child(yellow_circle)
	
	var logo_text = Label.new()
	logo_text.text = "MasterCart"
	logo_text.add_theme_font_size_override("font_size", 11)
	logo_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	var logo_vbox = VBoxContainer.new()
	logo_vbox.add_theme_constant_override("separation", 2)
	logo_vbox.alignment = BoxContainer.ALIGNMENT_END
	logo_vbox.add_child(logo_hbox)
	logo_vbox.add_child(logo_text)
	
	top_card_hbox.add_child(account_lbl)
	top_card_hbox.add_child(logo_vbox)
	
	var money = GameGlobal.player_money
	var amount_lbl = Label.new()
	amount_lbl.text = "%d,00 PLN" % money
	amount_lbl.add_theme_font_size_override("font_size", 36)
	amount_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var card_lbl = Label.new()
	card_lbl.text = "Карта: **** **** **** 4721"
	card_lbl.add_theme_font_size_override("font_size", 14)
	card_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	
	balance_vbox.add_child(top_card_hbox)
	balance_vbox.add_child(amount_lbl)
	balance_vbox.add_child(card_lbl)
	balance_panel.add_child(balance_vbox)
	vbox.add_child(balance_panel)
	
	# Transaction history
	var history_lbl = Label.new()
	history_lbl.text = "История операций"
	history_lbl.add_theme_font_size_override("font_size", 18)
	history_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	vbox.add_child(history_lbl)
	
	var transactions = [
		{"desc": "Зарплата — Завод", "amount": "+80,00 PLN", "color": Color(0.3, 0.9, 0.3)},
		{"desc": "Пиццерия", "amount": "+60,00 PLN", "color": Color(0.3, 0.9, 0.3)},
		{"desc": "Магазин — Энергетик", "amount": "-20,00 PLN", "color": Color(0.9, 0.3, 0.3)},
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
	_show_app_header("ePUAP — Usługi publiczne")
	_clear_content()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var welcome = Label.new()
	welcome.text = "Witaj, Danila Markowski"
	welcome.add_theme_font_size_override("font_size", 18)
	welcome.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(welcome)
	
	var services = [
		{"letter": "M", "title": "Status meldunkowy", "status": "Zameldowany: Warszawa, ul. Praga 14"},
		{"letter": "D", "title": "Dowód osobisty", "status": "Ważny do: 2028-03-15"},
		{"letter": "U", "title": "Ubezpieczenie", "status": "NFZ — aktywne, składki opłacone"},
		{"letter": "P", "title": "Rozliczenie PIT", "status": "PIT-37 złożony za ubiegły rok"},
	]
	
	for svc in services:
		var svc_panel = PanelContainer.new()
		var svc_style = StyleBoxFlat.new()
		svc_style.bg_color = Color(0.12, 0.15, 0.22, 0.9)
		svc_style.corner_radius_top_left = 12
		svc_style.corner_radius_top_right = 12
		svc_style.corner_radius_bottom_left = 12
		svc_style.corner_radius_bottom_right = 12
		svc_style.content_margin_left = 14
		svc_style.content_margin_right = 14
		svc_style.content_margin_top = 12
		svc_style.content_margin_bottom = 12
		svc_panel.add_theme_stylebox_override("panel", svc_style)
		
		var svc_hbox = HBoxContainer.new()
		svc_hbox.add_theme_constant_override("separation", 15)
		
		var icon_lbl = Label.new()
		icon_lbl.text = svc["letter"]
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var istyle = StyleBoxFlat.new()
		istyle.bg_color = Color(0.2, 0.3, 0.55, 1.0)
		istyle.corner_radius_top_left = 8
		istyle.corner_radius_top_right = 8
		istyle.corner_radius_bottom_left = 8
		istyle.corner_radius_bottom_right = 8
		icon_lbl.add_theme_stylebox_override("normal", istyle)
		icon_lbl.custom_minimum_size = Vector2(40, 40)
		icon_lbl.add_theme_font_size_override("font_size", 18)
		icon_lbl.add_theme_color_override("font_color", Color(1,1,1))
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var title_lbl = Label.new()
		title_lbl.text = svc["title"]
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		
		var status_lbl = Label.new()
		status_lbl.text = svc["status"]
		status_lbl.add_theme_font_size_override("font_size", 12)
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
# 🎮 GAMES APP
# ========================
func _open_games() -> void:
	_show_app_header("Игры")
	_clear_content()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var lbl = Label.new()
	lbl.text = "Раздел Игр пока в разработке.\nСкоро появятся новые развлечения!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	
	vbox.add_child(lbl)
	content_area.add_child(vbox)

# ========================
# 📻 RADIO APP
# ========================
var radio_player: AudioStreamPlayer
var current_station: int = -1
var radio_playlist: Array[String] = []
var radio_track_idx: int = 0

func _open_radio() -> void:
	_show_app_header("Радио")
	_clear_content()
	
	if not radio_player:
		radio_player = AudioManager.get_radio_player()
		radio_player.finished.connect(_on_radio_track_finished)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# The Digital Display
	var display_panel = PanelContainer.new()
	var screen_style = StyleBoxFlat.new()
	screen_style.bg_color = Color(0.04, 0.08, 0.04, 1.0)
	screen_style.corner_radius_top_left = 16
	screen_style.corner_radius_top_right = 16
	screen_style.corner_radius_bottom_left = 16
	screen_style.corner_radius_bottom_right = 16
	screen_style.border_width_left = 2
	screen_style.border_width_right = 2
	screen_style.border_width_top = 2
	screen_style.border_width_bottom = 2
	screen_style.border_color = Color(0.1, 0.3, 0.1)
	screen_style.content_margin_left = 20
	screen_style.content_margin_right = 20
	screen_style.content_margin_top = 25
	screen_style.content_margin_bottom = 25
	display_panel.add_theme_stylebox_override("panel", screen_style)
	
	var display_vbox = VBoxContainer.new()
	display_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	display_vbox.add_theme_constant_override("separation", 2)
	
	var now_playing_lbl = Label.new()
	now_playing_lbl.text = "СЕЙЧАС ИГРАЕТ"
	now_playing_lbl.add_theme_font_size_override("font_size", 12)
	now_playing_lbl.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
	now_playing_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_vbox.add_child(now_playing_lbl)
	
	var stations = [
		{"name": "FM 104.2", "desc": "Ретро Волна", "id": 0, "folder": "res://Assets/Audio/Radio/Retro", "color": Color(0.9, 0.3, 0.5)},
		{"name": "AM 99.0", "desc": "Подкаст-студия", "id": 1, "folder": "res://Assets/Audio/Radio/Podcast", "color": Color(0.3, 0.6, 0.9)},
		{"name": "FM 88.5", "desc": "Классика", "id": 2, "folder": "res://Assets/Audio/Radio/Classic", "color": Color(0.8, 0.7, 0.2)},
		{"name": "FM 101.4", "desc": "Новости Варшавы", "id": 3, "folder": "res://Assets/Audio/Radio/News", "color": Color(0.4, 0.8, 0.4)},
	]
	
	var freq_lbl = Label.new()
	freq_lbl.text = "ВЫКЛ"
	for st in stations:
		if current_station == st["id"]:
			freq_lbl.text = st["name"]
	
	freq_lbl.name = "FreqLabel"
	freq_lbl.add_theme_font_size_override("font_size", 42)
	freq_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	freq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_vbox.add_child(freq_lbl)
	display_panel.add_child(display_vbox)
	vbox.add_child(display_panel)
	
	var stations_vbox = VBoxContainer.new()
	stations_vbox.add_theme_constant_override("separation", 12)
	
	for st in stations:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 65)
		
		var bstyle = StyleBoxFlat.new()
		bstyle.bg_color = Color(0.2, 0.25, 0.35, 1.0) if current_station == st["id"] else Color(0.12, 0.15, 0.2, 0.8)
		bstyle.corner_radius_top_left = 12
		bstyle.corner_radius_top_right = 12
		bstyle.corner_radius_bottom_left = 12
		bstyle.corner_radius_bottom_right = 12
		bstyle.border_width_left = 6
		bstyle.border_color = st["color"]
		btn.add_theme_stylebox_override("normal", bstyle)
		
		# Inner layout overriding normal button text
		var margin = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var inner_hbox = HBoxContainer.new()
		inner_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var name_lbl = Label.new()
		name_lbl.text = st["name"]
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var desc_lbl = Label.new()
		desc_lbl.text = st["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		inner_hbox.add_child(name_lbl)
		inner_hbox.add_child(desc_lbl)
		margin.add_child(inner_hbox)
		btn.add_child(margin)
		
		btn.pressed.connect(func():
			current_station = st["id"]
			freq_lbl.text = st["name"]
			_open_radio() # Refresh UI to show selected state
			
			radio_playlist.clear()
			radio_track_idx = 0
			AudioManager.stop_radio()
			
			var d = DirAccess.open(st["folder"])
			if d:
				d.list_dir_begin()
				var file = d.get_next()
				while file != "":
					if not d.current_is_dir() and not file.begins_with("."):
						var clean_file = file.replace(".import", "").replace(".remap", "")
						if clean_file.ends_with(".ogg") or clean_file.ends_with(".mp3") or clean_file.ends_with(".wav"):
							var full_path = st["folder"] + "/" + clean_file
							if not radio_playlist.has(full_path):
								radio_playlist.append(full_path)
					file = d.get_next()
			
			if radio_playlist.size() > 0:
				radio_playlist.shuffle()
				_play_radio_track()
			else:
				freq_lbl.text = "ШУМ..."
		)
		stations_vbox.add_child(btn)
	
	vbox.add_child(stations_vbox)
	
	var off_btn = Button.new()
	off_btn.text = "Выключить приёмник"
	off_btn.custom_minimum_size = Vector2(0, 50)
	var off_style = StyleBoxFlat.new()
	off_style.bg_color = Color(0.6, 0.2, 0.2, 0.8)
	off_style.corner_radius_top_left = 8
	off_style.corner_radius_top_right = 8
	off_style.corner_radius_bottom_left = 8
	off_style.corner_radius_bottom_right = 8
	off_btn.add_theme_stylebox_override("normal", off_style)
	off_btn.pressed.connect(func():
		current_station = -1
		AudioManager.stop_radio()
		_open_radio()
	)
	vbox.add_child(off_btn)
	
	var info_lbl = Label.new()
	info_lbl.text = "Закиньте сколько угодно музыки (.ogg) в папки\nAssets/Audio/Radio/ (Retro, Podcast, Classic, News)"
	info_lbl.add_theme_font_size_override("font_size", 11)
	info_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_lbl)
	
	scroll.add_child(vbox)
	content_area.add_child(scroll)

func _play_radio_track() -> void:
	if radio_playlist.is_empty(): return
	if radio_track_idx >= radio_playlist.size():
		radio_track_idx = 0
		radio_playlist.shuffle()
	var track_path = radio_playlist[radio_track_idx]
	if ResourceLoader.exists(track_path):
		AudioManager.play_radio(track_path)
	else:
		radio_track_idx += 1
		if radio_track_idx < radio_playlist.size():
			_play_radio_track()

func _on_radio_track_finished() -> void:
	if current_station != -1 and radio_playlist.size() > 0:
		radio_track_idx += 1
		_play_radio_track()
