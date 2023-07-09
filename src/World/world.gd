extends Node3D


@onready var player = $Player

func _physics_process(delta):
	if not player.is_cowering:
		get_tree().call_group("enemy", "update_target_position", player.global_position)
	else:
		get_tree().call_group("enemy", "stop_navigation")
