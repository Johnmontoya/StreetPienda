extends Node2D

const MAX_HEALTH := 100
const GRAVITY := 1500.0
const WALK_SPEED := 233.0
const JUMP_SPEED := 525.0
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

enum Character { MARA, NICO }

var fighter_name := ""
var accent := Color.WHITE
var dark := Color.WHITE
var skin := Color.WHITE
var face := 1.0
var health := MAX_HEALTH
var elevation := 0.0
var vertical_speed := 0.0
var movement := 0.0
var clock := 0.0
var stance := &"idle"
var grounded := true
var attack_time := 0.0
var connected := false
var hit_confirmed := false
var queued_attack := &""
var stun_left := 0.0
var knockback := 0.0
var hits_taken := 0
var combo_hits := 0
var combo_display_left := 0.0

func configure(character: Character) -> void:
	match character:
		Character.MARA:
			fighter_name = "MARA"
			accent = Color("#53f1d4")
			dark = Color("#255c72")
			skin = Color("#f8b58d")
		Character.NICO:
			fighter_name = "NICO"
			accent = Color("#ff785c")
			dark = Color("#773454")
			skin = Color("#b9735c")

func reset_at(x: float, floor_y: float, direction: float) -> void:
	position = Vector2(x, floor_y)
	face = direction
	health = MAX_HEALTH
	elevation = 0.0
	vertical_speed = 0.0
	movement = 0.0
	clock = 0.0
	stance = &"idle"
	grounded = true
	attack_time = 0.0
	_clear_attack()
	stun_left = 0.0
	knockback = 0.0
	hits_taken = 0
	combo_hits = 0
	combo_display_left = 0.0
	queue_redraw()

func step(delta: float, axis: float, jump: bool, guard: bool, strike: StringName, rival_x: float) -> void:
	clock += delta
	movement = 0.0
	if ATTACKS.has(stance):
		_step_attack(delta, strike)
	elif stun_left > 0.0:
		stun_left = maxf(0.0, stun_left - delta)
		position.x += knockback * delta
		knockback = move_toward(knockback, 0.0, delta * 900.0)
	else:
		if absf(rival_x - position.x) > 1.0:
			face = signf(rival_x - position.x)
		stance = &"idle"
		if grounded and guard:
			stance = &"guard"
		elif strike != &"":
			_start_attack(strike)
		else:
			movement = axis
			position.x += axis * WALK_SPEED * delta
			if grounded and jump:
				vertical_speed = JUMP_SPEED
				grounded = false

	if not grounded:
		elevation += vertical_speed * delta
		vertical_speed -= GRAVITY * delta
		if elevation <= 0.0:
			elevation = 0.0
			vertical_speed = 0.0
			grounded = true
	queue_redraw()

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
	stance = &"guard" if blocked else &"hurt"
	stun_left = 0.15 if blocked else float(move["stun"])
	knockback = float(contact["direction"]) * (105.0 if blocked else 220.0)
	_clear_attack()
	return hits_taken

func _limb(a: Vector2, b: Vector2, c: Vector2, tint: Color, thickness: float) -> void:
	var outline := Color("#121324")
	draw_polyline(PackedVector2Array([a, b, c]), outline, thickness + 6.0, true)
	draw_circle(b, (thickness + 5.0) * 0.5, outline)
	draw_polyline(PackedVector2Array([a, b, c]), tint, thickness, true)
	draw_circle(b, thickness * 0.5, tint)

