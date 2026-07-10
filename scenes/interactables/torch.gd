extends Area2D

@export var task_id: String = "light_torches"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.task_manager.complete_task(task_id)
	queue_free()
