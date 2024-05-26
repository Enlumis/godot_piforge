@tool
class_name PiForgePanel 
extends Control

const OPTIONS = {
	API_KEY = 'piforge_ai/api_key',
	OUTPUT_PATH = 'piforge_ai/output_path',
	EXPORT_TYPE = 'piforge_ai/export_type',
}

var input_image_data:String = ""
var empty_image = true
var current_filename = "unknown.png"
var history_loaded:bool = false
var is_auth_ready:bool = false
var currentTab = 0
var credits = 0
var _headers : PackedStringArray = []

var history: Array[Dictionary] = [
	{"img_url": "https://storage.googleapis.com/download/storage/v1/b/gotoflatstyle.appspot.com/o/w39wM2Yo7xQf8LELXQumGFJNjJl2%2FeJSfnLXPZSyY3UHmCmNA_2.png?generation=1716666766803777&alt=media"}
]

@onready var tab_container:TabContainer = $TabContainer

@onready var file_input_image:PiForgeInputImage = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/Field_File

@onready var save_button = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/ActionButtons/TopButtons/ButtonSave

@onready var api_key_status:Label = $TabContainer/Settings/HBoxContainer/LabelStatus
@onready var api_key_input:LineEdit = $TabContainer/Settings/HBoxContainer/LineEdit

@onready var prompt_text:TextEdit = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/TextEdit
@onready var denoise_slider:HSlider = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/HSlider
@onready var cfg_slider:HSlider = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/HSliderCfg
@onready var image_count_spinbox:SpinBox = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/SpinBox

@onready var generate_spinner:Control = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/Spinner
@onready var generate_button:Button = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/Button
@onready var generate_status:Label = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/GenerateStatus

@onready var actions_buttons:Control = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/ActionButtons
@onready var canvas_spinner:Control = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/Spinner
@onready var canvas_subject_item:TextureRect = $TabContainer/Generate/HSplitContainer/HSplitContainer/ScrollContainer/GraphNode/VBoxContainer/TextureRect

@onready var settings_credits:Label = $TabContainer/Settings/Credits
@onready var generator_credits:Label = $TabContainer/Generate/HSplitContainer/HSplitContainer/BoxContainer2/VBoxContainer/Credits
@onready var show_start_generate_setting:Control = $TabContainer/Settings/HBoxContainer4
@onready var show_get_api_key_button:Control = $TabContainer/Settings/HBoxContainer3

@onready var history_container:HFlowContainer = $TabContainer/Generate/HSplitContainer/BoxContainer/VBoxContainer/ScrollContainer/FlowContainer/HFlowContainer

@onready var export_type_options:OptionButton = $TabContainer/Settings/HBoxContainer5/OptionButton

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
	save_button.connect("pressed", on_save_current)


func _process(delta):
	pass


func on_open_panel():
	if get_api_key() != "":
		api_key_input.text = "******"
	else:
		tab_container.current_tab = 1
		show_start_generate_setting.visible = false
	if empty_image:
		actions_buttons.visible = false
	save_button.icon = EditorInterface.get_editor_theme().get_icon("Save", 'EditorIcons')
	export_type_options.selected = get_export_type()
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
	pass # Replace with function body.
	for i in history:
		add_item_to_history(i, true)


func on_save_current():
	var my_resource: Image = canvas_subject_item.texture.get_image()
	var path:String = "%s%s" % [get_output_path(), current_filename]
	var only_filename = path.split("?")[0]
	var export_type = get_export_type()
	var error:Error
	match export_type:
		0:
			only_filename = only_filename.replace(".png", ".jpg")
			error = my_resource.save_jpg(only_filename)
		1:
			error = my_resource.save_png(only_filename)
		2:
			only_filename = only_filename.replace(".png", ".webp")
			error = my_resource.save_webp(only_filename)
		_:
			error = my_resource.save_png(only_filename)
	if error == OK:
		print("[PiForge AI] Ressouce Saved at %s" % only_filename)
		EditorInterface.get_resource_filesystem().scan()
	else:
		print("[PiForge AI] Failed to save resouce error:%s" % error)
	pass

func on_pressed_get_key():
	OS.shell_open("https://piforge.ai/user/account?autogenerateapikey=true")


func _on_api_key_changed(new_text:String):
	if !new_text.contains("*"):
		set_api_key(new_text)


func _on_button_check_key_pressed():
	if get_api_key() == "":
		api_key_status.add_theme_color_override("font_color",Color.RED)
		api_key_status.text = "Please enter API KEY before check"
	else:
		api_key_status.add_theme_color_override("font_color",Color.WHITE)
		api_key_status.text = "Checking account auth..."
		check_api_key(func(key_ready, data:Dictionary = {}):
			if key_ready:
				is_auth_ready = true
				show_start_generate_setting.visible = true;
				show_get_api_key_button.visible = false;
				set_credits(data["credits"])
				load_history()
				api_key_status.add_theme_color_override("font_color",Color.GREEN)
				api_key_status.text = "Your API KEY is ready"
				api_key_input.text = "******"
			else:
				is_auth_ready = false
				show_start_generate_setting.visible = false;
				show_get_api_key_button.visible = true;
				set_credits(0)
				api_key_status.add_theme_color_override("font_color",Color.RED)
				api_key_status.text = "Invalid key: %s"%data
				tab_container.current_tab = 1
				currentTab = 1
			)


func _on_tab_container_tab_changed(tab):
	if !tab_container:
		return
	currentTab = tab
	if get_api_key() == "" or is_auth_ready == false:
		currentTab = 1
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
	generate_spinner.create_tween().tween_property(generate_spinner.get_child(0), "rotation_degrees", 1000000, 1000).from(0)
	canvas_spinner.create_tween().tween_property(canvas_spinner.get_child(0), "rotation_degrees", 1000000, 1000).from(0)
	
	var img_count = int(image_count_spinbox.value)
	
	var historyItems = []
	for i in range(img_count):
		historyItems.append(add_item_to_history())
	
	var params = {
		"prompt": prompt_text.text,
		"product": "core_ai",
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
				h.setData({"img_url": data["img_urls"][i]})
			download_image(data["img_urls"][0])
		else:
			generate_status.text = data
		pass)


func set_result(item):
	actions_buttons.visible = false
	download_image(item["img_url"])


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


func _on_output_path_changed(new_text):
	set_output_path(new_text)


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


func set_output_path(key:String):
	ProjectSettings.set_setting(OPTIONS.OUTPUT_PATH, key)
	ProjectSettings.save()


func set_export_type(key:int):
	ProjectSettings.set_setting(OPTIONS.EXPORT_TYPE, key)
	ProjectSettings.save()


func get_api_key():
	return ProjectSettings.get_setting(OPTIONS.API_KEY, "")


func get_export_type():
	return ProjectSettings.get_setting(OPTIONS.EXPORT_TYPE, 0)


func get_output_path():
	return ProjectSettings.get_setting(OPTIONS.OUTPUT_PATH, "res://")


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
	


func _on_field_file_value_changed(property_name, value):
	print("[PiForge AI]: set input file", property_name, value)
	if value == "":
		input_image_data = ""
		denoise_slider.value = 0.8
	else:
		denoise_slider.value = 0.5
		input_image_data = file_input_image.get_base_64_data()


func _on_button_input_copy_img_pressed():
	file_input_image.set_raw_texture(canvas_subject_item.texture)


func _on_option_export_type_selected(index):
	set_export_type(index)


func _on_button_start_generate_pressed():
	if is_auth_ready:
		tab_container.current_tab = 0
