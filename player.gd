extends CharacterBody2D

const JUMP_VELOCITY = -400.0
var draw_angle = 0

var mining = false

var wait_next_frame = false

var health = 100
var max_health = 100

var main
var coll = 128*3

func _ready() -> void:
	Global.player_ref = self
	main = get_parent()
	$Line2D.add_point(Vector2.ZERO)
	$Line2D.add_point(Vector2.ZERO)
	return

func damage(num):
	if $InvulFrame.is_stopped():
		self.health -= num
		if health >= 0:
			$InvulFrame.start()
			$CanvasLayer/Control2/ColorRect2/HealthBar.set_health(float(health)/float(max_health))

func _physics_process(delta: float) -> void:

	var input_direction = Input.get_vector("left", "right", "up", "down")
	if input_direction:
		velocity = input_direction * Global.speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO,delta*30000)
	
	move_and_slide()
	if mining:
		var mouse_pos = get_local_mouse_position()
		var len = 128*3
		mouse_pos = mouse_pos.normalized() * len
		
		$RayCast2D.target_position = mouse_pos
		#$RayCast2D.force_raycast_update()

		if $RayCast2D.is_colliding():
			main.mine_tile($RayCast2D.get_collider(), $RayCast2D.get_collision_point() - $RayCast2D.get_collision_normal())
			#len = Vector2.ZERO.distance_to($RayCast2D.get_collision_point())
			coll = Vector2.ZERO.distance_to(to_local($RayCast2D.get_collision_point())) * 1.1
		else:
			coll = len
			main.stop_mining()
	
func _process(delta: float) -> void:
	if mining:


		var mouse_pos = get_local_mouse_position()
		mouse_pos = mouse_pos.normalized() * coll
		
		$Line2D.set_point_position(1, lerp($Line2D.get_point_position(1), mouse_pos, delta * 25))
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mine"):
		$Line2D.visible = true
		mining = true
	if event.is_action_released("mine"):
		$Line2D.visible = false
		mining = false
		main.stop_mining()
	return


func _on_invul_frame_timeout() -> void:
	$InvulFrame.stop()
	pass # Replace with function body.
