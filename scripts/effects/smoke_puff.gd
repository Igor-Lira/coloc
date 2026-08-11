extends Node2D

var radius := 40.0
var duration := 0.4
var color := Color(0.75, 0.75, 0.78, 0.85)

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(_t / duration, 0.0, 1.0)
	var r := radius * (0.4 + 0.6 * progress)
	var a := color.a * (1.0 - progress)
	var c := Color(color.r, color.g, color.b, a)
	# A small cluster of overlapping puffs rather than one flat circle.
	draw_circle(Vector2.ZERO, r, c)
	draw_circle(Vector2(-r * 0.4, -r * 0.3), r * 0.55, Color(c.r, c.g, c.b, c.a * 0.8))
	draw_circle(Vector2(r * 0.45, -r * 0.2), r * 0.5, Color(c.r, c.g, c.b, c.a * 0.7))
