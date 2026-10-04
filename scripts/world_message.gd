extends Label

var generation: int = 0


func show_for(seconds: float) -> void:
	generation += 1
	var current: int = generation
	show()
	if seconds <= 0.0:
		return
	await get_tree().create_timer(seconds, false).timeout
	if current == generation:
		hide()

