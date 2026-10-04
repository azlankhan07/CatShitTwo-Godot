extends Node2D

@export var bullet_scene: PackedScene

@export_range(1.0, 10000.0, 1.0)
var bullet_speed: float = 2200.0

@export_range(0.0, 100.0, 0.1)
var damage_percent: float = 8.0

@export_range(1.0, 10000.0, 1.0)
var max_distance: float = 1000.0

@export_range(1, 20, 1)
var burst_count: int = 4

@export_range(0.01, 1.0, 0.01)
var burst_gap: float = 0.06

@export_range(0.01, 5.0, 0.01)
var cooldown: float = 0.8

@onready var muzzle: Marker2D = $Muzzle
@onready var flash: AnimatedSprite2D = $Muzzle/MuzzleFlash

var facing: float = 1.0
var remaining: int = 0
var wait_time: float = 0.0

var shooter: CollisionObject2D
var target_group: StringName
var enabled: bool = true
var enemy_shots_fired: int = 0


func _ready() -> void:
	flash.hide()
	flash.animation_finished.connect(flash.hide)


func set_facing(value: float) -> void:
	facing = -1.0 if value < 0.0 else 1.0
	muzzle.position.x = absf(muzzle.position.x) * facing
	flash.scale.x = absf(flash.scale.x) * facing


func try_fire(
	body: CollisionObject2D,
	target: StringName
) -> void:
	if not enabled or remaining > 0 or wait_time > 0.0:
		return

	if bullet_scene == null:
		return

	shooter = body
	target_group = target
	remaining = burst_count
	if target_group == &"enemy":
		_play_audio(&"ak47_burst")

	# One flash at the beginning of each trigger.
	flash.show()
	flash.stop()
	flash.play("default")

	emit_bullet()


func _physics_process(delta: float) -> void:
	if not enabled:
		return

	wait_time = maxf(0.0, wait_time - delta)

	if remaining > 0 and wait_time <= 0.0:
		emit_bullet()


func emit_bullet() -> void:
	if not is_instance_valid(shooter):
		stop_firing()
		return

	var bullet := bullet_scene.instantiate() as Node2D

	bullet.call(
		"setup",
		shooter,
		facing,
		bullet_speed,
		damage_percent,
		max_distance,
		target_group
	)

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	if target_group == &"player":
		enemy_shots_fired += 1
		_play_audio(&"heavy_shot" if enemy_shots_fired % 4 == 0 else &"light_shot")

	remaining -= 1

	# Cooldown begins only after the final bullet.
	wait_time = burst_gap if remaining > 0 else cooldown


func stop_firing() -> void:
	enabled = false
	remaining = 0
	flash.stop()
	flash.hide()


func _play_audio(event: StringName) -> void:
	var audio: Node = get_tree().get_first_node_in_group("game_audio")
	if audio != null:
		audio.call("play_effect", event, muzzle.global_position)
