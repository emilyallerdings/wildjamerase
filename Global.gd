extends Node

var player_ref = null
var nav_reg_ref:NavigationRegion2D = null
var main_ref = null

var mining_mod = 1
var speed = 350

var diff_scale = 1.0

var text_arr = [preload("res://assets/floor.png"),
 preload("res://assets/wall.png"),
 preload("res://assets/hard_wall.png"),
preload("res://assets/wall_gem.png"),
preload("res://assets/hard_wall_gem.png")
]
var hardness_arr = [0, 1, 2.5, 1.5, 2.5]
