extends Node2D

var explored = false

var ammo_bought = 0
var repair_bought = 0
var mine_upgrade = false
var damage_upgrade = false
var rate_upgrade = false
var open = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if open && Global.player_ref.global_position.distance_to(global_position) > 256:
		open = false
		Global.main_ref.shop.visible = false
	if Global.player_ref.global_position.distance_to(global_position) <= 256 && Global.can_shop == true:
		$Label.visible = true
		if Input.is_action_just_pressed("interact"):
			print(open)
			if !open:
				Global.cur_shop = self
				open = true
				Global.main_ref.shop.visible = true
			else:
				open = false
				Global.main_ref.shop.visible = false
	else:
		$Label.visible = false
	pass
