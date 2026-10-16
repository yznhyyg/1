class_name PortraitMotion
extends Node

## Very subtle idle motion for the static portrait: breathing, tiny tilt and drift.
## The body remains stable; the effect only prevents the page from feeling frozen.

var target: Control
var strength := 1.0
var elapsed := 0.0
var base_position := Vector2.ZERO

func setup(control: Control, motion_strength: float = 1.0) -> void:
	target = control
	strength = motion_strength
	base_position = control.position
	target.pivot_offset = target.size * 0.5
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	elapsed = fmod(elapsed + delta, 100000.0)
	var t := elapsed
	var drift := (sin(t * 0.38 + 0.4) * 0.65 + sin(t * 0.21 + 1.7) * 0.25) * strength
	var tilt := (sin(t * 0.31 + 0.8) * 0.055 + sin(t * 0.17 + 2.0) * 0.02) * strength
	var breath := 1.0 + sin(t * 0.43 + 0.8) * 0.0015 * strength
	target.position = base_position + Vector2(0.0, drift)
	target.rotation = deg_to_rad(tilt)
	target.scale = Vector2(breath, breath)
