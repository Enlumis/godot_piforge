@tool
class_name PiForgeHistoryItem
extends Button

var data = null

@onready var texture_rect:TextureRect = $TextureRect2
@onready var spinner:Control = $Spinner

func _ready():
	spinner.visible = true
	texture_rect.visible = false
	spinner.create_tween().tween_property(spinner.get_child(0),"rotation_degrees", 1000000, 1000).from(0)	


func setData(item:Dictionary):
	data = item
	if data.has("data"):
		var outdata = data["data"]
		if outdata.has("img_url"):
			download_image(outdata["img_url"])



func download_image(url):
	texture_rect.visible = false
	spinner.visible = true
	spinner.create_tween().tween_property(spinner.get_child(0),"rotation_degrees", 1000000, 1000).from(0)	
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", func (result, response_code, headers, body):
		_http_request_completed(body, url))

	var http_error = http_request.request(url)
	if http_error != OK:
		print("[PiForge AI] An error occurred in the HTTP request.")
		spinner.visible = false


func _http_request_completed(body, url:String):
	var image = Image.new()
	var error = null
	if url.contains(".png"):
		error = image.load_png_from_buffer(body)
	elif url.contains(".jpg"):
		error = image.load_jpg_from_buffer(body)
	elif url.contains(".webp"):
		error = image.load_webp_from_buffer(body)
	if error != OK or error == null:
		push_error("[PiForge AI] Couldn't load the image.")
		spinner.visible = false

	var texture = ImageTexture.create_from_image(image)
	texture_rect.texture = texture
	spinner.visible = false
	texture_rect.visible = true


func _process(delta):
	pass
