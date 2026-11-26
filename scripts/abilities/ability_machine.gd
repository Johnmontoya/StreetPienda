extends LimboHSM

const AbilityState := preload("res://scripts/abilities/ability_state.gd")

const ACTIVATE := &"activate_ability"
const RECHARGED := &"ability_recharged"

@onready var ready_state: LimboState = $Ready
@onready var ability_state: AbilityState = $Active
@onready var cooldown_state: LimboState = $Cooldown

var cooldown_left := 0.0

func _ready() -> void:
	update_mode = LimboHSM.MANUAL
	initial_state = ready_state
	add_transition(ready_state, ability_state, ACTIVATE)
	add_transition(ability_state, cooldown_state, AbilityState.FINISHED)
	add_transition(cooldown_state, ready_state, RECHARGED)
	cooldown_state.entered.connect(_start_cooldown)

func reset() -> void:
	set_active(false)
	cooldown_left = 0.0
	set_active(true)

func is_available() -> bool:
	return get_active_state() == ready_state

func is_using_ability() -> bool:
	return get_active_state() == ability_state

func should_use(rival: Node, distance: float) -> bool:
	return is_available() and ability_state.should_use(rival, distance)

func advance_ability(delta: float) -> bool:
	var was_using_ability := is_using_ability()
	if get_active_state() == cooldown_state:
		cooldown_left = maxf(0.0, cooldown_left - delta)
		if cooldown_left <= 0.0:
			dispatch(RECHARGED)
	update(delta)
	return was_using_ability

func interrupt() -> void:
	if is_using_ability():
		dispatch(AbilityState.FINISHED)

func _start_cooldown() -> void:
	cooldown_left = ability_state.cooldown
