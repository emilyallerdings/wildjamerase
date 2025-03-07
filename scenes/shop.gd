extends CanvasLayer

var drill_cost_scale = 5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Global.player_ref.can_repair()
	
	if !Global.can_shop:
		visible = false
		
	if Global.cur_shop != null:
		$Panel/Repair/Cost.text = str(floor(Global.cur_shop.repair_bought * 0.25) + 1) + "x"
		$Panel/Ammo/Cost.text = str(floor(Global.cur_shop.ammo_bought * 0.25) + 1) + "x"
		$Panel/UpgradeDrill/Cost.text = str(floor(5 + Global.drill_upgrade_count * drill_cost_scale)) + "x"
		$Panel/UpgradeDamage/Cost.text = str(floor(5 + Global.damage_upgrade_count * drill_cost_scale)) + "x"
		$Panel/UpgradeRate/Cost.text = str(floor(5 + Global.rate_upgrade_count * drill_cost_scale)) + "x"
		
		if !Global.cur_shop.mine_upgrade:
			$Panel/UpgradeDrill/UpButton.text = "BUY"
			$Panel/UpgradeDrill/UpButton.disabled = false
		else:
			$Panel/UpgradeDrill/UpButton.text = "BOUGHT"
			$Panel/UpgradeDrill/UpButton.disabled = true
			
		if !Global.cur_shop.damage_upgrade:
			$Panel/UpgradeDamage/UpButton.text = "BUY"
			$Panel/UpgradeDamage/UpButton.disabled = false
		else:
			$Panel/UpgradeDamage/UpButton.text = "BOUGHT"
			$Panel/UpgradeDamage/UpButton.disabled = true
			
		if !Global.cur_shop.rate_upgrade:
			$Panel/UpgradeRate/UpButton.text = "BUY"
			$Panel/UpgradeRate/UpButton.disabled = false
		else:
			$Panel/UpgradeRate/UpButton.text = "BOUGHT"
			$Panel/UpgradeRate/UpButton.disabled = true
			
		if Global.player_ref.can_repair():
			$Panel/Repair/RepairButton.text = "BUY"
			$Panel/Repair/RepairButton.disabled = false
		else:
			$Panel/Repair/RepairButton.text = "FULL"
			$Panel/Repair/RepairButton.disabled = true
			
		if Global.player_ref.can_ammo():
			$Panel/Ammo/AmmoButton.text = "BUY"
			$Panel/Ammo/AmmoButton.disabled = false
		else:
			$Panel/Ammo/AmmoButton.text = "FULL"
			$Panel/Ammo/AmmoButton.disabled = true
	pass


func _on_repair_button_pressed() -> void:
	if Global.cur_shop == null:
		return
		
	if Global.gem_count >= floor(Global.cur_shop.repair_bought * 0.20) + 1 && Global.player_ref.can_repair():
		Global.player_ref.repair()
		Global.gem_count -= floor(Global.cur_shop.repair_bought * 0.20) + 1
		Global.cur_shop.repair_bought += 1
		$Panel/Repair/RepairSound.play(0)
	else:
		$OOps.play(0)
	pass # Replace with function body.


func _on_ammo_button_pressed() -> void:
	if Global.gem_count >= floor(Global.cur_shop.ammo_bought * 0.25) + 1 && Global.player_ref.can_ammo():
		Global.player_ref.give_ammo()
		Global.gem_count -= floor(Global.cur_shop.ammo_bought * 0.25) + 1
		Global.cur_shop.ammo_bought += 1
		$Panel/Ammo/AmmoSound.play(0)
	else:
		$OOps.play(0)
	pass # Replace with function body.

		


func _on_up_drill_button_pressed() -> void:
	if Global.cur_shop == null:
		return
	if Global.cur_shop.mine_upgrade:
		return
	if Global.gem_count >= floor(5 + Global.drill_upgrade_count * drill_cost_scale):
		Global.gem_count -= floor(5 + Global.drill_upgrade_count * drill_cost_scale)
		Global.drill_upgrade_count += 1
		Global.mining_mod += 0.18
		Global.cur_shop.mine_upgrade = true
		$Panel/UpgradeDrill/RepairSound.play(0)
	else:
		$OOps.play(0)
	pass # Replace with function body.




func _on_up_damage_button_pressed() -> void:
	if Global.cur_shop == null:
		return
	if Global.cur_shop.damage_upgrade:
		return
	if Global.gem_count >= floor(5 + Global.damage_upgrade_count * drill_cost_scale):
		Global.gem_count -= floor(5 + Global.damage_upgrade_count * drill_cost_scale)
		Global.damage_upgrade_count += 1
		Global.damage += 0.8
		Global.cur_shop.damage_upgrade = true
		$Panel/UpgradeDamage/RepairSound.play(0)
	else:
		$OOps.play(0)

func _on_up_rate_button_pressed() -> void:
	if Global.cur_shop == null:
		return
	if Global.cur_shop.rate_upgrade:
		return
	if Global.gem_count >= floor(5 + Global.rate_upgrade_count * drill_cost_scale):
		Global.gem_count -= floor(5 + Global.rate_upgrade_count * drill_cost_scale)
		Global.rate_upgrade_count += 1
		Global.rate += 0.14
		Global.cur_shop.rate_upgrade = true
		$Panel/UpgradeRate/RepairSound.play(0)
	else:
		$OOps.play(0)
