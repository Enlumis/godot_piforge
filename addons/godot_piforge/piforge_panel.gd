@tool
class_name PiForgePanel 
extends Control

const OPTIONS = {
	API_KEY = 'piforge_ai/api_key',
	OUTPUT_PATH = 'piforge_ai/output_path',
	EXPORT_TYPE = 'piforge_ai/export_type',
}

var editor_file_dialog: EditorFileDialog
var input_image_data:String = ""
var empty_image = true
var current_filename = "unknown.png"
var history_loaded:bool = false
var is_auth_ready:bool = false
var credits = 0
var _headers : PackedStringArray = []
var export_type = "jpg"
var current_ai_product = "core_ai"

var history: Array[Dictionary] = [
	{
		"data": {
			"img_url": "https://storage.googleapis.com/download/storage/v1/b/gotoflatstyle.appspot.com/o/w39wM2Yo7xQf8LELXQumGFJNjJl2%2FwZVfUUAlHWehgTzrP79e_2.png?generation=1716666602092817&alt=media",
			"prompt_settings": {
				"cfg": 8,
				"denoise": 0.54,
			}
		}
	},
	{
		"data": {
			"img_url": "https://storage.googleapis.com/download/storage/v1/b/gotoflatstyle.appspot.com/o/w39wM2Yo7xQf8LELXQumGFJNjJl2%2FpBMQxDAI8xdfkThEOiCW_4.png?generation=1707424863797919&alt=media",
			"prompt_settings": {
				"cfg": 8,
				"denoise": 0.54,
			}
		}
	},
	{
		"data": {
			"img_url": "https://storage.googleapis.com/download/storage/v1/b/gotoflatstyle.appspot.com/o/w39wM2Yo7xQf8LELXQumGFJNjJl2%2FM6JZJg7kQb7V4M5R3MjT_1.png?generation=1707424219488364&alt=media",
			"prompt_settings": {
				"cfg": 8,
				"denoise": 0.54,
			}
		}
	},
	{
		"data": {
			"img_url": "https://storage.googleapis.com/download/storage/v1/b/gotoflatstyle.appspot.com/o/w39wM2Yo7xQf8LELXQumGFJNjJl2%2FMYw6pZdF6R0gP45N4SXw_2.png?generation=1706624077371134&alt=media",
			"prompt_settings": {
				"cfg": 8,
				"denoise": 0.54,
			}
		}
	},
	{
		"data": {
			"img_url": "https://storage.googleapis.com/download/storage/v1/b/gotoflatstyle.appspot.com/o/w39wM2Yo7xQf8LELXQumGFJNjJl2%2F1ikad6UVgkb4GIKuAtsF_1.png?generation=1706286927564549&alt=media",
			"prompt_settings": {
				"cfg": 8,
				"denoise": 0.54,
			}
		}
	},
]
var product_list: Array[Dictionary] = [
	{
		"name": "Core AI (Recommended)",
		"id": "core_ia",
	},
	{
		"name": "Ultra",
		"id": "ultra",
	},
	{
		"name": "Flat Style",
		"id": "flat_style_core_ai",
	},
	{
		"name": "Vehicle",
		"id": "dgv_core_ai",
	},
	{
		"name": "Open Journey",
		"id": "openjourney",
	},
	{
		"name": "SDXL",
		"id": "sdxl",
	},
	{
		"name": "SD 1.5",
		"id": "sd15",
	},
	# upscaler not available yet
	#{ 
	#	"name": "Upscaler",
	#	"id": "upscaler",
	#},
]

@onready var auth_panel:VBoxContainer = $AuthenticatePanel
@onready var auth_panel_spinner:Control = $AuthenticatePanel/Spinner
@onready var tab_container:TabContainer = $TabContainer

@onready var file_input_image:PiForgeInputImage = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/Field_File

@onready var save_button:MenuButton = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/ActionButtons/TopButtons/MenuButton

@onready var api_key_status:Label = $TabContainer/Settings/HBoxContainer/LabelStatus
@onready var api_key_input:LineEdit = $TabContainer/Settings/HBoxContainer/LineEdit

@onready var prompt_text:TextEdit = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/TextEdit
@onready var denoise_slider:HSlider = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/HSlider
@onready var cfg_slider:HSlider = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/HSliderCfg
@onready var image_count_spinbox:SpinBox = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/SpinBox
@onready var product_select:OptionButton = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/OptionButton

