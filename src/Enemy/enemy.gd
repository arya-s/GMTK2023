extends CharacterBody3D

@onready var navigation_agent = $NavigationAgent3D
@onready var model = $model

var SPEED = 3.0

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		return
	
	var next_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	var new_velocity = direction * SPEED
	navigation_agent.set_velocity(new_velocity)
	
	if direction:
		look_at(position + Vector3(direction.x, 0, direction.z))

func update_target_position(target_pos: Vector3):
	navigation_agent.set_target_position(target_pos)


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()
