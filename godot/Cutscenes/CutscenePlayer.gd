## Проигрыватель видео кат-сцен для визуальной новеллы
## Поддерживает .ogv и .webm форматы
class_name CutscenePlayer
extends Control

signal cutscene_finished()
signal cutscene_skipped()

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var skip_label: Label = $SkipLabel

var can_skip: bool = true
var auto_continue: bool = true


func _ready() -> void:
	# Настройка видео плеера
	video_player.finished.connect(_on_video_finished)
	
	# Полноэкранный режим
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Подсказка для пропуска
	if skip_label:
		skip_label.visible = can_skip
	
	hide()


func play_cutscene(video_path: String, can_skip_video: bool = true, auto_continue_after: bool = true) -> void:
	"""
	Проиграть кат-сцену
	
	Args:
		video_path: Путь к видео файлу (например "res://Cutscenes/prologue.ogv")
		can_skip_video: Можно ли пропустить видео
		auto_continue_after: Автоматически продолжить после видео
	"""
	can_skip = can_skip_video
	auto_continue = auto_continue_after
	
	# Загрузить видео
	var video_stream: VideoStream = load(video_path)
	if not video_stream:
		push_error("Не удалось загрузить видео: " + video_path)
		cutscene_finished.emit()
		return
	
	video_player.stream = video_stream
	
	# Показать и запустить
	show()
	if skip_label:
		skip_label.visible = can_skip
	
	video_player.play()


func _input(event: InputEvent) -> void:
	if not visible or not can_skip:
		return
	
	# Пропустить на любую кнопку
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			skip_cutscene()


func skip_cutscene() -> void:
	"""Пропустить текущую кат-сцену"""
	if not can_skip or not visible:
		return
	
	video_player.stop()
	hide()
	cutscene_skipped.emit()
	
	if auto_continue:
		cutscene_finished.emit()


func _on_video_finished() -> void:
	"""Видео закончилось"""
	hide()
	
	if auto_continue:
		cutscene_finished.emit()


func stop() -> void:
	"""Остановить проигрывание"""
	video_player.stop()
	hide()









