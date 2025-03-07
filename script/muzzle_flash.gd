extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scale = Vector2.ONE * 6
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if scale.x > 6.0 || scale.x <= 0:
		queue_free()
	scale = lerp(scale, Vector2.ZERO, delta * 50)
	pass
