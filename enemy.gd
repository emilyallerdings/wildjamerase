extends CharacterBody2D

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
var SPEED = 300.0
var target

@onready var sub_sprite: Sprite2D = $SubSprite

var group = 0

var next_pos = Vector2.ONE

var vec_arr = []

func _ready() -> void:
	
	for i in range(0,16):
		var angle = TAU * i / 16
		vec_arr.append(Vector2(cos(angle), sin(angle)))
	
	target = Global.player_ref
	next_pos = target.global_position
	return
	

func _physics_process(delta: float) -> void:

	#if global_position.direction_to(next_pos) != Vector2.ZERO:
		#
		#var interest_vec
		#interest_vec = global_position.direction_to(next_pos)
		#
		#var des_velocity = vec_arr[$Movement.find_best_dir(interest_vec,vec_arr, $RayCast2D)] * SPEED
		#var steering_force = des_velocity - velocity
		#steering_force = steering_force * randi_range(2,10)
		#velocity = velocity + (steering_force*delta)
		#
		#
		#var prev_rot = float($SubViewport/SubSprite.rotation)
		#$SubViewport/SubSprite.look_at(velocity) 
		#$SubViewport/SubSprite.rotate(PI/2)
		#
		#var to_rot = float($SubViewport/SubSprite.rotation)
		#
		#$SubViewport/SubSprite.rotation = lerp_angle(prev_rot, to_rot, delta* 5)
		
	
	#print(velocity)
	#NavigationServer2D.agent_set_velocity(navigation_agent_2d.get_rid(), velocity)
	
	#move_and_slide()
	return
	
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
