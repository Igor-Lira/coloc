extends CanvasLayer

var _florian: Node = null
var _carl: Node = null

var _florian_bar: ProgressBar
var _florian_label: Label
var _carl_bar: ProgressBar
var _carl_label: Label


func _ready() -> void:
	_build_ui()
	call_deferred("_find_characters")


func _build_ui() -> void:
	# --- Florian HP (top-left) ---
	var fl_box := VBoxContainer.new()
	fl_box.position = Vector2(20, 16)
	add_child(fl_box)

	_florian_label = Label.new()
	_florian_label.text = "Florian"
	_florian_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	fl_box.add_child(_florian_label)

	_florian_bar = ProgressBar.new()
	_florian_bar.custom_minimum_size = Vector2(220, 22)
	_florian_bar.max_value = 100
	_florian_bar.value = 100
	_florian_bar.show_percentage = false
	var fl_fill := StyleBoxFlat.new()
	fl_fill.bg_color = Color(0.15, 0.75, 0.25)
	fl_fill.corner_radius_top_left = 4
	fl_fill.corner_radius_top_right = 4
	fl_fill.corner_radius_bottom_left = 4
	fl_fill.corner_radius_bottom_right = 4
	_florian_bar.add_theme_stylebox_override("fill", fl_fill)
	fl_box.add_child(_florian_bar)

	# --- Carl HP (top-right) ---
	var carl_box := VBoxContainer.new()
	carl_box.position = Vector2(1040, 16)
	add_child(carl_box)

	_carl_label = Label.new()
	_carl_label.text = "Carl"
	_carl_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	carl_box.add_child(_carl_label)

	_carl_bar = ProgressBar.new()
	_carl_bar.custom_minimum_size = Vector2(220, 22)
	_carl_bar.max_value = 200
	_carl_bar.value = 200
	_carl_bar.show_percentage = false
	var carl_fill := StyleBoxFlat.new()
	carl_fill.bg_color = Color(0.75, 0.15, 0.1)
	carl_fill.corner_radius_top_left = 4
	carl_fill.corner_radius_top_right = 4
	carl_fill.corner_radius_bottom_left = 4
	carl_fill.corner_radius_bottom_right = 4
	_carl_bar.add_theme_stylebox_override("fill", carl_fill)
	carl_box.add_child(_carl_bar)


func _find_characters() -> void:
	var players := get_tree().get_nodes_in_group("player")
	var enemies := get_tree().get_nodes_in_group("enemy")
	if players.size() > 0:
		_florian = players[0]
		_florian_bar.max_value = _florian.MAX_HP
	if enemies.size() > 0:
		_carl = enemies[0]
		_carl_bar.max_value = _carl.MAX_HP


func _process(_delta: float) -> void:
	if is_instance_valid(_florian):
		_florian_bar.value = _florian.hp
		_florian_label.text = "Florian  %d / %d" % [_florian.hp, _florian.MAX_HP]

	if is_instance_valid(_carl):
		_carl_bar.value = _carl.hp
		_carl_label.text = "Carl  %d / %d" % [_carl.hp, _carl.MAX_HP]
	else:
		_carl_bar.value = 0
		_carl_label.text = "Carl — WHAT"
