extends CharacterBody2D


@export var speed:float = 3
@export var acceleration:float = 10
@export var direction:float = 20
@export var deceleration : float = 32
@export var jump_height : float = 1.7
@export var air_control:float = 2

var jump_velocity:float
var initial_speed:float

var gravity:float = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_dead:bool
var is_attacking:bool
var can_sliding:bool = true
var climb_adsorptioning:bool

var now_state:String = "idle"

var touched_walls:Array

func _ready() -> void:
	speed *= 32
	acceleration *= 32
	deceleration *= 32
	jump_height *= 32
	#air_control *= 32
	jump_velocity = sqrt(jump_height * gravity * 2) * -1
	initial_speed = speed


func _process(_delta : float):
	if is_on_floor():
		if direction == 0:
			if now_state == "squat_idle" or now_state == "squat_walk":
				now_state = "squat_idle"
			else:
				now_state = "idle"
		else:
			if now_state == "squat_idle" or now_state == "squat_walk":
				now_state = "squat_walk"
			elif now_state == "sliding":
				pass
			else:
				now_state = "run"
	elif is_on_wall_only() and direction and touched_walls:
		now_state = "climb"
		climb_adsorptioning = true
		$ClimbAdsorptionTime.start()
	else:
		now_state = "jump"
	
	if now_state == "sliding":
		if speed <= 0:
			speed = 0
		else:
			speed -= 1
	
	change_animation(now_state)


func _physics_process(delta:float) -> void:
	move(Input.get_axis("run_left", "run_right"))
	
	if is_on_floor():
		ground_physics(delta)
	else:
		air_physics(delta)
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	move_and_slide()
	position = position.round()


func ground_physics(delta : float):
	# When the player stops moving, gradually slow down to zero.
	if direction == 0:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		
	# When moving continuously in one direction, gradually accelerate.
	elif velocity.x == 0 or sign(direction) == sign(velocity.x):
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	
	# When moving in the opposite direction, gradually slow down.
	else:
		velocity.x = move_toward(velocity.x, direction * speed, deceleration * delta)
	

func air_physics(delta:float):
	climb_adsorptioning = false
	if now_state == "climb":
		velocity.y += gravity * 0.005
		if velocity.y < 0:velocity.y *= 0.5
	else:
		velocity.y += gravity * delta
		
		if direction:
			velocity.x = move_toward(velocity.x, direction * speed, acceleration * air_control * delta)


func move(new_direction : float):
	if is_dead:
		direction = 0
	elif climb_adsorptioning:
		return
	else:
		direction = new_direction
		if direction < 0:
			$AnimatedSprite2D.scale = Vector2(-1,1)
		elif direction > 0:
			$AnimatedSprite2D.scale = Vector2(1,1)


func change_animation(state_name:String):
	if $AnimatedSprite2D.animation != state_name:
		if now_state == "squat_walk" and state_name == "walk":
			return
		$AnimatedSprite2D.play(state_name)


func _input(event : InputEvent):
	if event.is_action_pressed("jump"):
		jump()
	
	if event.is_action_released("jump"):
		stop_jump()
	
	if event.is_action_pressed("down"):
		squat()
		
	if event.is_action_released("down"):
		stop_squat()


func squat():
	if direction == 0 or (velocity.x < 95 and velocity.x > -95):
		now_state = "squat_idle"
		speed = initial_speed * 0.4
	else:
		if can_sliding:
			can_sliding = false
			$SlidingCoolingTimer.start()
			speed = initial_speed * 3
			now_state = "sliding"
	
	$CollisionShape2D.position = Vector2(0,1)
	$CollisionShape2D.shape.radius = 6
	$CollisionShape2D.shape.height = 13


func stop_squat():
	now_state = "walk"
	speed = initial_speed
	$CollisionShape2D.position = Vector2(0,-1)
	$CollisionShape2D.shape.radius = 6
	$CollisionShape2D.shape.height = 18


func jump():
	if is_dead:
		return
	if is_on_floor():
		velocity.y = jump_velocity
		$AudioStreamPlayer2D.play()
	
	elif now_state == "climb":
		
		if direction < 0:
			
			if !touched_walls:
				velocity.x += jump_velocity*0.5
				return
			
			velocity.x -= jump_velocity*0.37
			velocity.y = jump_velocity*2.2
			$AudioStreamPlayer2D.play()
			
		elif direction > 0:
			
			if !touched_walls:
				velocity.x -= jump_velocity*0.5
				return
			
			velocity.x += jump_velocity*0.37
			velocity.y = jump_velocity*2.2
			$AudioStreamPlayer2D.play()
			
		else:
			pass


func stop_jump():
	if is_dead:
		return
	if velocity.y < 0:
		velocity.y /= 2


func _on_climb_adsorption_time_timeout() -> void:
	climb_adsorptioning = false


func _on_wall_detection_area_2d_body_entered(body: Node2D) -> void:
	touched_walls.append(body)


func _on_wall_detection_area_2d_body_exited(body: Node2D) -> void:
	touched_walls.erase(body)


func _on_sliding_cooling_timer_timeout() -> void:
	can_sliding = true