func _draw() -> void:
	var shadow_scale := 1.0 - clampf(elevation / 160.0, 0.0, 0.55)
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(shadow_scale, 0.24 * shadow_scale))
	draw_circle(Vector2.ZERO, 45, Color(0.02, 0.02, 0.08, 0.48))
	draw_set_transform(Vector2(0, -elevation), 0.0, Vector2(face, 1))
	var walk := sin(clock * 17.0) * 15.0 * absf(movement)
	var bob := sin(clock * 8.0) * 2.0
	var lean := -12.0 if stance == &"hurt" else 0.0
	var hip := Vector2(lean * 0.4, -48 + bob)
	var shoulder := Vector2(lean + 3, -91 + bob)
	var back_foot := Vector2(-23 - walk, -2)
	var front_foot := Vector2(22 + walk, -2)
	if not grounded:
		back_foot.y = -15
		front_foot.y = -22
	var extended := 0.0
	if ATTACKS.has(stance):
		var move: Dictionary = ATTACKS[stance]
		extended = clampf(attack_time / float(move["start"]), 0.0, 1.0)
		if attack_time > float(move["end"]):
			extended = clampf((float(move["total"]) - attack_time) / (float(move["total"]) - float(move["end"])), 0.0, 1.0)
	if stance == &"cross":
		shoulder += Vector2(12, -2) * extended
	var front_knee := Vector2(16 + walk * 0.5, -27)
	if stance in [&"kick", &"finisher"]:
		var kick_height := -60.0 if stance == &"finisher" else -45.0
		front_foot = front_foot.lerp(Vector2(97, kick_height), extended)
		front_knee = front_knee.lerp(Vector2(51, kick_height + 4), extended)
	_limb(hip, Vector2(-17 - walk * 0.5, -25), back_foot, dark.darkened(0.22), 14)
	_limb(hip, front_knee, front_foot, dark, 17)
	draw_line(back_foot - Vector2(5, 1), back_foot + Vector2(11, 1), Color("#101020"), 9, true)
	draw_line(front_foot - Vector2(5, 1), front_foot + Vector2(12, 1), Color("#101020"), 10, true)
	var back_hand := shoulder + Vector2(25, 3)
	if stance == &"guard":
		back_hand = shoulder + Vector2(15, -19)
	_limb(shoulder + Vector2(-7, 2), shoulder + Vector2(-3, 20), back_hand, skin.darkened(0.28), 10)
	draw_circle(back_hand, 8, dark)
	var torso := PackedVector2Array([
		shoulder + Vector2(-17, -5), shoulder + Vector2(13, -4),
		hip + Vector2(14, 2), hip + Vector2(-17, 4),
	])
	draw_colored_polygon(torso, accent)
	var border := torso.duplicate()
	border.append(torso[0])
	draw_polyline(border, Color("#121324"), 4, true)
	draw_line(shoulder + Vector2(-11, 1), hip + Vector2(-5, -3), accent.lightened(0.35), 3, true)
	draw_line(hip + Vector2(-16, 1), hip + Vector2(14, -2), dark, 6, true)
	var head := shoulder + Vector2(3, -19)
	draw_circle(head, 17, Color("#121324"))
	draw_circle(head, 14, skin)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-14, 3), head + Vector2(-17, -8), head + Vector2(-9, -17),
		head + Vector2(12, -16), head + Vector2(16, -7), head + Vector2(-4, -7),
		head + Vector2(-7, 3),
	]), Color("#19182b"))
	draw_line(head + Vector2(-12, -8), head + Vector2(14, -8), accent, 3, true)
	draw_line(head + Vector2(6, -2), head + Vector2(12, -2), Color("#19182b"), 2, true)
	var elbow := shoulder + Vector2(9, 26)
	var fist := shoulder + Vector2(30, 13)
	if stance in [&"punch", &"cross"]:
		elbow = elbow.lerp(shoulder + Vector2(39, 11), extended)
		var punch_height := -87.0 if stance == &"cross" else -77.0
		fist = fist.lerp(Vector2(76, punch_height), extended)
	elif stance == &"guard":
		elbow = shoulder + Vector2(13, 22)
		fist = shoulder + Vector2(26, -9)
	_limb(shoulder + Vector2(4, 7), elbow, fist, skin, 11)
	draw_circle(fist, 10, Color("#121324"))
	draw_circle(fist, 7, accent.lightened(0.12))
