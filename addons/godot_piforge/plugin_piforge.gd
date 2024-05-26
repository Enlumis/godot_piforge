@tool
class_name PiForgePlugin
extends EditorPlugin
	
var piforge_panel:PiForgePanel

const icon:Texture2D = preload("icon.svg")

func _enter_tree():
	piforge_panel = preload("piforge.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(piforge_panel)
	_make_visible(false)

func _exit_tree():
	if piforge_panel:
		piforge_panel.queue_free()

func _has_main_screen():
	return true

func _disable_plugin() -> void:
	print("[PiForge AI] disabled.")

func _make_visible(visible):
	if piforge_panel:
		piforge_panel.visible = visible
		if visible == true:
			piforge_panel.on_open_panel()


func _get_plugin_name():
	return "PiForge AI"


func _get_plugin_icon():
	return icon
