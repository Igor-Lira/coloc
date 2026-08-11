extends Node2D

var radius := 70.0
var color := Color(0.25, 0.6, 1.0, 0.75)

var _t := 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.85 + 0.15 * sin(_t * 8.0)
	# Soft outer halo, bright mid glow, and a crisp rim so it reads clearly at a glance.
	draw_circle(Vector2.ZERO, radius * pulse * 1.5, Color(color.r, color.g, color.b, color.a * 0.25))
	draw_circle(Vector2.ZERO, radius * pulse, Color(color.r, color.g, color.b, color.a))
	draw_arc(Vector2.ZERO, radius * pulse + 5.0, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, 1.0), 5.0, true)
