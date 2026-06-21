extends Control

const NEXT_SCENE = "res://scenes/main_menu/main_menu.tscn"

@onready var start_button = $Background/StartButton

func _ready():
	print("Start button found: ", start_button)
	start_button.pressed.connect(_on_start)

func _on_start():
	get_tree().change_scene_to_file(NEXT_SCENE)
