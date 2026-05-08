extends Control

const NEXT_SCENE = "res://scenes/title_screen/title_screen.tscn"

@onready var video_player = $Background/VideoPlayer

func _ready():
	# Load your video file here
	# video_player.stream = load("res://assets/intro.ogv")
	# video_player.play()
	video_player.finished.connect(_go_to_title)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_go_to_title()

func _go_to_title():
	get_tree().change_scene_to_file(NEXT_SCENE)
