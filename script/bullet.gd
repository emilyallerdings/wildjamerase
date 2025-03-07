extends CharacterBody2D

@export var speed: float = 6000.0
const BULLET_TRAIL = preload("res://scenes/bullet_trail.tscn")
var prev_pos
const MUZZLE_FLASH = preload("res://scenes/muzzle_flash.tscn")
var line

var col = false

var to_remove = false

func _ready() -> void:
	global_position = global_position + velocity.normalized() * 24
	modulate = modulate * 2
	prev_pos = global_position
	line = BULLET_TRAIL.instantiate()
	Global.main_ref.add_child(line)
	
	line.add_point(prev_pos)
	#line.add_point(global_position + velocity.normalized() * 48)
	var muz = MUZZLE_FLASH.instantiate()
	muz.global_position = self. global_position
	
	Global.main_ref.add_child(muz)
func _physics_process(delta):
	if col:
		return
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.get_collider() is Enemy:
			collision.get_collider().damage(Global.damage)
		col = true
		prev_pos = global_position
		velocity = Vector2.ZERO
		position = collision.get_position()
		if !to_remove && $Timer.is_stopped():
			$Timer.start()


func shoot(direction: Vector2):
	var spread = deg_to_rad(3)  # Convert 2 degrees to radians
	var random_angle = randf_range(-spread, spread)  # Generate a random angle within -2 to +2 degrees
	velocity = speed * (direction.rotated(random_angle)).normalized()

func _process(delta: float) -> void:
	
	if to_remove:
		line.remove_point(0)
		line.modulate.a /= 10
		if line.get_points().size() == 0:
			queue_free()
			line.queue_free()
		return
	
	line.add_point(prev_pos)
	prev_pos += velocity * delta
	
	if line.get_points().size() > 20:
		line.remove_point(0)
		
	return


func _on_timer_timeout() -> void:
	to_remove = true
	visible = false
	pass # Replace with function body.
