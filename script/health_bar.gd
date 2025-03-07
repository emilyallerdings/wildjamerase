extends ColorRect


const CHUNK = preload("res://scenes/chunk.tscn")

@export var green:Color
@export var orange:Color
@export var red:Color

@export var black:Color

var chunks = []

var cur_color = green

func set_health(health):
	
	if health <= 0:
		for i in range(0, 13):
			chunks[i].color = black
			
	var cur = clamp(health*13,0,13)
	#print("health: ", cur)
	cur_color = green
	if cur < 13 * 0.75:
		cur_color = orange
	if cur < 13 * 0.33:
		cur_color = red
	
	for i in range(0, 13):
		if i < cur:
			chunks[i].color = cur_color
		else:
			chunks[i].color = black

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	green = green * 1.5
	orange = orange * 1.5
	red = red * 1.5
	
	for i in range(0,13):
		var n_chunk = CHUNK.instantiate()
		n_chunk.position.y += 14*i
		n_chunk.color = green
		chunks.append(n_chunk)
		add_child(n_chunk)
	chunks.reverse()
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
