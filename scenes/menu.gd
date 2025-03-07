extends Control

const MAIN = preload("res://scenes/main.tscn")
var spawn_part = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	#await get_tree().process_frame
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if spawn_part < 3:
		var n_bl = Global.BLOOD_PARTICLES.instantiate()
		var n_br = Global.BREAK_PARTICLES.instantiate()
		n_bl.position = Vector2(10,10)
		n_br.position = Vector2(10,10)
		add_child(n_bl)
		add_child(n_br)
		spawn_part += 1
	else:
		$Label.visible = false
		$Control.visible = true
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN)
	pass # Replace with function body.



func _on_h_slider_value_changed(value: float) -> void:
	print(value)
	AudioServer.set_bus_volume_db(0, value - 25)
	pass # Replace with function body.
