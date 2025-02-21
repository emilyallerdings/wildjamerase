extends CharacterBody2D

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
var SPEED = 400 + randi_range(-25,25)
var target

@onready var sub_sprite: Sprite2D = $SubSprite

var group = 0

var next_pos = Vector2.ONE

var vec_arr = []

enum {CHASE,ATTACK, RECOUP}
var state = CHASE

var att_rad = 32*3
var att_dur = 0.2

var att_tween

func _ready() -> void:
	
	for i in range(0,16):
		var angle = TAU * i / 16
		vec_arr.append(Vector2(cos(angle), sin(angle)))
	
	target = Global.player_ref
	next_pos = target.global_position
	return
	

func _physics_process(delta: float) -> void:
	if state == CHASE:
		chase_phys(delta)
	elif state == ATTACK:
		#print(velocity)
		move_and_slide()
		if position.distance_to(target.position) < 32:
			target.damage(2)
		if velocity == Vector2.ZERO:
			state = RECOUP
			$RecoupTimer.start()
		pass
	elif state == RECOUP:
		var interest_vec


		var interest_pos = target.global_position + target.global_position.direction_to(self.global_position) * 256
		interest_vec = position.direction_to(interest_pos)
		#$Sprite2D.position = to_local(target.position) + to_local(target.position).direction_to(position) * 128
		
		var des_velocity = vec_arr[$Movement.find_best_dir(interest_vec,vec_arr, $RayCast2D)] * 150
		
		var steering_force = des_velocity - velocity
		steering_force = steering_force * 5
		velocity = velocity + (steering_force*delta)
		sub_sprite.rotation = lerp_angle(sub_sprite.rotation, Vector2.ZERO.angle_to_point(to_local(target.position)) + PI/2, delta*30)
		move_and_slide()

	return

func _process(delta: float) -> void:
	#$Line2D.clear_points()
	#$Line2D.add_point(Vector2.ZERO)
	#$Line2D.add_point(velocity.normalized()*64)
	#sub_sprite.rotation = Vector2.ZERO.angle_to_point(velocity.normalized()*64)
	return

func chase_phys(delta):
	if global_position.direction_to(next_pos) != Vector2.ZERO:
		
		var interest_vec
		interest_vec = global_position.direction_to(next_pos)
		
		var des_velocity = vec_arr[$Movement.find_best_dir(interest_vec,vec_arr, $RayCast2D)] * SPEED
		var steering_force = des_velocity - velocity
		steering_force = steering_force * randi_range(2,10)
		velocity = velocity + (steering_force*delta)
		

		sub_sprite.rotation = lerp_angle(sub_sprite.rotation, Vector2.ZERO.angle_to_point(velocity.normalized()*64) + PI/2, delta*10)
		

		#sub_sprite.rotation = Vector2.ZERO.angle_to_point(velocity.normalized()*64)
	
	move_and_slide()
	
	if self.position.distance_to(target.position) < att_rad:
		state = ATTACK
		var att_vel = position.direction_to(target.position) * (att_rad*3.0) / att_dur
		velocity = att_vel * 2.0
		att_tween = get_tree().create_tween()
		sub_sprite.rotation = Vector2.ZERO.angle_to_point(velocity.normalized()*64) + PI/2
		att_tween.tween_property(self, "velocity", Vector2.ZERO, att_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
func find_best_dir(vec_arr, raycast):
	var interest_vec
	interest_vec = global_position.direction_to(next_pos)
	var dots = []
	var danger = []
	
	danger.resize(16)
	danger.fill(0)
	for i in range(0,16):
		dots.append(interest_vec.dot(vec_arr[i]))
		raycast.target_position = vec_arr[i] * 16
		raycast.force_raycast_update()
		if raycast.is_colliding():
			danger[i] += 10
			danger[posmod(i+1,16)] += 2
			danger[posmod(i-1,16)] += 2
	
	var best_dir = 0
	
	for i in range(0,16):
		dots[i] -= danger[i]
		if dots[i] > dots[best_dir]:
			best_dir = i
	return best_dir

func update_path():
	navigation_agent_2d.target_position = target.global_position
	next_pos = navigation_agent_2d.get_next_path_position()
	

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	print(safe_velocity)


func _on_recoup_timer_timeout() -> void:
	state = CHASE
	pass # Replace with function body.
