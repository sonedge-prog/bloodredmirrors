extends CharacterBody2D

signal health_changed(current: float, max: float)

# -- Movement Constants ---------------------------------------------------------------------------------
const SPEED           = 300.0
const SPEED_BOOST     = 1.10
const JUMP_VELOCITY   = -400.0
const CROUCH_SPEED_MOD = 0.4

# -- Health -----------------------------------------------------------------------------------------------
@export var max_health := 90.0
var current_health := max_health

const LOW_HEALTH_THRESHOLD    = 27.0   # 30% of 90 HP — adjust freely
const HEAL_RECOVERY_THRESHOLD = 45.0   # 50% of 90 HP — must heal back to this to turn off alarm
var is_low_health := false

# -- Ability Constants (placeholder values — tune freely) -----------------------------------------------
const BOOST_REV_TIME     = 1.0
const BOOST_DURATION     = 2.5
const BOOST_SPEED        = SPEED * 2.5
const BOOST_COOLDOWN     = 14.0
const BOOST_STUN_HIT     = 1.5

const BEATDOWN_STARTUP   = 0.3
const BEATDOWN_COMBO     = 3.0
const BEATDOWN_STUN      = 1.5
const BEATDOWN_COOLDOWN  = 9.0
const BEATDOWN_RANGE     = 90.0

const SHIELD_DURATION    = 0.5
const SHIELD_COOLDOWN    = 5.0

const ENERBEAM_MAX_CHARGES  = 3
const ENERBEAM_RECHARGE     = 6.0
const ENERBEAM_RANGE        = 400.0

const TORNADO_TAP_DURATION  = 4.0
const TORNADO_TAP_STUN      = 5.0
const TORNADO_HOLD_THRESHOLD = 0.3
const TORNADO_HOLD_DURATION = 10.0
const TORNADO_HOLD_STUN_TICK = 2.0
const TORNADO_COOLDOWN      = 16.0
const TORNADO_RANGE         = 150.0

const CHASE_MUFFLE_RANGE = 300.0

@onready var sprite = $AnimatedSprite2D

# -- Movement State --------------------------------------------------------------------------------------
var is_crouching  := false
var facing_right  := true
var is_turning    := false
var is_landing    := false
var was_in_air    := false
var movement_locked := false
var is_invulnerable := false

# -- Ability Cooldowns -------------------------------------------------------------------------------------
var ability_cooldowns := [0.0, 0.0, 0.0, 0.0, 0.0]  # indices 0-4 match ability_1..5

# Enerbeam charges (ability 4 works differently — charge-based)
var enerbeam_charges := ENERBEAM_MAX_CHARGES
var enerbeam_recharge_timer := 0.0

# Ability 5 tap/hold tracking
var ability5_press_time := 0.0
var ability5_held_check_active := false

func _ready():
	sprite.animation_finished.connect(_on_animation_finished)
	add_to_group("player")
	current_health = max_health
	call_deferred("_announce_health")  # ensures HUD has finished its own _ready first

func _announce_health():
	health_changed.emit(current_health, max_health)

func _physics_process(delta):
	var was_on_floor = is_on_floor()

	if not is_on_floor():
		velocity += get_gravity() * delta

	_tick_cooldowns(delta)
	_handle_ability_input()

	if movement_locked:
		move_and_slide()
		return

	is_crouching = Input.is_action_pressed("crouch") and is_on_floor() and not is_turning

	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0 and not is_turning and not is_landing:
		var new_facing = direction > 0
		if new_facing != facing_right and is_on_floor() and abs(velocity.x) > 50:
			is_turning = true
			sprite.play("Turn")
		facing_right = new_facing
		sprite.flip_h = not facing_right

	if not is_turning:
		if direction != 0:
			var speed = SPEED * SPEED_BOOST
			if is_crouching:
				speed *= CROUCH_SPEED_MOD
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching and not is_turning:
		velocity.y = JUMP_VELOCITY
		was_in_air = true

	move_and_slide()

	if not was_on_floor and is_on_floor() and was_in_air:
		is_landing = true
		sprite.play("Land")
		was_in_air = false
	elif not is_landing and not is_turning:
		_update_animation()

	# -- Low Health Muffle Check (runs every physics frame while low health) --------------------------------
	if is_low_health:
		_update_chase_muffle()

