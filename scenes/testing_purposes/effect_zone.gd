extends Area2D

@export var is_healing := false          # Toggle in Inspector: true = heal, false = damage
@export var amount_per_tick := 5.0       # How much HP per tick
@export var tick_interval := 1.0         # Seconds between ticks

var bodies_inside := []
var tick_timer := 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if bodies_inside.is_empty():
		return
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_apply_effect()

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	bodies_inside.append(body)

func _on_body_exited(body):
	if body in bodies_inside:
		bodies_inside.erase(body)

func _apply_effect():
	for body in bodies_inside:
		if is_healing:
			body.heal(amount_per_tick)
		else:
			body.take_damage(amount_per_tick)
