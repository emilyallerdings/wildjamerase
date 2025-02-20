extends Node2D
class_name Main

const CHUNK_LEN = 7
const CHUNK_SIZE = CHUNK_LEN*CHUNK_LEN
const RENDER_RAD = 3
const STRUCT_GEN_RAD = 50
const TILE_SIZE = 128

var prev_chunk = null

var loaded_chunks = []
var all_chunks = []

var modified_tiles = {}

var test_draw = true

var mining = false

var current_mining_tile = null
var mining_tiles = {}

var village_list = {}
var village_positions = []

var struct_prev = null

const TEST_TILE = preload("res://test_tile.tscn")
const VILLAGE = preload("res://village.tscn")
const ENEMY = preload("res://enemy.tscn")
const NAVIGATION_REGION_2D = preload("res://navigation_region_2d.tscn")

@export var noise:FastNoiseLite
@export var mineral_noise:FastNoiseLite
@export var village_noise:FastNoiseLite

var nav_regions = {}


@onready var player: CharacterBody2D = $Player
@onready var tiles: TileMapLayer = %TileMapLayer

var dist = RENDER_RAD * CHUNK_LEN * TILE_SIZE

const ENEMY_GROUP_TOTAL = 32

var enemy_group = 1
var enemy_counter = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#print(floor(-1.0 / CHUNK_LEN))
	
	#Global.nav_reg_ref = navigation_region_2d
	
	player.global_position = (Vector2i(3,3) * TILE_SIZE + Vector2i.ONE * TILE_SIZE/2)
	#$Enemy.global_position = (Vector2i(3,3) * TILE_SIZE + Vector2i.ONE * TILE_SIZE/2)
	#init_chunk(get_chunk_at_pos(player.global_position))
	var starting_tile = get_tile_at_pos(player.global_position)
	
	village_positions.append(starting_tile - Vector2i(0, 1))
	
	struct_prev = Vector2i.ZERO
	gen_structs(Vector2i.ZERO)
	for x in range(-3,4):
		for y in range(-3,4):
			modify_tile_sys(starting_tile + Vector2i(x,y), 0)
	init_load_chunks(Vector2i.ZERO)
	
	print(village_positions)

	
			
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
			
			unused_navregions.append(nav_regions[chunk])
			nav_regions.erase(chunk)
		
		var rebake_list = []
		
		for chunk in chunks_to_load:
			loaded_chunks.append(chunk)	
			gen_village_in_chunk(chunk)
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var cur_chunk = get_chunk_at_pos(player.global_position)
	#print(get_tile_at_pos(player.global_position))
	load_chunks(cur_chunk)
	
	var shortest = village_positions[0]
	for village in village_positions:
		if $Player.position.distance_to(village*TILE_SIZE) < $Player.position.distance_to(shortest*TILE_SIZE):
			shortest = village
	
	#print(shortest)
	
	$Player/DirToVil.clear_points()
	$Player/DirToVil.add_point(Vector2.ZERO + $Player.position.direction_to(shortest*TILE_SIZE) * 10)
	$Player/DirToVil.add_point(Vector2.ZERO + $Player.position.direction_to(shortest*TILE_SIZE) * 100)
	
	enemy_group = (enemy_group + 1) % ENEMY_GROUP_TOTAL
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.group == enemy_group:
			enemy.update_path()
	
	#print(Engine.get_frames_per_second())
	pass

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
			
			var threshold = 0.2
			var dist = abs(global_pos.length()) / 100000.0
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
			
			
			
			if !modified_tiles.has(tile_vec):
				tiles.set_cell(tile_vec, tile_type, Vector2i.ZERO)
			else:
				tiles.set_cell(tile_vec, modified_tiles[tile_vec], Vector2i.ZERO)
			#print("set cell: ", Vector2i(chunk_vec.x + x, chunk_vec.y + y))

func tile_in_chunk(tile,chunk):
	var tile_chunk = Vector2i(floor(tile.x / CHUNK_LEN), floor(tile.y / CHUNK_LEN))
	if tile_chunk == chunk:
		return true
	else:
		return false

func gen_structs(vec):
	for chunk_x in range(-STRUCT_GEN_RAD, STRUCT_GEN_RAD):
		for chunk_y in range(-STRUCT_GEN_RAD, STRUCT_GEN_RAD):
			var chunk_pos = Vector2i(chunk_x * CHUNK_LEN * TILE_SIZE, chunk_y * CHUNK_LEN * TILE_SIZE)
			if village_noise.get_noise_2d(chunk_pos.x, chunk_pos.y) > 0:
				var spawn = true
				for village_pos in village_positions:
					if village_pos.distance_to(chunk_pos) < 2000:
						spawn = false
						
				village_positions.append(chunk_pos / TILE_SIZE)

func gen_village_in_chunk(chunk_vec):
	for village_pos in village_positions:
		if tile_in_chunk(village_pos, chunk_vec):
			gen_village(village_pos)

func gen_village(tile_vec):
	if !village_list.has(tile_vec):
		village_positions.erase(tile_vec)
		village_list[tile_vec] = VILLAGE.instantiate()
		village_list[tile_vec].position = tile_vec*TILE_SIZE + Vector2i.ONE * TILE_SIZE/2
		add_child(village_list[tile_vec])
		for x in range(-2,3):
			for y in range(-2,3):
				modify_tile_sys(tile_vec + Vector2i(x,y), 0)


func modify_tile_sys(tile_vec, tile_type):
	tiles.set_cell(tile_vec, tile_type, Vector2i.ZERO)
	modified_tiles[tile_vec] = tile_type

func modify_tile(tile_vec, tile_type):
	tiles.set_cell(tile_vec, tile_type, Vector2i.ZERO)
	modified_tiles[tile_vec] = tile_type
	rebake_nav_region(get_chunk_at_tile(tile_vec))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		
		for i in range(0,100):
			var n_enemy = ENEMY.instantiate()
			n_enemy.group = enemy_counter
			enemy_counter = (enemy_counter + 1) % ENEMY_GROUP_TOTAL
			n_enemy.global_position = (Vector2i(3,3) * TILE_SIZE + Vector2i.ONE * TILE_SIZE/2)
			add_child(n_enemy)

		pass
