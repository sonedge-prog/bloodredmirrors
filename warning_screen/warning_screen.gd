extends Control

const NEXT_SCENE = "res://scenes/title_screen/title_screen.tscn"

@onready var checkbox_container = $Background/CheckboxContainer
@onready var dont_show_check    = $Background/CheckboxContainer/DontShowCheck
@onready var accept_button      = $Background/AcceptButton

func _ready():
	# Check if this is the first launch
	var first_launch = SaveManager.get_value("warning", "first_launch", true)
	var skip_warning = SaveManager.get_value("warning", "skip_warning", false)

	# If player chose to never see it again, skip straight to intro
	if skip_warning:
		_go_to_next_scene()
		return

	# Show checkbox only on second launch and beyond
	checkbox_container.visible = not first_launch

	# Mark that first launch has now happened
	if first_launch:
		SaveManager.set_value("warning", "first_launch", false)

	accept_button.pressed.connect(_on_accept)

func _on_accept():
	# If checkbox is visible and ticked, save the preference
	if checkbox_container.visible and dont_show_check.button_pressed:
		SaveManager.set_value("warning", "skip_warning", true)

	_go_to_next_scene()

func _go_to_next_scene():
	get_tree().change_scene_to_file(NEXT_SCENE)
