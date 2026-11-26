extends LimboState

const FINISHED := &"ability_finished"

@export var ability_name := ""
@export_range(0.05, 5.0, 0.05, "or_greater") var duration := 0.3
@export_range(0.1, 30.0, 0.1, "or_greater") var cooldown := 3.0

var time_left := 0.0

func _enter() -> void:
	time_left = duration

func _update(delta: float) -> void:
	var elapsed := minf(time_left, delta)
	_apply(elapsed)
	time_left -= elapsed
	if time_left <= 0.0:
		dispatch(FINISHED)

func _apply(_delta: float) -> void:
	pass

func should_use(_rival: Node, _distance: float) -> bool:
	return false
