extends GPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	self.emitting = true
	pass # Replace with function body.


func bigger(amount):
	self.process_material.scale_min = self.process_material.scale_min * amount
	self.process_material.scale_max = self.process_material.scale_max * amount
	
func faster(amount):
	self.process_material.initial_velocity_min = self.process_material.initial_velocity_min * amount
	self.process_material.initial_velocity_max = self.process_material.initial_velocity_max * amount

func _on_finished():
	queue_free()
	pass # Replace with function body.
