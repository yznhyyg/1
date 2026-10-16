class_name PortraitMotion
extends Node

## A small keyframe rig for a static full-body illustration.
## The six poses are interpolated with smoothstep so the character feels alive
## while the original artwork stays perfectly consistent.

var target: Control
var strength := 1.0
var elapsed := 0.0
var base_position := Vector2.ZERO
var cycle_seconds := 7.2

var keyframes := [
	{"offset": Vector2(0.0, 0.0), "rotation": 0.00, "scale": 1.000},
	{"offset": Vector2(0.7, -2.4), "rotation": -0.14, "scale": 1.003},
	{"offset": Vector2(-0.5, -3.8), "rotation": -0.08, "scale": 1.006},
	{"offset": Vector2(-1.0, -1.4), "rotation": 0.10, "scale": 1.002},
	{"offset": Vector2(0.6, 1.8), "rotation": 0.15, "scale": 0.998},
	{"offset": Vector2(0.0, 0.0), "rotation": 0.00, "scale": 1.000}
]

func setup(control: Control, motion_strength: float = 1.0) -> void:
	target = control
	strength = motion_strength
	base_position = control.position
	target.pivot_offset = target.size * 0.5
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	elapsed = fmod(elapsed + delta, cycle_seconds)
	var progress := elapsed / cycle_seconds * float(keyframes.size() - 1)
	var index := mini(int(floor(progress)), keyframes.size() - 2)
	var local_t := _smoothstep(progress - float(index))
	var from_pose: Dictionary = keyframes[index]
	var to_pose: Dictionary = keyframes[index + 1]
	var from_offset: Vector2 = from_pose["offset"]
	var to_offset: Vector2 = to_pose["offset"]
	var offset := from_offset.lerp(to_offset, local_t) * strength
	var rotation := lerpf(float(from_pose["rotation"]), float(to_pose["rotation"]), local_t) * strength
	var scale_value := lerpf(float(from_pose["scale"]), float(to_pose["scale"]), local_t)
	target.position = base_position + offset
	target.rotation = deg_to_rad(rotation)
	target.scale = Vector2(scale_value, scale_value)

func _smoothstep(value: float) -> float:
	return value * value * (3.0 - 2.0 * value)
