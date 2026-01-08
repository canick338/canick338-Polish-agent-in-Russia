extends RefCounted
class_name AxeTextureGenerator
## Утилита для генерации простых изображений топоров

static func create_axe_texture(size: Vector2 = Vector2(200, 300), is_golden: bool = false) -> ImageTexture:
	"""Создать текстуру топора"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Прозрачный фон
	
	# Основные цвета
	var handle_color = Color(0.4, 0.3, 0.2, 1)  # Коричневый для рукоятки
	var blade_color = Color(0.7, 0.7, 0.7, 1)   # Серый для лезвия
	var gold_color = Color(0.85, 0.65, 0.13, 1) # Золотой
	
	if is_golden:
		blade_color = gold_color
	
	# Рисуем топор
	var center_x = size.x / 2
	var center_y = size.y / 2
	
	# Рисуем рукоятку (вертикальная линия)
	var handle_width = 20
	var handle_start_y = center_y + 50
	var handle_end_y = size.y - 20
	
	for x in range(int(center_x - handle_width/2), int(center_x + handle_width/2)):
		for y in range(int(handle_start_y), int(handle_end_y)):
			image.set_pixel(x, y, handle_color)
	
	# Рисуем лезвие (треугольник)
	var blade_width = 120
	var blade_height = 80
	var blade_top_y = center_y - 50
	
	# Треугольник лезвия
	for y in range(int(blade_top_y), int(blade_top_y + blade_height)):
		var progress = float(y - blade_top_y) / blade_height
		var current_width = int(blade_width * (1.0 - progress * 0.3))
		var start_x = int(center_x - current_width / 2)
		var end_x = int(center_x + current_width / 2)
		
		for x in range(start_x, end_x):
			if x >= 0 and x < size.x and y >= 0 and y < size.y:
				# Добавляем блик для золотого топора
				if is_golden and (x - start_x) < current_width * 0.3:
					var highlight = Color(1.0, 0.9, 0.5, 1.0)
					image.set_pixel(x, y, highlight)
				else:
					image.set_pixel(x, y, blade_color)
	
	# Контур лезвия
	var outline_color = Color(0.2, 0.2, 0.2, 1)
	for y in range(int(blade_top_y), int(blade_top_y + blade_height)):
		var progress = float(y - blade_top_y) / blade_height
		var current_width = int(blade_width * (1.0 - progress * 0.3))
		var start_x = int(center_x - current_width / 2)
		var end_x = int(center_x + current_width / 2)
		
		if start_x >= 0 and start_x < size.x and y >= 0 and y < size.y:
			image.set_pixel(start_x, y, outline_color)
		if end_x - 1 >= 0 and end_x - 1 < size.x and y >= 0 and y < size.y:
			image.set_pixel(end_x - 1, y, outline_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture
