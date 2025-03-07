extends Node2D
class_name Main

const CHUNK_LEN = 8
const CHUNK_SIZE = CHUNK_LEN*CHUNK_LEN
const RENDER_RAD = 3
const STRUCT_GEN_RAD = 100
const TILE_SIZE = 128
@onready var shop: CanvasLayer = %Shop

var prev_chunk = null
var despawned_enemies = 0
var loaded_chunks = []
var all_chunks = []

var modified_tiles = {}

var test_draw = true

var mining = false

var paused = false

var current_mining_tile = null
var mining_tiles = {}

var village_list = {}
var village_positions = []

var struct_prev = null

var spawn_clusters

var threaded = false

const TEST_TILE = preload("res://scenes/test_tile.tscn")
const VILLAGE = preload("res://scenes/village.tscn")
const ENEMY = preload("res://scenes/enemy.tscn")
const NAVIGATION_REGION_2D = preload("res://scenes/navigation_region_2d.tscn")

@export var noise:FastNoiseLite
@export var mineral_noise:FastNoiseLite
@export var village_noise:FastNoiseLite

var nav_regions = {}



@onready var player: CharacterBody2D = $Player
@onready var tiles: TileMapLayer = %TileMapLayer

var dist = RENDER_RAD * CHUNK_LEN * TILE_SIZE

const ENEMY_GROUP_TOTAL = 6

var enemy_group = 1
var enemy_counter = 1


var enemies_in_wave = 0
var enemies_to_spawn = 0
var max_enemies = 10
var enemies_spawned = 0
var total_clusters = 0

const WAVE_TIMER_MAX = 116 - 32
const WAVE_TIMER = WAVE_TIMER_MAX

var wave_mod = 0

var village_mutex: Mutex
var village_spawn_thread:Thread

var village_create_threads = []

var in_wave_speed = 350
var out_wave_speed = 450

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	get_window().connect("focus_exited", Callable(self, "_on_focus_exited"))

	
	Global.reset()
	$PauseMenu.visible = false
	$Start.visible = true
	village_mutex = Mutex.new()
	Engine.time_scale = 1
	$MusicManager/Music.pitch_scale = Engine.time_scale
	
	Global.main_ref = self
	print(tiles.tile_set.get_source(0).get_tiles_count())
	
	Global.speed = out_wave_speed
	
	$WaveTimer.start(WAVE_TIMER)
	randomize()
	var new_seed = randi_range(0, 10000)
	seed(1)
	noise.seed = new_seed
	village_noise.seed = new_seed
	mineral_noise.seed = new_seed
	#print(floor(-1.0 / CHUNK_LEN))
	
	#Global.nav_reg_ref = navigation_region_2d
	
	player.global_position = (Vector2i(3,3) * TILE_SIZE + Vector2i.ONE * TILE_SIZE/2)
	$Guide.global_position = player.global_position + Vector2(0, 128)
	
	#$Enemy.global_position = (Vector2i(3,3) * TILE_SIZE + Vector2i.ONE * TILE_SIZE/2)
	#init_chunk(get_chunk_at_pos(player.global_position))
	var starting_tile = get_tile_at_pos(player.global_position)
	
	village_positions.append(starting_tile - Vector2i(0, 1))
	
	struct_prev = Vector2i.ZERO
	gen_structs(false, player.global_position)
	for x in range(-3,4):
		for y in range(-3,4):
			modify_tile_sys(starting_tile + Vector2i(x,y), 0)
	init_load_chunks(Vector2i.ZERO)
	
	#print(village_positions)
	if threaded:
		village_spawn_thread = Thread.new()
		village_spawn_thread.start(gen_structs.bind(true, player.global_position))
	else:
		call_deferred("gen_structs", true, player.global_position)
	#call_deferred_thread_group()
	pass # Replace with function body.

func init_load_chunks(cur_chunk):
	var prev_loaded 
	if prev_chunk != cur_chunk:
		loaded_chunks.clear()
		prev_chunk = cur_chunk
		
		for x in range(-RENDER_RAD,RENDER_RAD+1):
			for y in range(-RENDER_RAD,RENDER_RAD+1):
				var new_vec = cur_chunk + Vector2i(x,y)
				loaded_chunks.append(new_vec)
				
				gen_village_in_chunk(new_vec)

				init_chunk(new_vec)
				create_nav_region(new_vec)
	
	
func load_chunks(cur_chunk):
	
	if prev_chunk != cur_chunk:
		
		#print("new chunk")
		var dir = cur_chunk - prev_chunk
	
		var chunks_to_unload = []
		var chunks_to_load = []
		
		if dir.x != 0:
			for y in range(-RENDER_RAD,RENDER_RAD+1):
				chunks_to_unload.append(Vector2i(dir.x * -RENDER_RAD + prev_chunk.x, y + prev_chunk.y))
				chunks_to_load.append(Vector2i(dir.x * RENDER_RAD + cur_chunk.x, y + cur_chunk.y))
		if dir.y != 0:
			for x in range(-RENDER_RAD,RENDER_RAD+1):
				chunks_to_unload.append(Vector2i(x + prev_chunk.x, dir.y * -RENDER_RAD + prev_chunk.y))
				chunks_to_load.append(Vector2i(x + cur_chunk.x, dir.y * RENDER_RAD + cur_chunk.y))
		
		var unused_navregions = []
		
		for chunk in chunks_to_unload:
			loaded_chunks.erase(chunk)	
			unload_chunk(chunk)
			if nav_regions.has(chunk):
				unused_navregions.append(nav_regions[chunk])
				nav_regions.erase(chunk)
		
		var rebake_list = []
		if threaded:
			var new_thr = Thread.new()
			village_create_threads.append(new_thr)
			new_thr.start(gen_village_in_chunks.bind(chunks_to_load))
		else:
			gen_village_in_chunks(chunks_to_load)
		for chunk in chunks_to_load:
			loaded_chunks.append(chunk)	
			#gen_village_in_chunk(chunk)
			init_chunk(chunk)
			var reg = unused_navregions.pop_front()
			move_nav_region(reg, chunk)
			rebake_list.append(chunk)
		
		call_deferred("rebake_chunks_slow",rebake_list)
		prev_chunk = cur_chunk

func rebake_chunks_slow(chunk_list):
	for chunk in chunk_list:
		rebake_nav_region(chunk)
		if nav_regions.has(chunk):
			await nav_regions[chunk].bake_finished

func move_nav_region(nav_region, chunk):
	if nav_region == null:	
		return
		
	var chunk_pos = chunk*CHUNK_LEN*TILE_SIZE
	nav_region.global_position = chunk_pos
	nav_region.name = str(chunk)
	#nav_region.call_deferred("bake_navigation_polygon")
	nav_regions[chunk] = nav_region

func create_nav_region(chunk):
	var chunk_pos = chunk*CHUNK_LEN*TILE_SIZE
	var n_region = NAVIGATION_REGION_2D.instantiate()
	n_region.global_position = chunk_pos
	n_region.name = str(chunk)
	n_region.set_outline()
		
	add_child(n_region)
		
	n_region.bake_navigation_polygon()
	nav_regions[chunk] = n_region

func rebake_nav_region(chunk):
	if !nav_regions.has(chunk):
		return true
	
	
	if nav_regions[chunk].is_baking():
		
		await nav_regions[chunk].bake_finished
	nav_regions[chunk].bake_navigation_polygon()

	
	
	#var new_navigation_mesh = NavigationPolygon.new()
	
	#navigation_region_2d.navigation_polygon.clear()
	#var bounding_outline = PackedVector2Array(arr)
	#navigation_region_2d.navigation_polygon.add_outline(bounding_outline)
	#navigation_region_2d.bake_navigation_polygon()
	
	#NavigationServer2D.bake_from_source_geometry_data(new_navigation_mesh, NavigationMeshSourceGeometryData2D.new());
	#navigation_region_2d.navigation_polygon = new_navigation_mesh

	#navigation_region_2d.bake_navigation_polygon()

