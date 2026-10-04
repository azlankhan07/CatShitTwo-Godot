extends CharacterBody2D

const SPEED: float = 500.0
const JUMP_VELOCITY: float = -900.0
const PUSH_FORCE: float = 2200.0
var has_gun: bool = false
var is_dying: bool = false

@onready var gun: Node2D = $Gun
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal health_changed(current_health: float, maximum_health: float)
signal died
signal keys_changed(count: int)

const MAX_HEALTH: float = 100.0
var health: float = MAX_HEALTH
var collected_keys: Array[int] = []

@onready var recovery: Node = $HealthRecovery


func _physics_process(delta: float) -> void:
	var was_grounded: bool = is_on_floor()
	if not is_on_floor():
		velocity += get_gravity() * 2 * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	# Face the direction of movement.
	if direction < 0.0:
		sprite.flip_h = true
	elif direction > 0.0:
		sprite.flip_h = false

	# Choose animations based on movement and gun ownership.
	if has_gun:
		if not is_zero_approx(direction):
			sprite.play("gun_running")
		else:
			sprite.play("gun_idle")
	else:
		if not is_zero_approx(direction):
			sprite.play("run")
		else:
			sprite.play("default")

	var landing_speed: float = velocity.y
	move_and_slide()
	if not was_grounded and is_on_floor() and landing_speed >= 100.0:
		var audio: Node = get_tree().get_first_node_in_group("game_audio")
		if audio != null:
			audio.call("play_effect", &"landing", global_position)
	_push_crates(direction)

	var facing: float = -1.0 if sprite.flip_h else 1.0
	gun.call("set_facing", facing)

	if has_gun and Input.is_action_just_pressed("shoot"):
		gun.call("try_fire", self, &"enemy")


func _push_crates(direction: float) -> void:
	if is_zero_approx(direction):
		return

	var pushed: Array[RigidBody2D] = []

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var crate := collision.get_collider() as RigidBody2D

		if crate == null:
			continue

		if not crate.is_in_group("pushable"):
			continue

		# Push only when moving into the side of the crate.
		if direction * collision.get_normal().x > -0.5:
			continue

		# Avoid applying the force twice to the same crate.
		if pushed.has(crate):
			continue

		pushed.append(crate)
		if crate.linear_velocity.x * direction < SPEED:
			crate.apply_central_force(
				Vector2(direction * PUSH_FORCE, 0.0)
			)
func collect_ak47() -> void:
	if is_dying:
		return

	has_gun = true

func take_damage_percent(percent: float) -> void:
	var damage: float = MAX_HEALTH * clampf(percent, 0.0, 100.0) / 100.0
	take_damage(damage)


func take_damage(amount: float) -> void:
	if is_dying or health <= 0.0 or amount <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	recovery.call("note_damage")

	health_changed.emit(health, MAX_HEALTH)
	print("Player health: ", health)

	if health <= 0.0:
		_die()


func heal_percent(percent: float) -> void:
	if is_dying or health <= 0.0:
		return
	health = minf(MAX_HEALTH, health + MAX_HEALTH * maxf(percent, 0.0) / 100.0)
	health_changed.emit(health, MAX_HEALTH)

func _die() -> void:
	if is_dying:
		return

	is_dying = true
	gun.call("stop_firing")

	# Stop movement, jumping, pushing, and normal animation updates.
	velocity = Vector2.ZERO
	set_physics_process(false)

	died.emit()

	# Use the exact animation names from your SpriteFrames resource.
	var death_animation: StringName = &"dying_idle"

	if has_gun:
		death_animation = &"dying_Gun"

	# Play the death animation from its beginning.
	sprite.play(death_animation)
	sprite.set_frame_and_progress(0, 0.0)

	await sprite.animation_finished

	# Keep the final death frame visible.
	sprite.pause()
	sprite.frame = sprite.sprite_frames.get_frame_count(
		death_animation
	) - 1

	# Hold that final frame for 0.6 seconds.
	await get_tree().create_timer(0.6).timeout

	get_tree().reload_current_scene()

func collect_key(id: int) -> void:
	if is_dying or collected_keys.has(id):
		return

	collected_keys.append(id)
	keys_changed.emit(collected_keys.size())

	print("Keys: ", collected_keys.size(), "/2")
