extends Area2D

# Jules' first power. Channels for 0.5s (fade in), stays active for 1.0s
# (cycling through a color gradient, damaging + shoving any enemy caught in
# its collision out to the edge of the map), then fades out over 0.5s.

const CHANNEL_DURATION := 0.5
const ACTIVE_DURATION := 1.0
const FADEOUT_DURATION := 0.5
const TOTAL_DURATION := CHANNEL_DURATION + ACTIVE_DURATION + FADEOUT_DURATION

const DAMAGE := 300
const MAP_LEFT_X := 20.0
const MAP_RIGHT_X := 1004.0
const GRADIENT_CYCLES := 3.0  # how many full hue loops during the active window
const MAX_ALPHA := 0.6        # stays translucent throughout, never fully opaque
const PUSH_DURATION := 3.0    # safety cap; walking_enemy.gd stops early on arrival

var _t := 0.0
var _hit_enemies: Array = []

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _physics_process(delta: float) -> void:
	_t += delta

	if _t <= CHANNEL_DURATION:
		var fade_in := _t / CHANNEL_DURATION
		_sprite.modulate = Color(1.0, 1.0, 1.0, fade_in * MAX_ALPHA)
	elif _t <= CHANNEL_DURATION + ACTIVE_DURATION:
		var active_t := (_t - CHANNEL_DURATION) / ACTIVE_DURATION
		var hue := fmod(active_t * GRADIENT_CYCLES, 1.0)
		_sprite.modulate = Color.from_hsv(hue, 0.75, 1.0, MAX_ALPHA)
		_check_hits()
	elif _t <= TOTAL_DURATION:
		var fade_out := (_t - CHANNEL_DURATION - ACTIVE_DURATION) / FADEOUT_DURATION
		_sprite.modulate = Color(1.0, 1.0, 1.0, (1.0 - fade_out) * MAX_ALPHA)
	else:
		queue_free()


func _check_hits() -> void:
	for body in get_overlapping_bodies():
		_try_hit(body)


func _try_hit(body: Node) -> void:
	if _hit_enemies.has(body):
		return
	if not body.is_in_group("enemy") or not body.has_method("take_damage"):
		return
	_hit_enemies.append(body)
	body.take_damage(DAMAGE)
	_push_to_edge(body)


func _push_to_edge(body: Node) -> void:
	if not (body is Node2D):
		return
	var node := body as Node2D
	var dest_x: float = MAP_RIGHT_X if node.global_position.x >= global_position.x else MAP_LEFT_X
	if body.has_method("push_toward_x"):
		body.push_toward_x(dest_x, PUSH_DURATION)
