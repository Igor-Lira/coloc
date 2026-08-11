extends Node

# Ambient random Jules voice lines for this phase only — picks a random clip
# from assets/audios/random_jules/ and plays it every INTERVAL seconds.

const INTERVAL := 7.0
const STREAMS := [
	preload("res://assets/audios/random_jules/1.mp3"),
	preload("res://assets/audios/random_jules/2.mp3"),
	preload("res://assets/audios/random_jules/3.mp3"),
	preload("res://assets/audios/random_jules/4.mp3"),
	preload("res://assets/audios/random_jules/5.mp3"),
]

var _timer := INTERVAL

@onready var _player: AudioStreamPlayer = $AudioStreamPlayer


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = INTERVAL
		_play_random()


func _play_random() -> void:
	_player.stream = STREAMS[randi() % STREAMS.size()]
	_player.play()
