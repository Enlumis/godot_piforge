@tool
class_name PiForgeHistoryItem
extends Button

var data = null
var panel: PiForgePanel

@onready var texture_rect:TextureRect = $TextureRect2
@onready var spinner:Control = $Spinner

func _ready():
	spinner.visible = true
	texture_rect.visible = false
	spinner.create_tween().tween_property(spinner.get_child(0),"rotation_degrees", 1000000, 1000).from(0)	


func set_panel_ref(p):
	panel = p


func setData(item):
	data = item
	download_image(item["img_url"])


func _on_pressed():
	panel.set_result(data)


func download_image(url):
	texture_rect.visible = false
	spinner.visible = true
	spinner.create_tween().tween_property(spinner.get_child(0),"rotation_degrees", 1000000, 1000).from(0)	
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _http_request_completed)

	var http_error = http_request.request(url)
	if http_error != OK:
		print("An error occurred in the HTTP request.")
		spinner.visible = false


func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
		spinner.visible = false

	var texture = ImageTexture.create_from_image(image)
	texture_rect.texture = texture
	spinner.visible = false
	texture_rect.visible = true


func _process(delta):
	pass
