extends Node2D

var radius := 100.0
var duration := 0.3
var color := Color(1.0, 0.55, 0.15, 0.85)

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(_t / duration, 0.0, 1.0)
	var r := radius * progress
	var a := color.a * (1.0 - progress)
	draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, a))
