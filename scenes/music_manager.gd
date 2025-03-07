extends Node

@onready var track1 = $Music
@onready var track2 = $Fight

var current_track = 1
var fading = false  # Prevents multiple fade calls

var fade_out = 2
var fade_in = 0.5
var min_vol = -50


var cur_pos = 0

func _ready():
	track1.volume_db = 0  # Normal volume
	track2.volume_db = min_vol  # Fully silent
	track1.play(0)

func _process(delta):
	# Switch to Track2 when wave_timer reaches 2 (only once)
	if %WaveTimer.time_left <= fade_out and current_track == 1 and not fading:
		fade_to_track(2)
	

func fade_to_track(next_track):
	var tween = get_tree().create_tween()

	fading = true  # Lock state to prevent multiple calls

	if next_track == 2:
		current_track = 2
		var out_tween = get_tree().create_tween().tween_property(track1, "volume_db", min_vol, fade_out).set_trans(Tween.TRANS_LINEAR)
		track2.play(2.8)
		get_tree().create_tween().tween_property(track2, "volume_db", 0, fade_in).set_trans(Tween.TRANS_LINEAR)
		await out_tween.finished
		track1.stream_paused = true
	else:
		current_track = 1
		track1.stream_paused = false
		var out_tween = get_tree().create_tween().tween_property(track2, "volume_db", min_vol, fade_out).set_trans(Tween.TRANS_LINEAR)
		get_tree().create_tween().tween_property(track1, "volume_db", 0, fade_in).set_trans(Tween.TRANS_LINEAR)
		await out_tween.finished
		track2.stop()

	fading = false  # Unlock after fade is cosmplete

func should_switch_back():
	fade_to_track(1)
