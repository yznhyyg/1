extends Control

## Shared illustrated background for the entry and login scenes.
const BACKGROUND_TEXTURE = preload("res://assets/backgrounds/entry_atrium.png")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	# The artwork uses the same portrait ratio as the game's 720x1280 viewport.
	draw_texture_rect(BACKGROUND_TEXTURE, Rect2(Vector2.ZERO, size), false)
	# Keep form fields and labels readable without hiding the artwork.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.10, 0.34))
