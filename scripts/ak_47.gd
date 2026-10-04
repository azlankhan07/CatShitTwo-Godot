extends Area2D

var collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	if not body.has_method("collect_ak47"):
		return

	collected = true
	body.call("collect_ak47")

	hide()
	queue_free()