func get_furthest_point(direction: Vector2) -> Vector2:
	direction = direction.normalized()
	var viewport_size = get_viewport_rect().size
	var furthest_x = direction.x * viewport_size.x / 2
	var furthest_y = direction.y * viewport_size.y / 2
	return get_viewport_rect().size / 2 + Vector2(furthest_x, furthest_y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	$Player/CanvasLayer/Control2/Control/Label.text = str(Engine.get_frames_per_second())
	var cur_chunk = get_chunk_at_pos(player.global_position)
	#print(get_tile_at_pos(player.global_position))
	load_chunks(cur_chunk)
	
	var shortest = Vector2i.MAX
	var un_explored_vil_pos = []
	if !village_positions.is_empty():
		shortest = village_positions[0]
		un_explored_vil_pos.append_array(village_positions)
	
	for vil_vec in village_list:
		if !village_list[vil_vec].explored:
			un_explored_vil_pos.append(vil_vec)
			if player.global_position.distance_to(vil_vec*TILE_SIZE) < 4*TILE_SIZE:
				village_list[vil_vec].explored = true
	
	for village in un_explored_vil_pos:
		if $Player.position.distance_to(village*TILE_SIZE) < $Player.position.distance_to(shortest*TILE_SIZE):
			shortest = village
	
	#print(shortest)
	
	if shortest == Vector2i.MAX:
		%test2.visible = false
		$Player/CanvasLayer/MBox/MLabel.visible = false
	
	#%test1.scale = Vector2.ONE * (1.0 - clampf($Player.position.distance_to(shortest*TILE_SIZE)/500.0, 0.1, 0.75))
	#%test1.position = get_viewport_rect().size/2 - %test1.size/2*%test1.scale + player.global_position.direction_to(shortest*TILE_SIZE) * get_viewport_rect().size * 0.5
	var test_x = get_viewport_rect().size.x / 2.0 + player.global_position.direction_to(shortest*TILE_SIZE).x * get_viewport_rect().size.x * 0.6
	var test_y = get_viewport_rect().size.y / 2.0 + player.global_position.direction_to(shortest*TILE_SIZE).y * get_viewport_rect().size.y * 0.6
	test_x = clamp(test_x,64,1280-64)
	test_y = clamp(test_y,64,720-64)
	#%test2.position = clamp(get_viewport_rect().size/2 + player.global_position.direction_to(shortest*TILE_SIZE) * get_viewport_rect().size * 0.6, Vector2(64,64), Vector2(1280-64,720-64))
	#print(test_y)
	#%test1.position = clamp(player.position.direction_to(shortest*TILE_SIZE) * player.position.distance_to(shortest*TILE_SIZE), Vector2.ZERO, get_viewport_rect().size) - %test1.size/2*%test1.scale
	var dist = player.global_position.distance_to(shortest*TILE_SIZE)
	%test2.position = Vector2(test_x, test_y)
	
	%test2.scale.x = get_scaled_value(dist)
	%test2.scale.y = get_scaled_value(dist)
	
	$Player/CanvasLayer/MBox/MLabel.text = str(round(dist / TILE_SIZE)) + "m"
	
	$Player/CanvasLayer/MBox.position.x = test_x
	if test_y > (720-64)/2.0:
		$Player/CanvasLayer/MBox.position.y = test_y - 90 * %test2.scale.x 
	else:
		$Player/CanvasLayer/MBox.position.y = test_y + 90 * %test2.scale.x 
	
	#$Player/DirToVil.clear_points()
	#$Player/DirToVil.add_point(Vector2.ZERO + $Player.position.direction_to(shortest*TILE_SIZE) * 10)
	#$Player/DirToVil.add_point(Vector2.ZERO + $Player.position.direction_to(shortest*TILE_SIZE) * 100)
	
	enemy_group = (enemy_group + 1) % ENEMY_GROUP_TOTAL
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.group == enemy_group:
			enemy.update_path()
	
	var cur_enemies = get_tree().get_nodes_in_group("enemies").size()
	
	$Player/CanvasLayer/Control2/Control/Time.text = str(round($WaveTimer.time_left))
	if $WaveTimer.time_left == 0:
		$Player/CanvasLayer/Control2/Control/Time.text = "NOW"
	var despawned_spwn
	
	if despawned_enemies > 0:
		despawned_spwn = get_spawn_point()
		
	while despawned_enemies > 0:
		#print("while despawn")
		spawn_enemy(despawned_spwn)
		despawned_enemies -= 1
	
	cur_enemies = get_tree().get_nodes_in_group("enemies").size()
	$Player/CanvasLayer/Control2/Control/Label.text = str(cur_enemies)
	if $WaveTimer.time_left == 0 && cur_enemies == 0 && enemies_to_spawn <= 0 && despawned_enemies <= 0:
		print("END OF WAVE")
		
		wave_mod = (wave_mod + 1) % 2
		if wave_mod == 0:
			$WaveTimer.start(WAVE_TIMER_MAX - 5.64)
			$MusicManager/Music.play(5.64)
		if wave_mod == 1:
			var remaining_time = 158.17 - WAVE_TIMER_MAX
			$WaveTimer.start(remaining_time)
		Global.speed = out_wave_speed
		Global.can_shop = true
		%MusicManager.should_switch_back()
		print("total enemies spawned: ", enemies_spawned)

	
	#print(Engine.get_frames_per_second())
	pass

func get_scaled_value(distance: float) -> float:
	var d_min = 50.0
	var d_max = 10000.0
	var s_min = 0.4
	var s_max = 1.0

	var t = (clamp(distance, d_min, d_max) - d_min) / (d_max - d_min)
	return lerp(s_max, s_min, t)

func mine_tile(collider, pos):

	if collider is TileMapLayer:
		var tile = tiles.local_to_map(pos)
		if current_mining_tile != tile:
			if current_mining_tile != null:
				if mining_tiles.has(current_mining_tile):
					mining_tiles[current_mining_tile].stop_mining()
			current_mining_tile = tile
			if !mining_tiles.has(current_mining_tile):
				mining_tiles[current_mining_tile] = TEST_TILE.instantiate()
				mining_tiles[current_mining_tile].tile_pos = tile
				mining_tiles[current_mining_tile].position = tile * TILE_SIZE + Vector2i.ONE * TILE_SIZE/2
				mining_tiles[current_mining_tile].set_tile(tiles.get_cell_source_id(tile))
				add_child(mining_tiles[current_mining_tile])
			mining_tiles[current_mining_tile].start_mining()
			
	
	return

func stop_mining():
	if mining_tiles.has(current_mining_tile):
		mining_tiles[current_mining_tile].stop_mining()
		current_mining_tile = null

func stop_mining_tile(tile_pos):
	#print("stop mining: ", tile.tile_pos)
	mining_tiles[tile_pos].queue_free()
	mining_tiles.erase(tile_pos)
	
	#print(mining_tiles)

func remove_tile(tile):
	current_mining_tile = null
	if $TileMapLayer.get_cell_source_id(tile) == 3:
		Global.gem_count += 1
	if $TileMapLayer.get_cell_source_id(tile) == 4:
		Global.gem_count += randi_range(1,2)
	modify_tile(tile,0)

func get_tile_at_pos(pos):
	return Vector2i(floor(pos.x / TILE_SIZE), floor(pos.y / TILE_SIZE))

func get_chunk_at_pos(pos):
	var tile_pos = get_tile_at_pos(pos)
	return Vector2i(floor(float(tile_pos.x) / float(CHUNK_LEN)), floor(float(tile_pos.y) / float(CHUNK_LEN)))

func get_chunk_at_tile(tile_pos):
	return Vector2i(floor(float(tile_pos.x) / float(CHUNK_LEN)), floor(float(tile_pos.y) / float(CHUNK_LEN)))

func unload_chunk(chunk_vec):
	for x in range(0, CHUNK_LEN):
		for y in range(0, CHUNK_LEN):
			tiles.erase_cell(Vector2i(chunk_vec.x * CHUNK_LEN + x, chunk_vec.y * CHUNK_LEN + y))
			
func init_chunk(chunk_vec):
	for x in range(0, CHUNK_LEN):
		for y in range(0, CHUNK_LEN):
			var global_pos:Vector2i = chunk_vec*CHUNK_LEN*TILE_SIZE + Vector2i(x*TILE_SIZE, y*TILE_SIZE)
			var noise_sample = noise.get_noise_2d(global_pos.x, global_pos.y)
			var tile_type = 1
			
			var threshold = 0.25
			var dist = abs(global_pos.length()) / 600000.0
			threshold -= dist
			
			if noise_sample > threshold:
				tile_type = 2
			
			noise_sample = mineral_noise.get_noise_2d(global_pos.x, global_pos.y)
			
			if tile_type == 1:
				if noise_sample < -0.5:
					tile_type = 3
			elif tile_type == 2:
				if noise_sample < -0.5:
					tile_type = 4
			
			var tile_vec = Vector2i(chunk_vec.x * CHUNK_LEN + x, chunk_vec.y * CHUNK_LEN + y)
			
			
			village_mutex.lock()
			if !modified_tiles.has(tile_vec):
				tiles.set_cell(tile_vec, tile_type, Vector2i(0,0))
			else:
				var atlas_x = 0
				if modified_tiles[tile_vec] == 0 && randf() > 0.9:
					atlas_x = randi_range(1,3)
				tiles.set_cell(tile_vec, modified_tiles[tile_vec], Vector2i(atlas_x,0))
			village_mutex.unlock()
			#print("set cell: ", Vector2i(chunk_vec.x + x, chunk_vec.y + y))

func tile_in_chunk(tile,chunk):
	var tile_chunk = Vector2i(floor(tile.x / CHUNK_LEN), floor(tile.y / CHUNK_LEN))
	if tile_chunk == chunk:
		return true
	else:
		return false

func gen_structs(loop, pos):
	while true:
		#print("while gen_struct")
		var vec = get_chunk_at_pos(pos)
		var all_village_pos = []
		village_mutex.lock()
		all_village_pos.append_array(village_positions)
		village_mutex.unlock()
		
		for vil_pos in village_list:
			if !all_village_pos.has(vil_pos):
				all_village_pos.append(vil_pos)
		
		
		for chunk_x in range(-STRUCT_GEN_RAD, STRUCT_GEN_RAD):
			for chunk_y in range(-STRUCT_GEN_RAD, STRUCT_GEN_RAD):
				var chunk_pos = Vector2i(chunk_x * CHUNK_LEN * TILE_SIZE, chunk_y * CHUNK_LEN * TILE_SIZE)
				if village_noise.get_noise_2d(chunk_pos.x, chunk_pos.y) > -.15:
					var spawn = true

					
					for village_pos in all_village_pos:
						if (village_pos * TILE_SIZE).distance_to(chunk_pos) < (80 * TILE_SIZE):
							spawn = false
							
					if spawn == true:
						#print("spawning new")
						all_village_pos.append(chunk_pos / TILE_SIZE)
						village_positions.append(chunk_pos / TILE_SIZE)
						#gen_village_in_chunk(chunk_pos)
			
		if !loop:
			return
		await get_tree().create_timer(5).timeout

func gen_village_in_chunks(chunks):
	for chunk in chunks:
		gen_village_in_chunk(chunk)
		
func gen_village_in_chunk(chunk_vec):
	for village_pos in village_positions:
		if tile_in_chunk(village_pos, chunk_vec):
			gen_village(village_pos)

func gen_village(tile_vec):
	if !village_list.has(tile_vec):
		village_mutex.lock()
		village_positions.erase(tile_vec)
		village_list[tile_vec] = VILLAGE.instantiate()
		village_list[tile_vec].position = tile_vec*TILE_SIZE + Vector2i.ONE * TILE_SIZE/2
		call_deferred("add_child", village_list[tile_vec])
		for x in range(-2,3):
			for y in range(-2,3):
				modify_tile_sys(tile_vec + Vector2i(x,y), 0)
		village_mutex.unlock()


func modify_tile_sys(tile_vec, tile_type):
	
	tiles.set_cell(tile_vec, tile_type, Vector2i(0,0))
	modified_tiles[tile_vec] = tile_type

func modify_tile(tile_vec, tile_type):

	tiles.set_cell(tile_vec, tile_type, Vector2i(0,0))
	modified_tiles[tile_vec] = tile_type
	rebake_nav_region(get_chunk_at_tile(tile_vec))

func get_spawn_point():
	var max_tile_rad = 6 * 3
	var max_dist = max_tile_rad * TILE_SIZE
	
	var point = player.position
	
	var min_dist = 1024
	
	var max_tries = 100
	
	while point.distance_to(player.position) < min_dist || !can_navigate(point, player.position):
		#print("while spawn point")
		max_tries -= 1
		var rand_pos = Vector2(randi_range(-max_dist, max_dist), randi_range(-max_dist, max_dist))
		rand_pos += player.position
		if rand_pos.distance_to($Player.position) < min_dist:
			rand_pos += -rand_pos.direction_to($Player.position) * rand_pos.distance_to($Player.position)
		point = NavigationServer2D.map_get_closest_point(NavigationServer2D.get_maps()[0], rand_pos)
		
		min_dist -= 50
		if max_tries <= 0:
			return point
	return point


func can_navigate(from: Vector2, to: Vector2) -> bool:
	$TestNav.global_position = from
	$TestNav/TestNav.target_position = to
	return $TestNav/TestNav.get_final_position().distance_to(to) < 32

func spawn_enemy(position):
		var n_enemy = ENEMY.instantiate()
		n_enemy.group = enemy_counter
		enemy_counter = (enemy_counter + 1) % ENEMY_GROUP_TOTAL
		n_enemy.global_position = position
		add_child(n_enemy)

func _unhandled_input(event: InputEvent) -> void:
	
		pass


func _on_wave_timer_timeout() -> void:
	despawned_enemies = 0
	Global.can_shop = false
	Global.diff_scale += 0.88
	Global.speed = in_wave_speed
	#max_enemies = 3 * Global.diff_scale
	enemies_in_wave = min(round(5 + randi_range(6,8) * Global.diff_scale * 0.6), 200)
	enemies_to_spawn = enemies_in_wave
	spawn_clusters = randi_range(3, floor(enemies_to_spawn/3.0))
	total_clusters = spawn_clusters
	$SpawnTimer.start(2)
	#spawn_clusters = randi_range(3,6) * Global.diff_scale
	
	
	enemies_spawned = 0
	pass # Replace with function body.


func _on_spawn_timer_timeout() -> void:
	
	if spawn_clusters > 0:
		var enemies_in_cluster = floor(enemies_to_spawn / spawn_clusters)
		# Ensure we distribute the remaining enemies (if any)
		if spawn_clusters == 1:  # Last cluster, assign all remaining enemies
			enemies_in_cluster = enemies_to_spawn
		
		# Subtract the number of enemies spawned in this cluster from the total
		enemies_to_spawn -= enemies_in_cluster

		# Spawn the enemies for this cluster
		#print("cluster: ", spawn_clusters, " has ", enemies_in_cluster, " enemies")
		
		var groups = randi_range(1 + round(Global.diff_scale/2.0), enemies_in_cluster)  # Random number of groups between 1 and enemies_in_cluster
		var remaining_enemies = enemies_in_cluster  # Track remaining enemies to distribute

		for group in range(groups):
			# Calculate the number of enemies for this group (at least 1 enemy)
			var enemies_in_group = max(1, remaining_enemies - (groups - group - 1))  # Ensure at least 1 enemy, and leave enough for remaining groups
			
			var group_spawn_point = get_spawn_point()  # Get spawn point for the group
			for i in range(enemies_in_group):
				spawn_enemy(group_spawn_point)  # Spawn the enemy
				enemies_spawned += 1
			
			# Subtract the number of enemies spawned in this group from the remaining enemies
			remaining_enemies -= enemies_in_group
		
		# Decrease the number of clusters remaining
		spawn_clusters -= 1
		var timer = (max((enemies_in_cluster / total_clusters) * (enemies_in_wave * 1.0/Global.diff_scale * 10.0) / (enemies_in_cluster * Global.diff_scale * 0.5) , 0.1))
		$SpawnTimer.start(timer)

func _on_focus_exited():
	$PauseMenu.pause()
