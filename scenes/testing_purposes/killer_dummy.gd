extends StaticBody2D

@onready var chase_radius = $ChaseRadius
@onready var sprite = $Sprite2D

var player_in_range := false
var is_stunned := false

func _ready():
	chase_radius.body_entered.connect(_on_body_entered)
	chase_radius.body_exited.connect(_on_body_exited)
	add_to_group("killer")

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	player_in_range = true
	MusicManager.play("2011x_chase")

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
	player_in_range = false
	MusicManager.play("act9")

func stun(duration: float):
	if is_stunned:
		return
	is_stunned = true
	print("2011X stunned for ", duration, " seconds")
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(_end_stun)

func _end_stun():
	is_stunned = false
	sprite.modulate = Color(1, 1, 1)
