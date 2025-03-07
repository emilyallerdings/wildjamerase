extends Node2D

var CHUNK_LEN = 6
var CHUNK_SIZE = CHUNK_LEN*CHUNK_LEN
var RENDER_RAD = 3

var TILE_SIZE = 64

var all_chunk = {}

var loaded_chunks = []
var prev_chunk = Vector2.ZERO
var redraw = true

@onready var player: CharacterBody2D = $Player

var wall_color = Color.html("4f78c4")
var floor_color = Color.html("1b273d")

enum tile{EMPTY,STONE}

var default_font = ThemeDB.fallback_font
var default_font_size = ThemeDB.fallback_font_size



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	loaded_chunks.clear()
	for x in range(-RENDER_RAD,RENDER_RAD):
		for y in range(-RENDER_RAD,RENDER_RAD):
			var new_vec = prev_chunk + Vector2(x,y)
			get_chunk(new_vec)
			loaded_chunks.append(new_vec)
			
	player.global_position = Vector2.ZERO + Vector2(1,1) * TILE_SIZE/2
	var starting_tile = get_global_tile_at_pos(player.global_position)
	for x in range(-2,3):
		for y in range(-2,3):
			set_tile_from_global_tile(starting_tile + Vector2(x,y), tile.EMPTY)
	#print_chunk(get_chunk_at_pos(player.global_position))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	var cur_chunk = get_chunk_at_pos(player.global_position)
	if prev_chunk != cur_chunk:
		prev_chunk = cur_chunk
		loaded_chunks.clear()
		for x in range(-RENDER_RAD,RENDER_RAD):
			for y in range(-RENDER_RAD,RENDER_RAD):
				var new_vec = cur_chunk + Vector2(x,y)
				get_chunk(new_vec)
				loaded_chunks.append(new_vec)
		redraw = true
		
	
	if redraw:
		queue_redraw()
		redraw = false
	
	#print("player tile: ", get_global_tile_at_pos(player.global_position))
	
	var fps = Engine.get_frames_per_second()
	pass
	
func _draw() -> void:
	for chunk_vec in loaded_chunks:
		var chunk_arr = get_chunk(chunk_vec)
		for x in range(0,CHUNK_LEN):
			for y in range(0,CHUNK_LEN):
				var tile_num = y*CHUNK_LEN + x
				var color
				if chunk_arr[tile_num] == tile.STONE:
					color = wall_color
				else:
					color = floor_color
				var pos = Vector2((chunk_vec.x * CHUNK_LEN + x) * TILE_SIZE,
											 (chunk_vec.y * CHUNK_LEN + y) * TILE_SIZE)
											
				draw_rect(Rect2(pos, TILE_SIZE*Vector2.ONE), color, true)
				
				#var gx = int(x + chunk_vec.x * CHUNK_LEN)
				#var gy = int(y + chunk_vec.y * CHUNK_LEN)
				#
				#var rel_x = ((gx % CHUNK_LEN) + CHUNK_LEN) % CHUNK_LEN
				#var rel_y = ((gy % CHUNK_LEN) + CHUNK_LEN) % CHUNK_LEN
				#
				#draw_string(default_font, pos + Vector2(4,16), "(" + str(gx) + "," + str(gy) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size)
				#draw_string(default_font, pos + Vector2(4,32), "(" + str(rel_x) + "," + str(rel_y) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size)
	return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		var tile_vec = get_global_tile_at_pos(get_global_mouse_position())
		set_tile_from_global_tile(tile_vec, tile.EMPTY)
		#print(tile_vec)

func init_chunk_arr():
	var chunk_arr = []
	chunk_arr.resize(CHUNK_SIZE)
	chunk_arr.fill(tile.STONE)
	return chunk_arr

func get_chunk(vec):
	if !all_chunk.has(vec):
		all_chunk[vec] = init_chunk_arr()
	return all_chunk[vec]

func get_chunk_at_pos(pos):
	var tile_pos = get_global_tile_at_pos(pos)
	return Vector2(floor(tile_pos / CHUNK_LEN))

func get_global_tile_at_pos(pos):
	return Vector2(floor(pos.x / TILE_SIZE), floor(pos.y / TILE_SIZE))

func set_tile_from_global_tile(tile_vec, type):
	var chunk_vec = Vector2(floor(tile_vec / CHUNK_LEN))
	if all_chunk.has(chunk_vec):
		var chunk = all_chunk[chunk_vec]
		var rel_x = ((int(tile_vec.x) % CHUNK_LEN) + CHUNK_LEN) % CHUNK_LEN
		var rel_y = ((int(tile_vec.y) % CHUNK_LEN) + CHUNK_LEN) % CHUNK_LEN
		chunk[rel_y * CHUNK_LEN + rel_x] = type
		redraw = true

func print_chunk(chunk_vec):
	var chunk = all_chunk[chunk_vec]
	for y in range(0,CHUNK_LEN):
		var str = ""
		for x in range(0,CHUNK_LEN):
			str += str(chunk[y * CHUNK_LEN + x])
