extends CharacterBody2D

const JUMP_VELOCITY = -400.0
var draw_angle = 0

var mining = false

var wait_next_frame = false

var health = 100
var max_health = 100

const MAX_AM = 300
var max_ammo = MAX_AM
var ammo = max_ammo

var main
var coll = 128*3
var dead = false
var shooting = false

var shoot_delay = 0.1

var rt = 0.9

const BULLET = preload("res://scenes/bullet.tscn")

func _ready() -> void:
	refill_ammo()
	Global.player_ref = self
	main = get_parent()
	$Line2D.add_point(Vector2.ZERO)
	$Line2D.add_point(Vector2.ZERO)
	
	set_shoot_rate(Global.rate)
	
	return

func set_shoot_rate(rate):
	if max_ammo != MAX_AM + 150 * (rate - 0.9):

		ammo = (float(ammo) / float(max_ammo)) * (MAX_AM + (150 * (rate - 0.9)))
		
		max_ammo = MAX_AM + 150 * (rate - 0.9)
		print("total ammo ", max_ammo )
	shoot_delay = 0.1/rate
	$Minigun.pitch_scale = 1.0 * rate
	$MinigunEnd.pitch_scale = 1.0 * rate

func damage(num):
	if dead:
		return
	if $InvulFrame.is_stopped():
		self.health -= num
		if health >= 0:
			get_tree().root.add_child(FreeAudio.new(Global.METAL_HIT_2,0))
			#$InvulFrame.start()
		else:
			get_tree().root.add_child(FreeAudio.new(Global.METAL_HIT_2,0))
			
	if health <= 0:
		dead = true
		$Camera2D/Shake.process_mode = Node.PROCESS_MODE_DISABLED
		$Camera2D/ExShake.start()
		var n_part = Global.BREAK_PARTICLES.instantiate()
		n_part.scale *= 2
		n_part.amount *= 2
		n_part.lifetime *= 2
		n_part.global_position = global_position 
		main.add_child(n_part)
		$Sprite.visible = false
		
		await get_tree().create_timer(2.0).timeout
		%Restart.visible = true
		
	$CanvasLayer/Control2/ColorRect2/HealthBar.set_health(float(health)/float(max_health))

func _physics_process(delta: float) -> void:

	if dead:
		return

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
		var pos = Vector2.ZERO.direction_to(mouse_pos)
		pos = Vector2(-pos.y, pos.x)
		var gun_point = Vector2.ZERO.direction_to(mouse_pos) * 20 + pos * 30
		
		var direction = Vector2(cos($Sprite.rotation - PI/2 - deg_to_rad(4)), sin($Sprite.rotation - PI/2 - deg_to_rad(4)))
		$RayCast2D.position = gun_point
		$RayCast2D.target_position = gun_point + direction * len
		#$RayCast2D.force_raycast_update()

		if $RayCast2D.is_colliding():
			pass
			main.mine_tile($RayCast2D.get_collider(), $RayCast2D.get_collision_point() - $RayCast2D.get_collision_normal())
			#len = Vector2.ZERO.distance_to($RayCast2D.get_collision_point())
			coll = Vector2.ZERO.distance_to(to_local($RayCast2D.get_collision_point())) * 1.1
		else:
			coll = len
			main.stop_mining()
	