@onready var generate_spinner:Control = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/Spinner
@onready var generate_button:Button = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/Button
@onready var generate_status:Label = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/GenerateStatus

@onready var actions_buttons:Control = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/ActionButtons
@onready var canvas_spinner:Control = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/Spinner
@onready var canvas_subject_item:TextureRect = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/TextureRect

@onready var settings_credits:Label = $TabContainer/Settings/Credits
@onready var generator_credits:Label = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/ScrollContainer/VBoxContainer/Credits
@onready var show_start_generate_setting:Control = $TabContainer/Settings/HBoxContainer4
@onready var show_get_api_key_button:Control = $TabContainer/Settings/HBoxContainer3

@onready var history_container:HFlowContainer = $TabContainer/Generate/HSplitContainer/BoxContainer/VBoxContainer/ScrollContainer/FlowContainer/HFlowContainer

@onready var history_item = preload("history_item.tscn")


func _enter_tree():
	add_custom_project_setting(
		OPTIONS.API_KEY, 
		"", 
		TYPE_STRING, 
		PROPERTY_HINT_NONE,
		"Enter API KEY from https://piforge.ai"
	)
	add_custom_project_setting(
		OPTIONS.OUTPUT_PATH, 
		"res://", 
		TYPE_STRING, 
		PROPERTY_HINT_DIR,
		""
	)
	add_custom_project_setting(
		OPTIONS.EXPORT_TYPE, 
		0, 
		TYPE_INT, 
		PROPERTY_HINT_DIR,
		""
	)
	


func _ready():
	
	editor_file_dialog = EditorFileDialog.new()
	add_child(editor_file_dialog)
	var info_message := Label.new()
	info_message.add_theme_color_override('font_color', get_theme_color("warning_color", "Editor"))
	editor_file_dialog.get_line_edit().get_parent().add_sibling(info_message)
	info_message.get_parent().move_child(info_message, info_message.get_index()-1)
	editor_file_dialog.set_meta('info_message_label', info_message)
	
	save_button.get_popup().id_pressed.connect(_on_save_current)
	
	for i in range(product_list.size()):
		var prod = product_list[i]
		product_select.add_item(prod["name"], i)
	product_select.get_popup().id_pressed.connect(_on_change_ai_product)


func _on_change_ai_product(id: int):
	var prod = product_list[id]
	current_ai_product = prod["id"]
	pass
	
	
func _process(delta):
	pass


func update_auth_panel(show_app):
	if show_app:
		tab_container.visible = true
		auth_panel.visible = false
	else:
		tab_container.visible = false
		auth_panel.visible = true
		auth_panel_spinner.create_tween().tween_property(auth_panel_spinner.get_child(0),"rotation_degrees", 1000000, 1000).from(0)	


func on_open_panel():
	#print("[PiForge] Init")
	if get_api_key() != "":
		api_key_input.text = "******"
		update_auth_panel(is_auth_ready)
	else:
		tab_container.current_tab = 1
		show_start_generate_setting.visible = false
		auth_panel.visible = false
		tab_container.visible = true
	if empty_image:
		actions_buttons.visible = false
	save_button.icon = EditorInterface.get_editor_theme().get_icon("Save", 'EditorIcons')
	_on_button_check_key_pressed()


func add_item_to_history(item = null, append_at_end = false):
	var instan:PiForgeHistoryItem = history_item.instantiate()
	instan.set_panel_ref(self)
	history_container.add_child(instan)
	if !append_at_end:
		instan.get_parent().move_child(instan, 0)
	if item != null:
		instan.setData(item)
	return instan


func load_history():
	if (history_loaded):
		return
	history_loaded = true
	for i in history:
		add_item_to_history(i)


func _on_button_load_more_history_pressed():
	print("[PiForge AI]: history not available")
	pass # Replace with function body.
	

func _on_file_dialog_selected(path:String) -> void:
	var my_resource: Image = canvas_subject_item.texture.get_image()
	var only_filename = current_filename.split("?")[0]
	var filename_no_ext = only_filename.replace(".png", "")
	var error:Error
	match export_type:
		"jpg":
			only_filename = only_filename.replace(".png", ".jpg")
			error = my_resource.save_jpg(only_filename)
		"png":
			error = my_resource.save_png(only_filename)
		"webp":
			only_filename = only_filename.replace(".png", ".webp")
			error = my_resource.save_webp(only_filename)
		_:
			error = my_resource.save_jpg(only_filename)
	if error == OK:
		print("[PiForge AI] Ressouce Saved at %s" % only_filename)
		EditorInterface.get_resource_filesystem().scan()
	else:
		print("[PiForge AI] Failed to save resouce error:%s" % error)



