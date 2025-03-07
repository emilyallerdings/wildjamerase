extends CanvasLayer

var paused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HSlider.value = AudioServer.get_bus_volume_db(0) + 25
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if !paused:
			pause()
		else:
			unpause()

func _on_h_slider_value_changed(value: float) -> void:
	print(value)
	AudioServer.set_bus_volume_db(0, value - 25)
	pass # Replace with function body.

func unpause():
	visible = false
	Engine.time_scale = 1
	get_tree().paused = false
	paused = false

func pause():
	visible = true
	get_tree().paused = true
	paused = true


func _on_button_2_pressed() -> void:
	unpause()
	pass # Replace with function body.
