extends Node

var settings = {}

func _ready():
	load_settings()

func load_settings():
	var file_path = "res://data/settings.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			settings = json.data
			print("Config loaded successfully")
		else:
			push_error("JSON Parse Error: ", json.get_error_message())
	else:
		push_error("Config file not found!")

func get_val(category: String, key: String, default = null):
	if settings.has(category) and settings[category].has(key):
		return settings[category][key]
	return default
