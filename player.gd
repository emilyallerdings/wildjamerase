extends CharacterBody2D

const JUMP_VELOCITY = -400.0
var draw_angle = 0

var mining = false

var wait_next_frame = false

var main

func _ready() -> void:
	Global.player_ref = self
	main = get_parent()
	return

func _physics_process(delta: float) -> void:

	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction:
		velocity = input_direction * Global.speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO,delta*30000)
	
	move_and_slide()
	
func _process(delta: float) -> void:
	if mining:
		$Line2D.clear_points()
		var mouse_pos = get_local_mouse_position()
		mouse_pos = mouse_pos.normalized() * 128*3
		
		$RayCast2D.target_position = mouse_pos
		$RayCast2D.force_raycast_update()

		if $RayCast2D.is_colliding():
			main.mine_tile($RayCast2D.get_collider(), $RayCast2D.get_collision_point() - $RayCast2D.get_collision_normal())
			mouse_pos = to_local($RayCast2D.get_collision_point()) * 1.1
		else:
			main.stop_mining()
			
		$Line2D.add_point(Vector2.ZERO)
		$Line2D.add_point(mouse_pos)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mine"):
		$Line2D.visible = true
		mining = true
	if event.is_action_released("mine"):
		$Line2D.visible = false
		mining = false
		main.stop_mining()
	return
