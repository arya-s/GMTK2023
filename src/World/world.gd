extends Node3D


@onready var player = $NavigationRegion3D/Map/Player

func _physics_process(delta):
	get_tree().call_group("enemy", "update_target_position", player.global_position)
