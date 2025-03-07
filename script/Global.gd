extends Node

var player_ref = null
var nav_reg_ref:NavigationRegion2D = null
var main_ref = null
var gem_count = 0
var can_shop = true

var mining_mod = 1.1
var speed = 350
var rate = 0.9

var cur_shop = null

var damage = 5

var drill_upgrade_count = 0
var damage_upgrade_count = 0
var rate_upgrade_count = 0

var diff_scale = 4.0

const FREE_AUDIO = preload("res://scenes/FreeAudio.tscn")
const METAL_HIT_2 = preload("res://assets/audio/metal_hit2.ogg")
const VAPORIZE = preload("res://assets/audio/vaporize.ogg")

const BLOOD_PARTICLES = preload("res://scenes/blood_particles.tscn")
const BREAK_PARTICLES = preload("res://scenes/BreakParticles.tscn")

var text_arr = [preload("res://assets/floor.png"),
 preload("res://assets/wall.png"),
 preload("res://assets/hard_wall.png"),
preload("res://assets/wall_gem.png"),
preload("res://assets/hard_wall_gem.png")
]
var hardness_arr = [0, 1, 3, 1.25, 3.25]

func reset():
	gem_count = 0
	can_shop = true
	cur_shop = null
	speed = 350
	
	mining_mod = 1.12
	rate = 0.9
	damage = 5
	
	drill_upgrade_count = 0
	damage_upgrade_count = 0
	rate_upgrade_count = 0

	diff_scale = 4.0
