extends CanvasLayer

signal phase_started

@export var lines: Array[String] = [
	"Ce personnage s'appelle Florian. Il ressemble un peu à Ryan Gosling... mais c'est surtout parce que c'était plus facile de trouver un sprite de Ryan Gosling que d'en dessiner un nouveau. Quoiqu'il en soit, il a besoin de se reposer.",
	"Il s'est endormi sur le canapé en regardant le Tour de France, mais une sale race refuse de le laisser tranquille...",
	"Voyons un peu de quoi Florian est capable, même si personnellement, je n'y crois pas trop.",
]

const CHARS_PER_SECOND := 45.0

var _line_index := 0
var _char_progress := 0.0
var _typing := false

var _label: RichTextLabel
var _ok_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_ui()
	get_tree().paused = true
	_show_line(0)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -170.0
	panel.offset_bottom = -20.0
	panel.offset_left = 40.0
	panel.offset_right = -40.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_top = 18.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = false
	_label.custom_minimum_size = Vector2(0, 90)
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.scroll_active = false
	_label.add_theme_font_size_override("normal_font_size", 20)
	_label.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0))
	box.add_child(_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(button_row)

	_ok_button = Button.new()
	_ok_button.text = "OK"
	_ok_button.custom_minimum_size = Vector2(100, 40)
	_ok_button.pressed.connect(_on_ok_pressed)
	button_row.add_child(_ok_button)


func _process(delta: float) -> void:
	if not _typing:
		return
	_char_progress += CHARS_PER_SECOND * delta
	var total := lines[_line_index].length()
	_label.visible_characters = mini(int(_char_progress), total)
	if _label.visible_characters >= total:
		_typing = false


func _show_line(index: int) -> void:
	_line_index = index
	_label.text = lines[index]
	_char_progress = 0.0
	_label.visible_characters = 0
	_typing = true
	_ok_button.grab_focus()


func _on_ok_pressed() -> void:
	if _typing:
		_char_progress = lines[_line_index].length()
		_label.visible_characters = lines[_line_index].length()
		_typing = false
		return

	if _line_index < lines.size() - 1:
		_show_line(_line_index + 1)
	else:
		_finish()


func _finish() -> void:
	visible = false
	phase_started.emit()
	get_tree().paused = false
	queue_free()
