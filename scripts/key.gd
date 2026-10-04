extends Area2D

@export var rise_height: float = 140.0
@export var rise_duration: float = 0.5

var key_id: int = 1
var collectible: bool = false


func _ready() -> void:
	hide()
	monitoring = false

	# Detect the player on physics layer 1.
	collision_layer = 0
	collision_mask = 1

	body_entered.connect(on_body_entered)
	$AnimatedSprite2D.play("default")


func reveal() -> void:
	show()

	var tween := create_tween()

	tween.tween_property(
		self,
		"global_position:y",
		global_position.y - rise_height,
		maxf(rise_duration, 0.01)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished

	# Collection starts only after the rise finishes.
	collectible = true
	set_deferred("monitoring", true)


func on_body_entered(body: Node2D) -> void:
	if not collectible or not body.is_in_group("player"):
		return

	if body.get("is_dying") == true:
		return

	if body.has_method("collect_key"):
		collectible = false
		body.call("collect_key", key_id)
		queue_free()
