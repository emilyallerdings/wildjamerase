extends Node

var player_ref = null
var nav_reg_ref:NavigationRegion2D = null
var main_ref = null

var mining_mod = 40
var speed = 600

var text_arr = [preload("res://assets/floor.png"),
 preload("res://assets/wall.png"),
 preload("res://assets/hard_wall.png"),
preload("res://assets/wall_gem.png")]
var hardness_arr = [0, 1, 2.5, 1.5]
