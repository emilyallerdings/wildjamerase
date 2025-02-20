extends StaticBody2D
class_name MiningTile

var being_mined = false

var mine_progress = 0.0

var mine_dur = 1.0

var hardness = 1.0

var tile_pos = Vector2.ZERO

func start_mining():
	being_mined = true
	
func stop_mining():
	being_mined = false

func set_tile(tile):
	$Sprite.texture = Global.text_arr[tile]
	hardness = float(Global.hardness_arr[tile])

func _process(delta: float) -> void:
	if being_mined:
		mine_progress += delta * Global.mining_mod * (1.0/hardness)
		mine_progress = clampf(mine_progress,0,1)
		if mine_progress >= mine_dur:
			get_parent().remove_tile(tile_pos)
			get_parent().stop_mining_tile(tile_pos)


	else:
		mine_progress -= delta / 10.0
		mine_progress = clampf(mine_progress,0,1)
		if mine_progress <= 0:
			get_parent().stop_mining_tile(tile_pos)

	
	var prog_norm = mine_progress/mine_dur
	
	$Sprite.material.set_shader_parameter("whiteness", prog_norm)	
