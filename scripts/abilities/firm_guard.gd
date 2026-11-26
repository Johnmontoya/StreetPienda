extends "res://scripts/abilities/ability_state.gd"

const Fighter := preload("res://scripts/fighter.gd")

var fighter: Fighter

func _setup() -> void:
	fighter = agent as Fighter

func _enter() -> void:
	super._enter()
	fighter.stance = &"guard"
	fighter.block_reaction_scale = 0.0

func _exit() -> void:
	fighter.stance = &"idle"
	fighter.block_reaction_scale = 1.0

func should_use(rival: Node, distance: float) -> bool:
	return distance <= 130.0 and Fighter.ATTACKS.has((rival as Fighter).stance)
