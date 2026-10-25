extends SceneTree

const Effects = preload("res://ui/hit_effects.gd")
const Game = preload("res://main.gd")
var checks := 0
var failures := 0

class TestGame extends Game:
	func _ready() -> void:
		set_process(false)

class TestNote extends Node:
	var lane := 0
	var hit_time := 0.0
	var judged := false
	var is_hold := false
	var holding := false
	var head_result := "Good"
	var hold_start_time := 0.0
	var hold_finished := false
	var duration := 1.0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game := TestGame.new()
	var playfield := Node2D.new()
	playfield.name = "PlayField"
	game.add_child(playfield)
	var music := AudioStreamPlayer.new()
	music.name = "MusicPlayer"
	game.add_child(music)
	var ui := CanvasLayer.new()
	ui.name = "UI"
	game.add_child(ui)
	root.add_child(game)
	game.points_per_key = 100.0
	game.lane_start_x = 120.0
	game.lane_width = 120.0
	game.top_judge_line_y = 100.0
	game.bottom_judge_line_y = 1180.0
	for example in [[0.01, "Perfect", 100.0], [0.1, "Great", 70.0], [0.16, "Good", 40.0]]:
		var note := TestNote.new()
		note.hit_time = float(example[0])
		game.add_child(note)
		game.active_notes = [note]
		var before: float = game.score
		game._try_judge_lane(0)
		check(note.judged, "tap judged")
		check(is_equal_approx(game.score - before, float(example[2])), "effect preserves scoring")
		check(game.hit_effects.bursts.back()["color"] == Effects.COLORS[example[1]], "judgment maps to correct effect color")
		check(game.hit_effects.bursts.back()["center"] == Vector2(180, 1180), "lower hit centered on lane and judgment line")
	game._show_hit_effect("Great", 6)
	check(game.hit_effects.bursts.back()["center"] == Vector2(420, 100), "upper hit centered on upper line")
	check(game.hit_effects.bursts.back()["upper"], "upper hit is mirrored")
	var count: int = game.hit_effects.bursts.size()
	game._show_hit_effect("Miss", 0)
	game._show_hit_effect("Perfect", -1)
	check(game.hit_effects.bursts.size() == count, "miss and invalid lane do not emit")
	var hold := TestNote.new()
	hold.lane = 4
	hold.is_hold = true
	game.add_child(hold)
	game.active_notes = [hold]
	var before_hold: float = game.score
	game._try_judge_lane(4)
	check(hold.holding and game.hit_effects.bursts.size() == count + 1, "hold head emits immediately")
	check(game.score == before_hold, "hold head does not add premature score")
	game._finish_hold(hold, 0.5)
	check(game.hit_effects.bursts.back()["color"] == Effects.COLORS["Great"], "early hold release uses final downgraded judgment")
	check(is_equal_approx(game.score - before_hold, 70.0), "hold scoring unchanged")
	for index in range(100):
		game._show_hit_effect("Perfect", index % 8)
	check(game.hit_effects.bursts.size() == Effects.MAX_BURSTS, "dense chords have bounded effect count")
	check(game.hit_effects.process_mode == Node.PROCESS_MODE_PAUSABLE, "effects pause with playfield")
	# Exercise every draw phase, including the closed arc tips and expiration.
	for step in range(24):
		game.hit_effects._process(Effects.LIFETIME / 20.0)
		await process_frame
	check(game.hit_effects.bursts.is_empty(), "bursts fully expire")
	check(not game.hit_effects.is_processing(), "idle effect layer stops processing")
	game.queue_free()
	await process_frame
	print("Hit effect tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
