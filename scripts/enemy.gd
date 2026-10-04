extends CharacterBody2D

signal died
signal health_changed(current_health: float, maximum_health: float)

@export var detection_range: float = 3000.0
@export var y_tolerance: float = 60.0
@export var artwork_faces_right: bool = true

@export var key_scene: PackedScene

@export_range(1, 2, 1)
var key_id: int = 1

@export var key_scale: float = 0.25

@export var death_hold: float = 0.8
@export var fade_duration: float = 0.3
@export var key_delay: float = 0.5

const MAX_HEALTH: float = 100.0

var health: float = MAX_HEALTH
var is_dying: bool = false
var player: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var gun: Node2D = $Gun
@onready var muzzle: Marker2D = $Gun/Muzzle
@onready var recovery: Node = $HealthRecovery


func _ready() -> void:
	add_to_group("enemy")
	sprite.play("default")

	player = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(_delta: float) -> void:
	if is_dying:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		return

	if player.get("is_dying") == true:
		return

	var dx: float = player.global_position.x - global_position.x
	var facing: float = -1.0 if dx < 0.0 else 1.0

	sprite.flip_h = (
		(facing < 0.0)
		if artwork_faces_right
		else (facing > 0.0)
	)

	gun.call("set_facing", facing)

	var target_point := player.get_node("TargetPoint") as Node2D

	if absf(dx) > detection_range:
		return

	if absf(
		target_point.global_position.y - muzzle.global_position.y
	) > y_tolerance:
		return

	gun.call("try_fire", self, &"player")


func take_damage_percent(percent: float) -> void:
	take_damage(
		MAX_HEALTH * clampf(percent, 0.0, 100.0) / 100.0
	)


func take_damage(amount: float) -> void:
	if is_dying or amount <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	recovery.call("note_damage")
	health_changed.emit(health, MAX_HEALTH)

	if health <= 0.0:
		die()


func heal_percent(percent: float) -> void:
	if is_dying or health <= 0.0:
		return
	health = minf(MAX_HEALTH, health + MAX_HEALTH * maxf(percent, 0.0) / 100.0)
	health_changed.emit(health, MAX_HEALTH)


func die() -> void:
	if is_dying:
		return
	is_dying = true
	died.emit()

	gun.call("stop_firing")
	set_physics_process(false)

	$CollisionShape2D.set_deferred("disabled", true)

	sprite.play("enemy_death")
	sprite.set_frame_and_progress(0, 0.0)

	await sprite.animation_finished

	# Hold the final death frame.
	await get_tree().create_timer(death_hold).timeout

	# Fade away.
	var tween := create_tween()
	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		fade_duration
	)

	await tween.finished

	# Wait before revealing the key.
	await get_tree().create_timer(key_delay).timeout

	if key_scene != null:
		var key := key_scene.instantiate() as Node2D

		key.set("key_id", key_id)

		get_tree().current_scene.add_child(key)
		key.global_position = global_position
		key.global_scale = Vector2.ONE * key_scale

		key.call("reveal")

	queue_free()
