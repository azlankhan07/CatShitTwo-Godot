extends Area2D

@export_range(0.05, 60.0, 0.05) var damage_interval: float = 0.5
@export_range(0.0, 100.0, 1.0) var damage_percent: float = 50.0

@onready var damage_timer: Timer = $DamageTimer

var player_inside: Node2D = null


func _ready() -> void:
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	damage_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	damage_timer.stop()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	damage_timer.timeout.connect(_on_damage_timer_timeout)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if not body.has_method("take_damage_percent"):
		return

	player_inside = body
	damage_timer.start()


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		damage_timer.stop()
		player_inside = null


func _on_damage_timer_timeout() -> void:
	if not is_instance_valid(player_inside):
		damage_timer.stop()
		player_inside = null
		return

	if not overlaps_body(player_inside):
		damage_timer.stop()
		player_inside = null
		return

	player_inside.call("take_damage_percent", damage_percent)
