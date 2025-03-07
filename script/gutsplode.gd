extends AudioStreamPlayer
class_name FreeAudio

func _init(audio_source, vol):
	self.stream = audio_source
	self.volume_db = -15.0 + vol
# Called when the node enters the scene tree for the first time.
func _ready():
	play(0)
	pass # Replace with function body.

func _on_finished():
	queue_free()
	pass # Replace with function body.
