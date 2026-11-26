extends Node2D

const AbilityMachine := preload("res://scripts/abilities/ability_machine.gd")

const MAX_HEALTH := 100
const GRAVITY := 1500.0
const ATTACKS := {
	&"punch": {"start": 0.09, "end": 0.17, "total": 0.32, "reach": 94.0, "height": 67.0, "damage": 10, "stun": 0.22},
	&"kick": {"start": 0.17, "end": 0.27, "total": 0.52, "reach": 128.0, "height": 42.0, "damage": 17, "stun": 0.31},
	&"cross": {"start": 0.075, "end": 0.145, "total": 0.31, "reach": 112.0, "height": 67.0, "damage": 8, "stun": 0.24, "advance": 52.0},
	&"finisher": {"start": 0.095, "end": 0.18, "total": 0.54, "reach": 139.0, "height": 42.0, "damage": 15, "stun": 0.31, "advance": 26.0},
}
const FOLLOW_UPS := {
	&"punch": {&"punch": &"cross", &"kick": &"finisher"},
	&"kick": {&"punch": &"cross"},
	&"cross": {&"kick": &"finisher"},
}
const CANCEL_GRACE := 0.04
const COMBO_DISPLAY_TIME := 1.1

@export var fighter_name := ""
@export var accent := Color.WHITE
@export_range(1.0, 1000.0, 1.0, "or_greater") var walk_speed := 233.0
@export_range(1.0, 1000.0, 1.0, "or_greater") var jump_speed := 525.0
@export var face := 1.0

@onready var visual: Node2D = $Visual
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ability: AbilityMachine = get_node_or_null("Ability")

var health := MAX_HEALTH
var elevation := 0.0
var vertical_speed := 0.0
var movement := 0.0
var stance := &"idle"
var grounded := true
var attack_time := 0.0
var connected := false
var hit_confirmed := false
var queued_attack := &""
var stun_left := 0.0
var knockback := 0.0
var block_reaction_scale := 1.0
var hits_taken := 0
var combo_hits := 0
var combo_display_left := 0.0

func _ready() -> void:
	if ability != null:
		ability.initialize(self)
		ability.set_active(true)
	_update_visual(0.0)

func reset_at(x: float, floor_y: float, direction: float) -> void:
	if ability != null:
		ability.reset()
	position = Vector2(x, floor_y)
	face = direction
	health = MAX_HEALTH
	elevation = 0.0
	vertical_speed = 0.0
	movement = 0.0
	stance = &"idle"
	grounded = true
	attack_time = 0.0
	_clear_attack()
	stun_left = 0.0
	knockback = 0.0
	block_reaction_scale = 1.0
	hits_taken = 0
	combo_hits = 0
	combo_display_left = 0.0
	animation_player.stop()
	animation_player.play(&"idle")
	_update_visual(0.0)

func step(delta: float, axis: float, jump: bool, guard: bool, strike: StringName, rival_x: float, special := false) -> void:
	movement = 0.0
	if ability != null:
		if special and ability.is_available() and grounded and stun_left <= 0.0 and not ATTACKS.has(stance):
			_face_rival(rival_x)
			stance = &"idle"
			ability.dispatch(AbilityMachine.ACTIVATE)
		if ability.advance_ability(delta):
			_update_visual(delta)
			return
	if ATTACKS.has(stance):
		_step_attack(delta, strike)
	elif stun_left > 0.0:
		stun_left = maxf(0.0, stun_left - delta)
		position.x += knockback * delta
		knockback = move_toward(knockback, 0.0, delta * 900.0)
	else:
		_face_rival(rival_x)
		stance = &"idle"
		if grounded and guard:
			stance = &"guard"
		elif strike != &"":
			_start_attack(strike)
		else:
			movement = axis
			position.x += axis * walk_speed * delta
			if grounded and jump:
				vertical_speed = jump_speed
				grounded = false

	if not grounded:
		elevation += vertical_speed * delta
		vertical_speed -= GRAVITY * delta
		if elevation <= 0.0:
			elevation = 0.0
			vertical_speed = 0.0
			grounded = true
	_update_visual(delta)

