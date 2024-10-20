extends Node2D


func _physics_process(_delta: float) -> void:
	var target = %Player.global_position
	var x = int(lerp(global_position.x,target.x,0.2))
	var y = int(lerp(global_position.y,target.y,0.2))
	global_position = Vector2(x,y)
