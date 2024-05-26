@tool
class_name PiForgeInputImage
extends Control

signal value_changed(property_name:String, value:Variant)
var property_name := ""

var editor_file_dialog: EditorFileDialog
## Event block field for selecting a file or directory.

#region VARIABLES
################################################################################

@export var file_filter := ""
@export var placeholder := ""
@export var file_mode : EditorFileDialog.FileMode = EditorFileDialog.FILE_MODE_OPEN_FILE
var resource_icon:Texture:
	get:
		return resource_icon
	set(new_icon):
		resource_icon = new_icon
		%Icon.texture = new_icon
		if new_icon == null:
			%Field.theme_type_variation = ""
		else:
			%Field.theme_type_variation = "LineEditWithIcon"

var max_width := 200
var current_value : String
var hide_reset:bool = false

#endregion


#region MAIN METHODS
################################################################################

func _ready() -> void:
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	var info_message := Label.new()
	info_message.add_theme_color_override('font_color', get_theme_color("warning_color", "Editor"))
	editor_file_dialog.get_line_edit().get_parent().add_sibling(info_message)
	info_message.get_parent().move_child(info_message, info_message.get_index()-1)
	editor_file_dialog.set_meta('info_message_label', info_message)
	$FocusStyle.add_theme_stylebox_override('panel', get_theme_stylebox('focus', 'DialogicEventEdit'))

	%OpenButton.icon = get_theme_icon("Folder", "EditorIcons")
	%OpenButton.button_down.connect(_on_OpenButton_pressed)

	%ClearButton.icon = get_theme_icon("Reload", "EditorIcons")
	%ClearButton.button_up.connect(clear_path)
	%ClearButton.visible = !hide_reset

	%Field.set_drag_forwarding(Callable(), self._can_drop_data_fw, self._drop_data_fw)
	%Field.placeholder_text = placeholder


func _load_display_info(info:Dictionary) -> void:
	file_filter = info.get('file_filter', '')
	placeholder = info.get('placeholder', '')
	resource_icon = info.get('icon', null)
	await ready
	if resource_icon == null and info.has('editor_icon'):
		resource_icon = callv('get_theme_icon', info.editor_icon)


func _set_value(value:Variant) -> void:
	current_value = value
	var text := value
	if file_mode != EditorFileDialog.FILE_MODE_OPEN_DIR:
		text = value.get_file()
		%Field.tooltip_text = value

	if %Field.get_theme_font('font').get_string_size(
		text, 0, -1,
		%Field.get_theme_font_size('font_size')).x > max_width:
		%Field.expand_to_text_length = false
		%Field.custom_minimum_size.x = max_width
		%Field.size.x = 0
	else:
		%Field.custom_minimum_size.x = 0
		%Field.expand_to_text_length = true

	%Field.text = text
	
	if value == null or value == "":
		%TextureRect.visible = false
	else:
		%TextureRect.visible = true
	
		var image = Image.load_from_file(value)

		var texture = ImageTexture.create_from_image(image)
		%TextureRect.texture = texture

	%ClearButton.visible = !value.is_empty() and !hide_reset


func get_base_64_data():
	var img:Image = %TextureRect.texture.get_image()
	var buf = img.save_png_to_buffer()
	return Marshalls.raw_to_base64(buf)


func set_raw_texture(textu:Texture2D):
	current_value = ""
	%TextureRect.visible = true
	%TextureRect.texture = textu
	%Field.text = current_value
	%ClearButton.visible = !hide_reset
	
#endregion

#region BUTTONS
################################################################################

func godot_file_dialog(callable:Callable, filter:String, mode := EditorFileDialog.FILE_MODE_OPEN_FILE, window_title := "Save", current_file_name := 'New_File', saving_something := false, extra_message:String = "") -> EditorFileDialog:
	for connection in editor_file_dialog.file_selected.get_connections():
		editor_file_dialog.file_selected.disconnect(connection.callable)
	for connection in editor_file_dialog.dir_selected.get_connections():
		editor_file_dialog.dir_selected.disconnect(connection.callable)
	editor_file_dialog.file_mode = mode
	editor_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	editor_file_dialog.clear_filters()
	editor_file_dialog.popup_centered_ratio(0.6)
	editor_file_dialog.add_filter(filter)
	editor_file_dialog.title = window_title
	editor_file_dialog.current_file = current_file_name
	editor_file_dialog.disable_overwrite_warning = !saving_something
	if extra_message:
		editor_file_dialog.get_meta('info_message_label').show()
		editor_file_dialog.get_meta('info_message_label').text = extra_message
	else:
		editor_file_dialog.get_meta('info_message_label').hide()

	if mode == EditorFileDialog.FILE_MODE_OPEN_FILE or mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		editor_file_dialog.file_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_DIR:
		editor_file_dialog.dir_selected.connect(callable)
	elif mode == EditorFileDialog.FILE_MODE_OPEN_ANY:
		editor_file_dialog.dir_selected.connect(callable)
		editor_file_dialog.file_selected.connect(callable)
	return editor_file_dialog
	
func _on_OpenButton_pressed() -> void:
	godot_file_dialog(_on_file_dialog_selected, file_filter, file_mode, "Open "+ property_name)


func _on_file_dialog_selected(path:String) -> void:
	_set_value(path)
	value_changed.emit(property_name, path)


func clear_path() -> void:
	_set_value("")
	value_changed.emit(property_name, "")

#endregion


#region DRAG AND DROP
################################################################################

func _can_drop_data_fw(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has('files') and len(data.files) == 1:
		if file_filter:
			if '*.'+data.files[0].get_extension() in file_filter:
				return true
		else: return true
	return false

func _drop_data_fw(at_position: Vector2, data: Variant) -> void:
	_on_file_dialog_selected(data.files[0])

#endregion


#region VISUALS FOR FOCUS
################################################################################

func _on_field_focus_entered():
	$FocusStyle.show()

func _on_field_focus_exited():
	_on_file_dialog_selected(%Field.text)

#endregion


func _on_texture_rect_gui_input(event):
	if event is InputEventMouseButton and event.pressed == false and event.button_index == 1:
		_on_OpenButton_pressed()
	if event is InputEventScreenTouch and event.pressed == false and event.button_index == 1:
		_on_OpenButton_pressed()