func _face_rival(rival_x: float) -> void:
	if absf(rival_x - position.x) > 1.0:
		face = signf(rival_x - position.x)

func _step_attack(delta: float, strike: StringName) -> void:
	var move: Dictionary = ATTACKS[stance]
	var active_end: float = move["end"]
	buffer_follow_up(strike)
	var startup: float = move["start"]
	var previous_time := attack_time
	attack_time += delta
	if grounded and move.has("advance"):
		var startup_progress := (minf(attack_time, startup) - minf(previous_time, startup)) / startup
		position.x += face * float(move["advance"]) * startup_progress
	if hit_confirmed and queued_attack != &"" and attack_time > active_end:
		_start_attack(queued_attack)
	elif attack_time >= float(move["total"]):
		stance = &"idle"
		_clear_attack()

func buffer_follow_up(strike: StringName) -> void:
	if strike == &"" or queued_attack != &"" or not grounded:
		return
	if not FOLLOW_UPS.has(stance) or (connected and not hit_confirmed):
		return
	if attack_time > float(ATTACKS[stance]["end"]) + CANCEL_GRACE:
		return
	queued_attack = FOLLOW_UPS[stance].get(strike, &"")

func _start_attack(attack: StringName) -> void:
	stance = attack
	attack_time = 0.0
	_clear_attack()

func _clear_attack() -> void:
	connected = false
	hit_confirmed = false
	queued_attack = &""

func contact_with(rival) -> Dictionary:
	if not ATTACKS.has(stance) or connected:
		return {}
	var move: Dictionary = ATTACKS[stance]
	if attack_time < float(move["start"]) or attack_time > float(move["end"]):
		return {}
	var ahead: float = (rival.position.x - position.x) * face
	var height_difference: float = elevation + float(move["height"]) - rival.elevation
	if ahead < 0.0 or ahead > float(move["reach"]) or height_difference < 13.0 or height_difference > 105.0:
		return {}
	connected = true
	var blocked: bool = rival.stance == &"guard" and (position.x - rival.position.x) * rival.face > 0.0
	hit_confirmed = not blocked and grounded and rival.grounded
	return {"move": move, "blocked": blocked, "direction": face}

func receive(contact: Dictionary) -> int:
	var move: Dictionary = contact["move"]
	var blocked: bool = contact["blocked"]
	if blocked:
		hits_taken = 0
	else:
		# A hit starts a new count once the defender has recovered.
		var continuing := stance == &"hurt" and stun_left > 0.0
		hits_taken = hits_taken + 1 if continuing else 1
		health = maxi(0, health - int(move["damage"]))
		if ability != null:
			ability.interrupt()
	stance = &"guard" if blocked else &"hurt"
	stun_left = 0.15 * block_reaction_scale if blocked else float(move["stun"])
	knockback = float(contact["direction"]) * (105.0 * block_reaction_scale if blocked else 220.0)
	_clear_attack()
	_update_visual(0.0)
	return hits_taken

func _update_visual(delta: float) -> void:
	visual.transform = Transform2D(Vector2(face, 0), Vector2.DOWN, Vector2(0, -elevation))
	var pose := stance
	if stance == &"idle":
		if not grounded:
			pose = &"jump"
		elif not is_zero_approx(movement):
			pose = &"walk"
	if animation_player.assigned_animation != pose:
		animation_player.play(pose)
		animation_player.advance(0.0)
	if ATTACKS.has(stance):
		# Combat owns this clock, including when one attack cancels into another.
		animation_player.seek(attack_time, true)
	else:
		animation_player.advance(delta)
	queue_redraw()

func _draw() -> void:
	var shadow_scale := 1.0 - clampf(elevation / 160.0, 0.0, 0.55)
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(shadow_scale, 0.24 * shadow_scale))
	draw_circle(Vector2.ZERO, 45, Color(0.02, 0.02, 0.08, 0.48))
	if ability != null and ability.is_using_ability():
		draw_circle(Vector2.ZERO, 42, Color(accent, 0.25))
		draw_circle(Vector2.ZERO, 42, accent, false, 3.0, true)
