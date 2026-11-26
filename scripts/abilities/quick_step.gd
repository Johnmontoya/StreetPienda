extends "res://scripts/abilities/ability_state.gd"

const Fighter := preload("res://scripts/fighter.gd")

@export_range(1.0, 1000.0, 1.0, "or_greater") var distance := 96.0

var fighter: Fighter

func _setup() -> void:
	fighter = agent as Fighter

func _apply(delta: float) -> void:
	fighter.movement = fighter.face
	fighter.position.x += fighter.face * distance * delta / duration

func _exit() -> void:
	fighter.movement = 0.0

func should_use(_rival: Node, distance_to_rival: float) -> bool:
	return distance_to_rival >= 170.0 and distance_to_rival <= 250.0
