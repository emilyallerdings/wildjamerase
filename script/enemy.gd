extends CharacterBody2D
class_name Enemy

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D


var MAX_SPEED:float = 425 + randi_range(-25,25)

var speed:float = MAX_SPEED
var target

@onready var sub_sprite: Sprite2D = $SubSprite

var group = 0

var next_pos = Vector2.ONE

var vec_arr = Array([], TYPE_VECTOR2, "", null)

enum {CHASE,ATTACK, RECOUP, TUNNEL}
var state = CHASE

var att_rad = 32*4
var att_dur = 0.2

var att_tween

var dots: PackedFloat32Array = PackedFloat32Array()
var danger: PackedFloat32Array = PackedFloat32Array()

var des_velocity = Vector2.ZERO

var ray_num = 16

var counter = 0
var health = 14

var can_attack = true

func _ready() -> void:
	
	dots.resize(ray_num)
	danger.resize(ray_num)
	health = 14 + 0.20 * Global.diff_scale
	dots.fill(0)
	danger.fill(0)
		
	for i in range(0,ray_num):
		var angle:float = TAU * i / ray_num
		vec_arr.append(Vector2(cos(angle), sin(angle)))
	
	target = Global.player_ref
	next_pos = target.global_position
	return
	

func _physics_process(delta: float) -> void:
	
	if global_position.distance_to(target.global_position) > 8 * 128 * 3:
		Global.main_ref.despawned_enemies += 1
		print("despawn")
		queue_free()
		return
	
	counter = (counter + 1) % Main.ENEMY_GROUP_TOTAL
	if state == CHASE:
		chase_phys(delta)
	elif state == ATTACK:
		#print(velocity)
		move_and_slide()
		if position.distance_to(target.position) < 32:
			if can_attack && target.dead == false:
				self.damage(5, false)
				target.damage(1 + 0.15*Global.diff_scale)
				can_attack = false
		if velocity == Vector2.ZERO:
			state = RECOUP
			$RecoupTimer.start()
		pass
	elif state == RECOUP:
		var interest_vec


		var interest_pos = to_local(target.global_position + target.global_position.direction_to(self.global_position) * 256)
		interest_vec = Vector2.ZERO.direction_to(interest_pos)

		#$Sprite2D.position = to_local(target.position) + to_local(target.position).direction_to(position) * 128
		
		
		#ONLY DO UPDATE IF COUNTER + GROUP NUM HERE
		#COUNTER ++
		#IF COUNTER != GROUP NUM
		#RETURN
		if counter == group:
			des_velocity = vec_arr[find_best_dir(interest_vec,vec_arr, $RayCast2D)] * 150
		
		var steering_force = des_velocity - velocity
		steering_force = steering_force * 5
		velocity = velocity + (steering_force*delta)

		sub_sprite.rotation = lerp_angle(sub_sprite.rotation, Vector2.ZERO.angle_to_point(to_local(target.position)) + PI/2, delta*30)
		move_and_slide()
	elif state == TUNNEL:
		velocity = global_position.direction_to(target.global_position) * speed / 2.0
	return

func _process(delta: float) -> void:
	
	speed = lerpf(speed, MAX_SPEED, delta)
	

	#$Line2D.clear_points()
	#$Line2D.add_point(Vector2.ZERO)
	#$Line2D.add_point(velocity.normalized()*64)
	#sub_sprite.rotation = Vector2.ZERO.angle_to_point(velocity.normalized()*64)
	return

func chase_phys(delta):
	if global_position.direction_to(next_pos) != Vector2.ZERO:
		
		var interest_vec:Vector2
		interest_vec = global_position.direction_to(next_pos)
		if counter == group:
			des_velocity = vec_arr[find_best_dir(interest_vec, vec_arr, $RayCast2D)] * speed
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

func do_ray_check(tar_pos, raycast:RayCast2D) -> float:
	
	raycast.target_position = tar_pos
	raycast.force_raycast_update()
	var col = raycast.get_collider()
	if col == null:
		return 0
	elif col is Enemy:
		return 1
	elif col is TileMapLayer:
		return 10
	return 0

func find_best_dir(interest_vec:Vector2, vec_arr:Array, raycast:RayCast2D):



	#interest_vec = global_position.direction_to(next_pos)
	
	danger.fill(0)
	
	for i in range(0,ray_num):
		dots[i] = (interest_vec.dot(vec_arr[i]))
		
		var dang = do_ray_check(vec_arr[i] * ray_num, raycast)
		danger[i] += dang
		danger[posmod(i+1,ray_num)] += dang/5
		danger[posmod(i-1,ray_num)] += dang/5
	
	var best_dir = 0
	
	for i in range(0,ray_num):
		dots[i] -= danger[i]
		if dots[i] > dots[best_dir]:
			best_dir = i
			
	return best_dir

func update_path():
	navigation_agent_2d.target_position = target.global_position
	next_pos = navigation_agent_2d.get_next_path_position()
	if navigation_agent_2d.get_final_position().distance_to(navigation_agent_2d.target_position) > 64:
		state = TUNNEL
	else:
		if state == TUNNEL:
			state = CHASE
		
		
	
func damage(dmg, part:bool = true):

	health -= dmg
	velocity = velocity * 0.5
	if health <= 0:
		queue_free()
		if part:
			var n_particle = Global.BLOOD_PARTICLES.instantiate()
			n_particle.global_position = global_position
			n_particle.bigger(3)
			Global.main_ref.add_child(n_particle)
	else:
		if part:
			var n_particle = Global.BLOOD_PARTICLES.instantiate()
			n_particle.global_position = global_position
			Global.main_ref.add_child(n_particle)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	print(safe_velocity)


func _on_recoup_timer_timeout() -> void:
	state = CHASE
	can_attack = true
	pass # Replace with function body.