# -- Health API ---------------------------------------------------------------------------------------------
func take_damage(amount: float):
	if is_invulnerable:
		return
	current_health = clamp(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	_check_low_health()
	if current_health <= 0:
		_on_death()

func heal(amount: float):
	current_health = clamp(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	_check_low_health()

func set_max_health(new_max: float, keep_ratio: bool = true):
	if keep_ratio and max_health > 0:
		var ratio = current_health / max_health
		max_health = new_max
		current_health = clamp(max_health * ratio, 0, max_health)
	else:
		max_health = new_max
		current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)
	_check_low_health()

func _on_death():
	print("Sonic has died")
	# Placeholder — hook up death state/animation later

# -- Low Health / Alarm / Muffle -----------------------------------------------------------------------------
func _check_low_health():
	if current_health <= LOW_HEALTH_THRESHOLD and not is_low_health:
		is_low_health = true
		MusicManager.start_low_health_alarm()
		_update_chase_muffle()
	elif current_health >= HEAL_RECOVERY_THRESHOLD and is_low_health:
		is_low_health = false
		MusicManager.stop_low_health_alarm()
		MusicManager.set_muffled(false)

func _update_chase_muffle():
	if is_low_health and _get_nearest_killer(CHASE_MUFFLE_RANGE) != null:
		MusicManager.set_muffled(true)
	else:
		MusicManager.set_muffled(false)

# -- Cooldown Ticking -------------------------------------------------------------------------------------
func _tick_cooldowns(delta):
	for i in range(ability_cooldowns.size()):
		if ability_cooldowns[i] > 0.0:
			ability_cooldowns[i] = max(0.0, ability_cooldowns[i] - delta)

	if enerbeam_charges < ENERBEAM_MAX_CHARGES:
		enerbeam_recharge_timer += delta
		if enerbeam_recharge_timer >= ENERBEAM_RECHARGE:
			enerbeam_recharge_timer = 0.0
			enerbeam_charges += 1

# -- Ability Input -----------------------------------------------------------------------------------------
func _handle_ability_input():
	if Input.is_action_just_pressed("ability_1"):
		_try_boost()
	if Input.is_action_just_pressed("ability_2"):
		_try_rapid_beatdown()
	if Input.is_action_just_pressed("ability_3"):
		_try_shield_sidestep()
	if Input.is_action_just_pressed("ability_4"):
		_try_enerbeam()

	# Ability 5 tap/hold detection
	if Input.is_action_just_pressed("ability_5"):
		ability5_press_time = 0.0
		ability5_held_check_active = true
	if ability5_held_check_active and Input.is_action_pressed("ability_5"):
		ability5_press_time += get_physics_process_delta_time()
		if ability5_press_time >= TORNADO_HOLD_THRESHOLD:
			ability5_held_check_active = false
			_try_sonic_tornado()
	if Input.is_action_just_released("ability_5") and ability5_held_check_active:
		ability5_held_check_active = false
		_try_windy_finish()

# -- Helper: Get HUD ---------------------------------------------------------------------------------------
func _get_hud():
	return get_tree().get_first_node_in_group("hud")

func _get_nearest_killer(range: float):
	var nearest = null
	var nearest_dist = range
	for killer in get_tree().get_nodes_in_group("killer"):
		var dist = global_position.distance_to(killer.global_position)
		if dist <= nearest_dist:
			nearest = killer
			nearest_dist = dist
	return nearest

# -- Ability 1: Boost / Double Boost ------------------------------------------------------------------------
func _try_boost():
	if ability_cooldowns[0] > 0.0 or movement_locked:
		return
	_boost_sequence()

func _boost_sequence():
	movement_locked = true
	velocity.x = 0
	sprite.play("Idle")  # placeholder — rev up pose
	await get_tree().create_timer(BOOST_REV_TIME).timeout

	var dir = 1 if facing_right else -1
	var elapsed = 0.0
	var boost_duration = BOOST_DURATION

	while elapsed < boost_duration:
		velocity.x = dir * BOOST_SPEED
		move_and_slide()

		var killer = _get_nearest_killer(60.0)
		if killer:
			killer.stun(BOOST_STUN_HIT)
			boost_duration *= 0.5  # loses half duration on hit
			break

		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	movement_locked = false
	ability_cooldowns[0] = BOOST_COOLDOWN
	var hud = _get_hud()
	if hud:
		hud.start_ability_cooldown(0, BOOST_COOLDOWN)

# -- Ability 2: Rapid Beatdown ------------------------------------------------------------------------------
func _try_rapid_beatdown():
	if ability_cooldowns[1] > 0.0 or movement_locked:
		return
	_rapid_beatdown_sequence()

func _rapid_beatdown_sequence():
	movement_locked = true
	velocity.x = 0
	await get_tree().create_timer(BEATDOWN_STARTUP).timeout

	var killer = _get_nearest_killer(BEATDOWN_RANGE)
	if killer:
		print("Rapid Beatdown connected — 30 damage over 3s combo")
		await get_tree().create_timer(BEATDOWN_COMBO).timeout
		killer.stun(BEATDOWN_STUN)
	else:
		print("Rapid Beatdown missed — no target in range")

	movement_locked = false
	ability_cooldowns[1] = BEATDOWN_COOLDOWN
	var hud = _get_hud()
	if hud:
		hud.start_ability_cooldown(1, BEATDOWN_COOLDOWN)

# -- Ability 3: InstaShield / Sidestep -----------------------------------------------------------------------
func _try_shield_sidestep():
	if ability_cooldowns[2] > 0.0:
		return
	_shield_sequence()

func _shield_sequence():
	is_invulnerable = true
	if is_on_floor():
		print("Sidestep — 10 embarrassment points")
		var dir = 1 if facing_right else -1
		velocity.x = dir * 50  # small dodge nudge
	else:
		print("InstaShield — 10 embarrassment points")

	await get_tree().create_timer(SHIELD_DURATION).timeout
	is_invulnerable = false
	ability_cooldowns[2] = SHIELD_COOLDOWN
	var hud = _get_hud()
	if hud:
		hud.start_ability_cooldown(2, SHIELD_COOLDOWN)

# -- Ability 4: Enerbeam ---------------------------------------------------------------------------------------
func _try_enerbeam():
	if enerbeam_charges <= 0:
		print("Enerbeam — no charges left")
		return

	var killer = _get_nearest_killer(ENERBEAM_RANGE)
	if killer:
		print("Enerbeam grabbed 2011X — pulling in (5 damage)")
		var dir = (global_position - killer.global_position).normalized()
		killer.global_position += dir * 100  # pull toward Sonic (placeholder logic)
	else:
		print("Enerbeam — no target, could grapple to a platform here (needs 'grappable' group)")

	enerbeam_charges -= 1
	var hud = _get_hud()
	if hud:
		hud.start_ability_cooldown(3, ENERBEAM_RECHARGE)

# -- Ability 5: Windy Finish / Sonic Tornado -------------------------------------------------------------------
func _try_windy_finish():
	if ability_cooldowns[4] > 0.0 or movement_locked:
		return
	_windy_finish_sequence()

func _windy_finish_sequence():
	movement_locked = true
	velocity = Vector2.ZERO
	print("Windy Finish — tornado forming")

	await get_tree().create_timer(TORNADO_TAP_DURATION).timeout

	var killer = _get_nearest_killer(TORNADO_RANGE)
	if killer:
		print("Windy Finish caught 2011X — 50 damage")
		killer.stun(TORNADO_TAP_STUN)

	movement_locked = false
	ability_cooldowns[4] = TORNADO_COOLDOWN
	var hud = _get_hud()
	if hud:
		hud.start_ability_cooldown(4, TORNADO_COOLDOWN)

func _try_sonic_tornado():
	if ability_cooldowns[4] > 0.0:
		return
	_sonic_tornado_sequence()

func _sonic_tornado_sequence():
	print("Sonic Tornado — transformed for 10 seconds")
	movement_locked = false  # player retains control, moving as a tornado
	var elapsed = 0.0
	var tick_timer = 0.0

	while elapsed < TORNADO_HOLD_DURATION:
		await get_tree().physics_frame
		var delta = get_physics_process_delta_time()
		elapsed += delta
		tick_timer += delta

		if tick_timer >= 1.0:
			tick_timer = 0.0
			var killer = _get_nearest_killer(TORNADO_RANGE)
			if killer:
				print("Sonic Tornado hit 2011X — 15 damage")
				killer.stun(TORNADO_HOLD_STUN_TICK)

	print("Sonic Tornado ended")
	ability_cooldowns[4] = TORNADO_COOLDOWN
	var hud = _get_hud()
	if hud:
		hud.start_ability_cooldown(4, TORNADO_COOLDOWN)

# -- Animation State Logic -------------------------------------------------------------------------------
func _update_animation():
	if is_crouching:
		if sprite.animation != "Crouch":
			sprite.play("Crouch")
	elif not is_on_floor():
		if velocity.y < 0:
			if sprite.animation != "Jump":
				sprite.play("Jump")
		else:
			if sprite.animation != "Fall_Start" and sprite.animation != "Fall_Loop":
				sprite.play("Fall_Start")
	elif abs(velocity.x) > 10:
		if sprite.animation != "Run_Start" and sprite.animation != "Run_Loop":
			sprite.play("Run_Start")
	else:
		if sprite.animation != "Idle":
			sprite.play("Idle")

func _on_animation_finished():
	match sprite.animation:
		"Run_Start":
			sprite.play("Run_Loop")
		"Fall_Start":
			sprite.play("Fall_Loop")
		"Land":
			is_landing = false
			_update_animation()
		"Turn":
			is_turning = false
			_update_animation()
		"Jump":
			pass
