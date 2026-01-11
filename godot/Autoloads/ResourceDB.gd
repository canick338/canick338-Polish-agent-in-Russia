## Auto-loaded node that loads and gives access to all [Background] resources in the game.
extends Node

const NARRATOR_ID := "narrator"

@onready var _characters := _load_resources("res://Characters/", "_is_character")
@onready var _backgrounds := _load_resources("res://Backgrounds/", "_is_background")


func get_character(character_id: String) -> Character:
	return _characters.get(character_id)


func get_narrator() -> Character:
	return _characters.get(NARRATOR_ID)


func get_background(background_id: String) -> Background:
	if _backgrounds.has(background_id):
		return _backgrounds[background_id]
	
	# Fallback: check if it is a raw path to an image
	if background_id.begins_with("res://") or (background_id.find("/") > -1 and (background_id.ends_with(".png") or background_id.ends_with(".jpg") or background_id.ends_with(".webp"))):
		var path = background_id
		if not path.begins_with("res://"):
			# Try to resolve relative path if possible, or assume it is absolute from project root??
			# ScenePlayer usually resolves it, but if it came here as relative, we might need to fix it.
			# But best to rely on caller providing good path. 
			# Let's check for file existence via load
			if not FileAccess.file_exists("res://" + path):
				pass # Keep original
			else:
				path = "res://" + path
				
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture is Texture2D:
				var bg = Background.new()
				bg.id = "custom_" + path.get_file()
				bg.texture = texture
				return bg
				
	return null


## Finds and loads resources of a given type in `directory_path`.
## As we don't have generics in GDScript, we pass a function's name to do type checks.
## We call that function on each loaded resource with `call()`.
func _load_resources(directory_path: String, check_type_function: String) -> Dictionary:
	var directory := DirAccess.open(directory_path)
	if not directory:
		return {}

	var resources := {}

	directory.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var filename = directory.get_next()
	while filename != "":
		if filename.ends_with(".tres"):
			var resource: Resource = load(directory_path.path_join(filename))

			if not call(check_type_function, resource):
				continue

			resources[resource.id] = resource
		filename = directory.get_next()
	directory.list_dir_end()

	return resources


func _is_character(resource: Resource) -> bool:
	return resource is Character


func _is_background(resource: Resource) -> bool:
	return resource is Background
