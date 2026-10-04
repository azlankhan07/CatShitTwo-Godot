extends Node

## Every new hit restarts the delay. First recovery tick is at delay + interval.
@export var recovery_delay: float = 10.0
@export var recovery_interval: float = 2.0
@export var recovery_percent: float = 5.0

var quiet_time: float = 0.0
var tick_time: float = 0.0


func note_damage() -> void:
	quiet_time = 0.0
	tick_time = 0.0


func _physics_process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	var character: Node = get_parent()
	if character.get("is_dying") == true:
		return
	if float(character.get("health")) >= 100.0:
		tick_time = 0.0
		return
	var previous_time: float = quiet_time
	quiet_time += delta
	# Count only the portion of this step after the no-damage delay.
	var eligible: float = quiet_time - maxf(previous_time, recovery_delay)
	if eligible <= 0.0:
		return
	tick_time += eligible
	while tick_time + 0.00001 >= maxf(recovery_interval, 0.01):
		tick_time -= maxf(recovery_interval, 0.01)
		character.call("heal_percent", recovery_percent)