func _on_save_current(id: int):
	match (id):
		0:
			export_type = "jpg"
		1:
			export_type = "png"
		2:
			export_type = "webp"
		_:
			export_type = "jpg"
	var only_filename = current_filename.split("?")[0]
	var filename_no_ext = only_filename.replace(".png", "")
	godot_file_dialog(_on_file_dialog_selected, "*.%s" % export_type, EditorFileDialog.FILE_MODE_SAVE_FILE, "Save "+ only_filename, filename_no_ext, true)


func on_pressed_get_key():
	OS.shell_open("https://piforge.ai/user/account?autogenerateapikey=true")


func _on_api_key_changed(new_text:String):
	if !new_text.contains("*"):
		set_api_key(new_text)


func _on_button_check_key_pressed():
	if get_api_key() == "":
		api_key_status.add_theme_color_override("font_color",Color.RED)
		api_key_status.text = "Please enter API KEY before check"
		show_start_generate_setting.visible = false;
		show_get_api_key_button.visible = true;
		set_credits(0)
	else:
		api_key_status.add_theme_color_override("font_color",Color.WHITE)
		api_key_status.text = "Checking account auth..."
		check_api_key(func(key_ready, data:Dictionary = {}):
			if key_ready:
				is_auth_ready = true
				update_auth_panel(is_auth_ready)
				show_start_generate_setting.visible = true;
				show_get_api_key_button.visible = false;
				set_credits(data["credits"])
				load_history()
				api_key_status.add_theme_color_override("font_color",Color.GREEN)
				api_key_status.text = "Your API KEY is ready"
				api_key_input.text = "******"
			else:
				is_auth_ready = false
				update_auth_panel(true)
				show_start_generate_setting.visible = false;
				show_get_api_key_button.visible = true;
				set_credits(0)
				api_key_status.add_theme_color_override("font_color",Color.RED)
				api_key_status.text = "Invalid key: %s"%data
				tab_container.current_tab = 1
			)


func _on_tab_container_tab_changed(tab):
	if !tab_container:
		return
	if get_api_key() == "" or is_auth_ready == false:
		tab_container.current_tab = 1
		show_get_api_key_button.visible = true
	else:
		tab_container.current_tab = tab
	if (tab == 1):
		_on_button_check_key_pressed()


func _on_pi_forge_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			OS.shell_open("https://piforge.ai/")
			


func set_credits(v):
	credits = v
	if !is_auth_ready:
		settings_credits.visible = false;
		generator_credits.visible = false;
	else:
		settings_credits.visible = true;
		generator_credits.visible = true;
		
	if v == 0:
		settings_credits.text = "0 Credits ! piforge.ai to reload"
		generator_credits.text = "0 Credits ! piforge.ai to reload"
		settings_credits.add_theme_color_override("font_color",Color.RED)
		generator_credits.add_theme_color_override("font_color",Color.RED)
	else:
		settings_credits.text = "%s Credits"%v
		generator_credits.text = "%s Credits"%v
		settings_credits.add_theme_color_override("font_color",Color.GREEN)
		generator_credits.add_theme_color_override("font_color",Color.GREEN)


func _on_button_generate_pressed():
	generate_spinner.visible = true
	generate_button.disabled = true
	canvas_spinner.visible = true
	canvas_subject_item.visible = false
	actions_buttons.visible = false
	generate_status.text = ""
	generate_spinner.create_tween().tween_property(generate_spinner.get_child(0), "rotation_degrees", 1000000, 1000).from(0)
	canvas_spinner.create_tween().tween_property(canvas_spinner.get_child(0), "rotation_degrees", 1000000, 1000).from(0)
	
	var img_count = int(image_count_spinbox.value)
	
	var historyItems = []
	for i in range(img_count):
		historyItems.append(add_item_to_history())
	
	var params = {
		"prompt": prompt_text.text,
		"product": current_ai_product,
		"denoise": denoise_slider.value,
		"cfg": cfg_slider.value,
		"image_count": img_count,
	}
	if input_image_data != "":
		params["image_url"] = "data:image/png;base64,%s" % input_image_data
	get_images(JSON.stringify(params), func(success, data):
		generate_spinner.visible = false
		generate_button.disabled = false
		if success:
			if data.has("total_credit_cost"):
				credits -= data["total_credit_cost"]
				set_credits(credits)
			for i in range(img_count):
				var h = historyItems[i]
				var create_history = get_json_data(JSON.stringify(data))
				create_history["data"] = get_json_data(JSON.stringify(data))
				create_history["data"]["img_url"] = data["img_urls"][i]
				h.setData(create_history)
			download_image(data["img_urls"][0])
		else:
			generate_status.text = JSON.stringify(data)
			canvas_spinner.visible = false
			
			for i in range(img_count):
				var h = historyItems[i]
				h.queue_free()
		pass)


