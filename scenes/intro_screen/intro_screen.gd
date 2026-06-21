extends Control

const NEXT_SCENE = "res://scenes/title_screen/title_screen.tscn"

@onready var video_player = $Background/VideoPlayer

var can_skip := false

func _ready():
	# Small delay before allowing skip to prevent accidental instant skip
	await get_tree().create_timer(0.5).timeout
	can_skip = true
	
	video_player.stream = load("res://assets/videos/intro.ogv")
	video_player.play()
	video_player.finished.connect(_go_to_title)


func _input(event):
	if not can_skip:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_go_to_title()

func _go_to_title():
	# Prevent calling twice
	set_process_input(false)
	get_tree().change_scene_to_file(NEXT_SCENE)
