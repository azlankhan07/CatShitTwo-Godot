extends RigidBody2D

@export_range(0.0, 1000.0, 10.0) var minimum_landing_speed: float = 100.0
@export_range(0.0, 1.0, 0.01) var minimum_air_time: float = 0.12
@export_range(0.0, 2.0, 0.05) var landing_sound_cooldown: float = 0.3

var was_supported: bool = false
var air_time: float = 0.0
var previous_down_speed: float = 0.0
var cooldown: float = 0.0


func _ready() -> void:
	# Contact reporting only: mass, damping, shapes and layers stay unchanged.
	max_contacts_reported = maxi(max_contacts_reported, 8)
	contact_monitor = true


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	cooldown = maxf(0.0, cooldown - state.step)
	var supported: bool = false
	for index in state.get_contact_count():
		var normal: Vector2 = state.get_contact_local_normal(index)
		if normal.y < -0.55:
			supported = true
			break
	if supported:
		if not was_supported and air_time >= minimum_air_time:
			if previous_down_speed >= minimum_landing_speed and cooldown <= 0.0:
				cooldown = landing_sound_cooldown
				_play_landing.call_deferred()
		air_time = 0.0
	else:
		air_time += state.step
	was_supported = supported
	previous_down_speed = maxf(state.linear_velocity.y, 0.0)


func _play_landing() -> void:
	var audio: Node = get_tree().get_first_node_in_group("game_audio")
	if audio != null:
		audio.call("play_effect", &"crate_landing", global_position)
