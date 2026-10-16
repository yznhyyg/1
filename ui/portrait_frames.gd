class_name PortraitFrames
extends Node

## Optional frame animation layer for characters with hand or hair motion.
## Files use the convention assets/characters/frames/<id>_idle_0.png ...

var target: TextureRect
var character_id := ""
var frames: Array[Texture2D] = []
const FRAME_RATE := 30.0
const MAX_FRAMES := 64
var elapsed := 0.0
var cycle_length := 1.0

func setup(control: TextureRect) -> void:
	target = control
	set_process(true)

func set_character(id: String) -> void:
	character_id = id
	frames.clear()
	for index in range(MAX_FRAMES):
		var path := "res://assets/characters/frames/%s_idle_%d.png" % [character_id, index]
		if not ResourceLoader.exists(path):
			break
		var texture := load(path) as Texture2D
		if texture != null:
			frames.append(texture)
	elapsed = 0.0
	cycle_length = maxf(float(frames.size()) / FRAME_RATE, 0.1)
	if not frames.is_empty() and is_instance_valid(target):
		target.texture = frames[0]

func _process(delta: float) -> void:
	if frames.size() < 2 or not is_instance_valid(target):
		return
	elapsed = fmod(elapsed + delta, cycle_length)
	var frame_index := mini(int(floor(elapsed * FRAME_RATE)), frames.size() - 1)
	target.texture = frames[frame_index]