func _process(delta: float) -> void:
	
	
	
	if dead:
		$Sprite.visible = false
		shooting = false
		mining = false
		$Line2D.visible = false
		return
	
	#$Camera2D.offset.x = snapped(lerp($Camera2D.offset.x, Vector2.ZERO.direction_to(get_local_mouse_position()).x * clamp(Vector2.ZERO.distance_to(get_local_mouse_position()), 0, 128), delta * 5), 1)
	#$Camera2D.offset.y = snapped(lerp($Camera2D.offset.y, Vector2.ZERO.direction_to(get_local_mouse_position()).y * clamp(Vector2.ZERO.distance_to(get_local_mouse_position()), 0, 128), delta * 5), 1)
	$Sprite.rotation = Vector2.ZERO.angle_to_point(get_local_mouse_position()) + PI/2.0
	set_shoot_rate(Global.rate)
	
	if mining:
		$Laser.volume_db = lerp($Laser.volume_db, -15.0, delta/2.0)
		var mouse_pos = get_local_mouse_position()
		mouse_pos = Vector2.ZERO.direction_to(mouse_pos) * coll
		var pos = Vector2.ZERO.direction_to(mouse_pos)
		pos = Vector2(-pos.y, pos.x)
		var gun_point = Vector2.ZERO.direction_to(mouse_pos) * 20 + pos * 32
		$Line2D.set_point_position(0, gun_point)
		var direction = Vector2(cos($Sprite.rotation - PI/2), sin($Sprite.rotation  - PI/2))
		$Line2D.set_point_position(1, lerp($Line2D.get_point_position(1), gun_point + direction * coll, delta * 25))
	else:
		$Laser.volume_db = lerp($Laser.volume_db, -80.0, delta/2.0)
		$Laser.pitch_scale = lerp($Laser.pitch_scale, 0.25, delta/2.0)
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
		
	if event.is_action_pressed("mine"):
		$Line2D.visible = true
		mining = true
		$Laser.play(0)
		$Laser.volume_db = -5
		$Laser.pitch_scale = 1.2
		
	if event.is_action_released("mine"):
		$Line2D.visible = false
		mining = false
		main.stop_mining()
		
	if event.is_action_pressed("click"):
		shooting = true
		if $ShootTimer.is_stopped():
			shoot()
	if event.is_action_released("click"):
		shooting = false
			
	return


func _on_invul_frame_timeout() -> void:
	$InvulFrame.stop()
	pass # Replace with function body.


func shoot():
	if $Shop.visible:
		return
	
	if ammo <= 0:
		$ShootTimer.start(shoot_delay)
		return
	ammo -= 1
	
	if !$Minigun.playing:
		$Minigun.play(0.094)
	
	$CanvasLayer/Control2/AmmoLabel.text = "AMMO: " + str(round(float(ammo) / float(max_ammo) * 100.0)) + "%"
	$ShootTimer.start(shoot_delay)
	$Camera2D/Shake.start()
	var n_bullet = BULLET.instantiate()
	var direction = Vector2(cos($Sprite.rotation - PI/2), sin($Sprite.rotation  - PI/2))
	var for_off = direction * 12
	direction = Vector2(-direction.y, direction.x)
	n_bullet.global_position = self.global_position - direction * 28 + for_off
	
	var dir = Vector2.ZERO.direction_to(get_local_mouse_position())

	n_bullet.shoot(dir)

	#n_bullet.set_target_pos(global_position, to_global(tar_pos))
	
	main.add_child(n_bullet)

func _on_shoot_timer_timeout() -> void:
	
	if shooting && ammo > 0:
		shoot()
	else:
		if ammo <= 0:
			$CanvasLayer/Control2/AmmoLabel.text = "AMMO: EMPTY"
			$CanvasLayer/Control2/AmmoLabel.modulate = Color(1.0,0,0)
			$MinigunEnd.play(0)
			
		if $Minigun.playing:
			$Minigun.stop()
			$MinigunEnd.play(0)
	pass # Replace with function body.

func refill_ammo():
	ammo = max_ammo
	$CanvasLayer/Control2/AmmoLabel.modulate = Color(0,1.00,0)

func can_repair():
	return health < max_health

func repair():
	
	health += max_health/14.0
	health = clamp(health, 0, max_health)
	$CanvasLayer/Control2/ColorRect2/HealthBar.set_health(float(health)/float(max_health))
	

func can_ammo():
	return ammo < max_ammo
	
func give_ammo():
	ammo += max_ammo/10
	ammo = clamp(ammo, 0, max_ammo)
	$CanvasLayer/Control2/AmmoLabel.modulate = Color(0,1.00,0)
	$CanvasLayer/Control2/AmmoLabel.text = "AMMO: " + str(round(float(ammo) / float(max_ammo) * 100.0)) + "%"
