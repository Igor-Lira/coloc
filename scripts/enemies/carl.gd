extends CharacterBody2D

const MAX_HP := 200
const PATROL_SPEED := 70.0
const DASH_SPEED := 1500.0
const GRAVITY := 980.0

const MIN_DASH_INTERVAL := 3.0
const MAX_DASH_INTERVAL := 7.0
const CHARGE_DURATION := 0.5   # warning flash before dash
const DASH_DURATION    := 0.45  # how long the dash lasts
const COOLDOWN_DURATION := 2.5  # rest after dash

# Damage dealt to player on hit
const DASH_DAMAGE := 40
const KNOCKBACK := Vector2(600.0, -280.0)  # applied in dash direction

enum State { PATROL, CHARGING, DASHING, COOLDOWN }

var hp := MAX_HP
var _state := State.PATROL
var _timer := 0.0
var _patrol_dir := 1.0   # current patrol direction
var _dash_dir := 1.0     # direction of the upcoming/current dash
var _hit_player := false  # prevent double-hit per dash

# Trail stores recent world-space positions
const TRAIL_LEN := 16
var _trail_world: Array[Vector2] = []

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _trail: Line2D = $Trail


func _ready() -> void:
	add_to_group("enemy")
	_timer = randf_range(MIN_DASH_INTERVAL, MAX_DASH_INTERVAL)
	_setup_trail()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_timer -= delta

	match _state:
		State.PATROL:   _tick_patrol()
		State.CHARGING: _tick_charge()
		State.DASHING:  _tick_dash(delta)
		State.COOLDOWN: _tick_cooldown()

	move_and_slide()
	_update_trail()
	_update_visuals()


# ---------------------------------------------------------------------------
# State handlers
# ---------------------------------------------------------------------------

func _tick_patrol() -> void:
	velocity.x = PATROL_SPEED * _patrol_dir

	# Bounce at room edges
	if global_position.x <= 80.0:
		_patrol_dir = 1.0
	elif global_position.x >= 1115.0:
		_patrol_dir = -1.0

	_trail.visible = false

	if _timer <= 0.0:
		_enter_charge()


func _enter_charge() -> void:
	_state = State.CHARGING
	_timer = CHARGE_DURATION
	velocity.x = 0.0

	# Lock onto player direction
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var px: float = (players[0] as Node2D).global_position.x
		_dash_dir = 1.0 if px >= global_position.x else -1.0
	else:
		_dash_dir = _patrol_dir


func _tick_charge() -> void:
	velocity.x = 0.0
	if _timer <= 0.0:
		_enter_dash()


func _enter_dash() -> void:
	_state = State.DASHING
	_timer = DASH_DURATION
	_hit_player = false
	_trail_world.clear()
	_trail.visible = true


func _tick_dash(delta: float) -> void:
	velocity.x = DASH_SPEED * _dash_dir

	# Check proximity to player (manual check avoids tunneling at high speed)
	if not _hit_player:
		var players := get_tree().get_nodes_in_group("player")
		for p in players:
			var node := p as CharacterBody2D
			if node == null:
				continue
			var dx := absf(node.global_position.x - global_position.x)
			var dy := absf(node.global_position.y - global_position.y)
			if dx < 65.0 and dy < 100.0:
				node.take_damage(DASH_DAMAGE, Vector2(_dash_dir * KNOCKBACK.x, KNOCKBACK.y))
				_hit_player = true
				break

	if _timer <= 0.0 or global_position.x <= 15.0 or global_position.x >= 1180.0:
		_enter_cooldown()


func _enter_cooldown() -> void:
	_state = State.COOLDOWN
	_timer = COOLDOWN_DURATION
	velocity.x = 0.0
	_trail.visible = false
	_trail_world.clear()
	_trail.clear_points()


func _tick_cooldown() -> void:
	velocity.x = 0.0
	if _timer <= 0.0:
		_state = State.PATROL
		_patrol_dir = _dash_dir
		_timer = randf_range(MIN_DASH_INTERVAL, MAX_DASH_INTERVAL)


# ---------------------------------------------------------------------------
# Trail
# ---------------------------------------------------------------------------

func _setup_trail() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0.3, 0.85, 1.0, 0.95))  # bright tip
	grad.set_color(1, Color(0.1, 0.4, 1.0, 0.0))    # transparent tail
	_trail.gradient = grad
	_trail.width = 22.0
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND


func _update_trail() -> void:
	if _state != State.DASHING:
		return
	_trail_world.push_front(global_position)
	if _trail_world.size() > TRAIL_LEN:
		_trail_world.pop_back()
	_trail.clear_points()
	for wp in _trail_world:
		_trail.add_point(to_local(wp))


# ---------------------------------------------------------------------------
# Visuals
# ---------------------------------------------------------------------------

func _update_visuals() -> void:
	# Face movement direction
	var facing_dir := _dash_dir if (_state == State.DASHING or _state == State.CHARGING) else _patrol_dir
	_sprite.flip_h = facing_dir < 0.0

	match _state:
		State.CHARGING:
			# Yellow warning flash
			var t := fmod(Time.get_ticks_msec() * 0.008, 1.0)
			_sprite.modulate = Color(1.6, 1.2, 0.1) if t < 0.5 else Color.WHITE
		State.DASHING:
			_sprite.modulate = Color(0.5, 0.85, 2.2)  # electric blue
		_:
			_sprite.modulate = Color.WHITE


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	if hp == 0:
		queue_free()
