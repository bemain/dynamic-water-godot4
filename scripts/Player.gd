extends CollidingObject

@export var speed = 400


func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	move_and_slide()
	
	super._physics_process(delta)
