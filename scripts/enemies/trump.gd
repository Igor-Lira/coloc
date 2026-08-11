extends "res://scripts/enemies/walking_enemy.gd"

# Trump always walks toward Jules instead of bouncing between patrol bounds,
# and hops every few seconds — sometimes chaining into a double or triple jump.

const JUMP_INTERVAL := 3.0
const JUMP_VELOCITY := -420.0
const MULTI_JUMP_GAP := 0.3   # seconds between chained jumps
const CHASE_DEADZONE := 20.0  # stop jittering once this close to Jules

const BOMB_SCENE := preload("res://scenes/enemies/trump_bomb.tscn")
const BOMB_INTERVAL := 2.0

var _jump_timer := JUMP_INTERVAL
var _jumps_remaining := 0
var _jump_gap_timer := 0.0
var _bomb_timer := BOMB_INTERVAL


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if _jumps_remaining > 0:
		if _jump_gap_timer > 0.0:
			_jump_gap_timer -= delta
		else:
			velocity.y = JUMP_VELOCITY
			_jumps_remaining -= 1
			_jump_gap_timer = MULTI_JUMP_GAP
	else:
		_jump_timer -= delta
		if _jump_timer <= 0.0 and is_on_floor():
			_jump_timer = JUMP_INTERVAL
			_jumps_remaining = _roll_jump_count()
			_jump_gap_timer = 0.0

	_bomb_timer -= delta
	if _bomb_timer <= 0.0:
		_bomb_timer = BOMB_INTERVAL
		_throw_bomb()


func _decide_patrol_dir() -> float:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return _patrol_dir

	var target_x: float = (players[0] as Node2D).global_position.x
	var dx := target_x - global_position.x
	if absf(dx) <= CHASE_DEADZONE:
		return 0.0
	return signf(dx)


func _roll_jump_count() -> int:
	var roll := randf()
	if roll < 0.3:
		return 2  # 30% chance: double jump
	elif roll < 0.6:
		return 3  # 30% chance: triple jump
	return 1      # remaining 40%: a single jump


func _throw_bomb() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var jules := players[0] as Node2D

	var bomb := BOMB_SCENE.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = global_position
	bomb.start_pos = global_position
	bomb.target_pos = jules.global_position
