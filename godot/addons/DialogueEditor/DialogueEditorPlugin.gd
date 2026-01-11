@tool
extends EditorPlugin

const MainPanel = preload("res://addons/DialogueEditor/DialogueEditor.tscn")

var main_panel_instance

func _enter_tree():
	main_panel_instance = MainPanel.instantiate()
	# Add the main panel to the editor's main viewport.
	get_editor_interface().get_editor_main_screen().add_child(main_panel_instance)
	# Hide it by default.
	_make_visible(false)

func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible

func _get_plugin_name():
	return "Dialogues"

func _get_plugin_icon():
	# Use standard script icon for now
	return get_editor_interface().get_base_control().get_theme_icon("Script", "EditorIcons")
