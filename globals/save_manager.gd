extends Node

const SAVE_PATH = "user://settings.cfg"
var config := ConfigFile.new()

func _ready():
	config.load(SAVE_PATH)

func get_value(section: String, key: String, default):
	return config.get_value(section, key, default)

func set_value(section: String, key: String, value):
	config.set_value(section, key, value)
	config.save(SAVE_PATH)
