extends CharacterBody2D

const MAX_HP := 1000
const PATROL_SPEED := 70.0
const DASH_SPEED := 1500.0
const GRAVITY := 980.0

# Occasional hop while patrolling
const JUMP_VELOCITY := -420.0
const MIN_JUMP_INTERVAL := 2.0
const MAX_JUMP_INTERVAL := 5.0
var _jump_timer := 0.0

const MIN_DASH_INTERVAL := 3.0
const MAX_DASH_INTERVAL := 7.0
const CHARGE_DURATION := 0.5   # warning flash before dash
const DASH_DURATION    := 0.45  # how long the dash lasts
const COOLDOWN_DURATION := 2.5  # rest after dash

# Damage dealt to player on hit
const DASH_DAMAGE := 40
const KNOCKBACK := Vector2(600.0, -280.0)  # applied in dash direction

# --- Second attack: spiral burst, fired every time Carl takes damage ---
const SHOT_SCENE := preload("res://scenes/enemies/carl_shot.tscn")
const SPIRAL_ANGLE_STEP := 0.4189  # ~24 deg between consecutive shots -> spiral arms
const SPIRAL_SHOT_INTERVAL := 0.03  # seconds between shots in a burst
var _spiral_angle := 0.0

# --- Damage reaction: charges toward Florian, faster the more damage he's
# taken in the trailing window (overrides normal movement while active) ---
const STAGGER_WINDOW := 3.0            # seconds of damage history considered
const STAGGER_MIN_SPEED := 40.0        # base speed once triggered
const STAGGER_SPEED_PER_DAMAGE := 2.0  # extra px/s per point of damage taken in the window
var _damage_events: Array = []  # [{amount: int, t: float}, ...]

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

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _trail: Line2D = $Trail


func _ready() -> void:
	add_to_group("enemy")
	_timer = _next_dash_interval()
	_jump_timer = _next_jump_interval()
	_setup_trail()
	_setup_animations()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_timer -= delta
	_jump_timer -= delta

	match _state:
		State.PATROL:   _tick_patrol()
		State.CHARGING: _tick_charge()
		State.DASHING:  _tick_dash(delta)
		State.COOLDOWN: _tick_cooldown()

	# Don't let the stagger reaction fight the charge/dash (move attack) —
	# it was overriding DASHING's velocity, so Carl would stall near Florian
	# instead of completing the dash whenever he'd recently taken damage.
	var stagger_speed := _stagger_speed()
	if stagger_speed > 0.0 and _state != State.CHARGING and _state != State.DASHING:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var target_x: float = (players[0] as Node2D).global_position.x
			velocity.x = signf(target_x - global_position.x) * stagger_speed

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

	if is_on_floor() and _jump_timer <= 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_timer = _next_jump_interval()

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
	# Enraged below 40% HP: the dash covers 1.5x the distance (same speed, longer duration)
	_timer = DASH_DURATION * (1.5 if _hp_percent() < 40.0 else 1.0)
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
		_timer = _next_dash_interval()


# ---------------------------------------------------------------------------
# Enrage helpers
# ---------------------------------------------------------------------------

const ENRAGE_HP_PERCENT := 30.0
const ENRAGE_FREQUENCY_MULT := 1.3  # 30% more often below the enrage threshold


func _hp_percent() -> float:
	return float(hp) / float(MAX_HP) * 100.0


func _next_dash_interval() -> float:
	var t := randf_range(MIN_DASH_INTERVAL, MAX_DASH_INTERVAL)
	return t / ENRAGE_FREQUENCY_MULT if _hp_percent() < ENRAGE_HP_PERCENT else t


func _next_jump_interval() -> float:
	var t := randf_range(MIN_JUMP_INTERVAL, MAX_JUMP_INTERVAL)
	return t / ENRAGE_FREQUENCY_MULT if _hp_percent() < ENRAGE_HP_PERCENT else t


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

	# Static pose when idle/patrolling, cycling frames while dashing
	_sprite.play("move" if _state == State.DASHING else "idle")

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
# Animation setup
# ---------------------------------------------------------------------------

func _setup_animations() -> void:
	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", load("res://assets/characters/carl_enemy/move_01.png"))

	frames.add_animation("move")
	frames.set_animation_loop("move", true)
	frames.set_animation_speed("move", 8.0)
	for i in range(1, 5):
		var tex := load("res://assets/characters/carl_enemy/move_%02d.png" % i) as Texture2D
		if tex:
			frames.add_frame("move", tex)
		else:
			push_warning("Missing frame: move_%02d.png" % i)

	_sprite.sprite_frames = frames
	_sprite.play("idle")


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	if hp == 0:
		queue_free()
		return

	_damage_events.append({"amount": amount, "t": Time.get_ticks_msec() / 1000.0})
	_fire_spiral_burst()


# ---------------------------------------------------------------------------
# Damage reaction (charge toward Florian, faster with recent damage)
# ---------------------------------------------------------------------------

func _stagger_speed() -> float:
	var now := Time.get_ticks_msec() / 1000.0
	while _damage_events.size() > 0 and now - _damage_events[0]["t"] > STAGGER_WINDOW:
		_damage_events.pop_front()

	var total_damage := 0
	for e in _damage_events:
		total_damage += e["amount"]

	if total_damage <= 0:
		return 0.0
	return STAGGER_MIN_SPEED + total_damage * STAGGER_SPEED_PER_DAMAGE


# ---------------------------------------------------------------------------
# Second attack: spiral projectile burst (triggered on taking damage)
# ---------------------------------------------------------------------------

func _fire_spiral_burst() -> void:
	var hp_pct := _hp_percent()
	var count := 10
	if hp_pct < 50.0:
		count = 30
	elif hp_pct < 80.0:
		count = 20

	for i in range(count):
		if hp <= 0 or not is_inside_tree():
			return
		_spawn_shot(_spiral_angle)
		_spiral_angle += SPIRAL_ANGLE_STEP
		await get_tree().create_timer(SPIRAL_SHOT_INTERVAL).timeout


func _spawn_shot(angle: float) -> void:
	var shot := SHOT_SCENE.instantiate()
	get_tree().current_scene.add_child(shot)
	shot.global_position = global_position
	shot.velocity = Vector2.RIGHT.rotated(angle) * shot.SPEED
