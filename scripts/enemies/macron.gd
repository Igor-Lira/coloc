extends "res://scripts/enemies/walking_enemy.gd"

# Macron always walks toward Jules, and every few seconds channels for a
# second (flashing color, standing still) before teleporting next to him,
# with a smoke puff at both the spot he vanishes from and appears at.

const TELEPORT_INTERVAL := 5.0
const TELEPORT_OFFSET_MIN := 60.0
const TELEPORT_OFFSET_MAX := 110.0
const CHASE_DEADZONE := 20.0
const CHANNEL_DURATION := 1.0
const CHANNEL_COLOR := Color(1.7, 0.4, 1.9)  # magenta flash while channeling
const SMOKE_SCENE := preload("res://scenes/effects/smoke_puff.tscn")

enum State { NORMAL, CHANNELING }

var _state := State.NORMAL
var _teleport_timer := TELEPORT_INTERVAL
var _channel_timer := 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	match _state:
		State.NORMAL:
			_teleport_timer -= delta
			if _teleport_timer <= 0.0:
				_enter_channel()
		State.CHANNELING:
			_channel_timer -= delta
			var flash := fmod(_channel_timer, 0.2) < 0.1
			_sprite.modulate = CHANNEL_COLOR if flash else Color.WHITE
			if _channel_timer <= 0.0:
				_sprite.modulate = Color.WHITE
				_teleport_near_jules()
				_state = State.NORMAL
				_teleport_timer = TELEPORT_INTERVAL


func _decide_patrol_dir() -> float:
	if _state == State.CHANNELING:
		return 0.0  # stand still while channeling

	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return _patrol_dir

	var target_x: float = (players[0] as Node2D).global_position.x
	var dx := target_x - global_position.x
	if absf(dx) <= CHASE_DEADZONE:
		return 0.0
	return signf(dx)


func _enter_channel() -> void:
	_state = State.CHANNELING
	_channel_timer = CHANNEL_DURATION


func _teleport_near_jules() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var jules := players[0] as Node2D

	_spawn_smoke(global_position)

	var side := 1.0 if randf() < 0.5 else -1.0
	var offset := randf_range(TELEPORT_OFFSET_MIN, TELEPORT_OFFSET_MAX)
	var dest_x := clampf(jules.global_position.x + side * offset, patrol_min_x, patrol_max_x)
	global_position = Vector2(dest_x, jules.global_position.y - 100.0)
	velocity = Vector2.ZERO

	_spawn_smoke(global_position)


func _spawn_smoke(at: Vector2) -> void:
	var smoke := SMOKE_SCENE.instantiate()
	get_tree().current_scene.add_child(smoke)
	smoke.global_position = at