func set_result(item):
	actions_buttons.visible = false
	if item.has("data"):
		var outdata = item["data"]
		if outdata.has("img_url"):
			download_image(outdata["img_url"])


func download_image(url:String):
	current_filename = url.get_file()
	canvas_spinner.visible = true
	canvas_spinner.create_tween().tween_property(canvas_spinner.get_child(0),"rotation_degrees", 1000000, 1000).from(0)	
	canvas_subject_item.visible = false

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _http_request_completed)

	var http_error = http_request.request(url)
	if http_error != OK:
		print("[PiForge AI] An error occurred in the HTTP request.")
		canvas_spinner.visible = false
		canvas_subject_item.visible = true


func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("[PiForge AI] Couldn't load the image.")
		canvas_spinner.visible = false
		canvas_subject_item.visible = true

	var texture = ImageTexture.create_from_image(image)
	canvas_subject_item.texture = texture
	actions_buttons.visible = true
	canvas_subject_item.visible = true
	canvas_spinner.visible = false
	empty_image = false


func check_api_key(callback:Callable):
	var authReq = "Authorization: Bearer %s" % get_api_key()
	_headers=[authReq]
	http_heq("user", func(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, request : HTTPRequest) -> void:
		var bodutf = body.get_string_from_utf8()
		var json = get_json_data(bodutf)
		if response_code == 200:
			callback.call(true, json)
		else:
			callback.call(false, json)
		pass)


func get_images(params, callback:Callable):
	var authReq = "Authorization: Bearer %s" % get_api_key()
	_headers=[authReq, "Content-Type: application/json; charset=UTF-8"]
	
	http_heq("images", func(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, request : HTTPRequest) -> void:
		var bodutf = body.get_string_from_utf8()
		var json = get_json_data(bodutf)
		if response_code == 200:
			callback.call(true, json)
		else:
			callback.call(false, json)
		pass, params)


func http_heq(route, callback, data: String = "", method:HTTPClient.Method = HTTPClient.METHOD_POST):
	var http_request : HTTPRequest

	http_request = HTTPRequest.new()
	http_request.timeout = 300
	add_child(http_request)
	http_request.request_completed.connect(_request_completed.bind(http_request))

	http_request.set_meta("callback", callback)
	http_request.request("https://piforge.ai/api/v1/%s" % route, _headers, method, data)


func _request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray, request : HTTPRequest) -> void:
	request.get_meta("callback").call(result, response_code, headers, body, request)
	pass


func get_json_data(value):
	if value is PackedByteArray:
		value = value.get_string_from_utf8()
	var json = JSON.new()
	var json_parse_result = json.parse(value)
	if json_parse_result == OK:
		return json.data
	
	return null


func set_api_key(key:String):
	ProjectSettings.set_setting(OPTIONS.API_KEY, key)
	ProjectSettings.save()


func get_api_key():
	return ProjectSettings.get_setting(OPTIONS.API_KEY, "")


func add_custom_project_setting(name: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:
	if ProjectSettings.has_setting(name): return

	var setting_info: Dictionary = {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	}

	ProjectSettings.set_setting(name, default_value)
	ProjectSettings.add_property_info(setting_info)
	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.set_as_basic(name, true)
	ProjectSettings.save()
	


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
	elif mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		editor_file_dialog.file_selected.connect(callable)
	return editor_file_dialog


func _on_field_file_value_changed(property_name, value):
	print("[PiForge AI]: set input file", property_name, value)
	if value == "":
		input_image_data = ""
		denoise_slider.value = 0.8
	else:
		denoise_slider.value = 0.6
		input_image_data = file_input_image.get_base_64_data()


func _on_button_input_copy_img_pressed():
	file_input_image.set_raw_texture(canvas_subject_item.texture)
	input_image_data = file_input_image.get_base_64_data()
	denoise_slider.value = 0.6
	


func _on_button_start_generate_pressed():
	if is_auth_ready:
		tab_container.current_tab = 0
