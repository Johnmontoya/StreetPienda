extends Node2D

const Fighter := preload("res://scripts/fighter.gd")
const FLOOR_Y := 423.0
const ROUND_TIME := 45.0
const ROUNDS_TO_WIN := 2
const BODY_WIDTH := 54.0
const BOUNDS := Vector2(61.0, 899.0)

enum Phase { INTRO, FIGHT, ROUND_END, MATCH_END }
enum Mode { CPU, LOCAL, STORY }

const CONTROLS := {
	"p1_left": KEY_A, "p1_right": KEY_D, "p1_jump": KEY_W,
	"p1_guard": KEY_S, "p1_punch": KEY_F, "p1_kick": KEY_G,
	"p2_left": KEY_LEFT, "p2_right": KEY_RIGHT, "p2_jump": KEY_UP,
	"p2_guard": KEY_DOWN, "p2_punch": KEY_K, "p2_kick": KEY_L,
	"mode_cpu": KEY_F1, "mode_local": KEY_F2, "restart": KEY_R, "pause_match": KEY_ESCAPE,
	"return_to_menu": KEY_M,
}

@export var mode := Mode.CPU

var first := Fighter.new()
var second := Fighter.new()
var phase := Phase.INTRO
var round_number := 1
var first_wins := 0
var second_wins := 0
var time_left := ROUND_TIME
var phase_left := 0.0
var paused := false
var local_multiplayer: bool:
	get:
		return mode == Mode.LOCAL
var result := ""
var spark_time := 0.0
var spark_position := Vector2.ZERO
var spark_color := Color.WHITE
var cpu_wait := 0.0
var cpu_guard := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	for action: String in CONTROLS:
		if InputMap.has_action(action):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = CONTROLS[action]
		InputMap.add_action(action)
		InputMap.action_add_event(action, event)
	$Overlay/HUD.arena = self
	$Overlay/HUD/MenuButton.pressed.connect(return_to_menu)
	first.configure(Fighter.Character.MARA)
	second.configure(Fighter.Character.NICO)
	add_child(first)
	add_child(second)
	_new_match(mode)

func _new_match(next_mode: Mode) -> void:
	mode = next_mode
	first_wins = 0
	second_wins = 0
	round_number = 1
	paused = false
	_new_round()

func return_to_menu() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if error != OK:
		push_error("No se pudo abrir el menú principal: %s" % error_string(error))

func _new_round() -> void:
	first.reset_at(305.0, FLOOR_Y, 1.0)
	second.reset_at(655.0, FLOOR_Y, -1.0)
	phase = Phase.INTRO
	phase_left = 1.25
	time_left = ROUND_TIME
	spark_time = 0.0
	cpu_wait = 0.0
	cpu_guard = 0.0
	result = ""

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("return_to_menu"):
		return_to_menu()
		return
	elif Input.is_action_just_pressed("mode_cpu"):
		_new_match(Mode.CPU)
	elif Input.is_action_just_pressed("mode_local"):
		_new_match(Mode.LOCAL)
	elif Input.is_action_just_pressed("restart"):
		_new_match(mode)
	elif Input.is_action_just_pressed("pause_match"):
		paused = not paused

	$Overlay/HUD.queue_redraw()
	if paused:
		return
	spark_time = maxf(0.0, spark_time - delta)
	first.combo_display_left = maxf(0.0, first.combo_display_left - delta)
	second.combo_display_left = maxf(0.0, second.combo_display_left - delta)
	if phase == Phase.MATCH_END:
		return

	phase_left -= delta
	match phase:
		Phase.INTRO:
			if phase_left <= 0.0:
				phase = Phase.FIGHT
				phase_left = 0.65
		Phase.FIGHT:
			_play_frame(delta)
		Phase.ROUND_END:
			if phase_left <= 0.0:
				round_number += 1
				_new_round()

func _play_frame(delta: float) -> void:
	var old_first := first.position.x
	var old_second := second.position.x
	_read_player(first, "p1_", delta, old_second)
	if local_multiplayer:
		_read_player(second, "p2_", delta, old_first)
	else:
		_step_cpu(delta, old_first)
	_separate(old_first <= old_second)
	var first_contact := first.contact_with(second)
	var second_contact := second.contact_with(first)
	if not first_contact.is_empty():
		_resolve_contact(first, second, first_contact)
	if not second_contact.is_empty():
		_resolve_contact(second, first, second_contact)
	time_left = maxf(0.0, time_left - delta)
	if first.health == 0 or second.health == 0 or time_left <= 0.0:
		_end_round()

func _resolve_contact(attacker: Fighter, target: Fighter, contact: Dictionary) -> void:
	var hit_count := target.receive(contact)
	if hit_count > 1:
		attacker.combo_hits = hit_count
		attacker.combo_display_left = Fighter.COMBO_DISPLAY_TIME
	_show_contact(target, contact["blocked"])
	if not local_multiplayer and attacker == second and attacker.hit_confirmed:
		var follow_ups: Dictionary = Fighter.FOLLOW_UPS.get(attacker.stance, {})
		if not follow_ups.is_empty() and rng.randf() < 0.45:
			attacker.buffer_follow_up(follow_ups.keys()[rng.randi_range(0, follow_ups.size() - 1)])

func _read_player(fighter: Fighter, prefix: String, delta: float, rival_x: float) -> void:
	var strike := &""
	if Input.is_action_just_pressed(prefix + "punch"):
		strike = &"punch"
	elif Input.is_action_just_pressed(prefix + "kick"):
		strike = &"kick"
	fighter.step(
		delta, Input.get_axis(prefix + "left", prefix + "right"),
		Input.is_action_just_pressed(prefix + "jump"),
		Input.is_action_pressed(prefix + "guard"), strike, rival_x
	)

func _step_cpu(delta: float, rival_x: float) -> void:
	var offset := rival_x - second.position.x
	var distance := absf(offset)
	var axis := signf(offset) if distance > 83.0 else 0.0
	var strike := &""
	var jump := false
	cpu_wait -= delta
	cpu_guard = maxf(0.0, cpu_guard - delta)
	if cpu_wait <= 0.0 and second.stance in [&"idle", &"guard"] and second.stun_left <= 0.0:
		cpu_wait = rng.randf_range(0.19, 0.46)
		if distance < 146.0 and Fighter.ATTACKS.has(first.stance) and rng.randf() < 0.62:
			cpu_guard = rng.randf_range(0.19, 0.38)
		elif distance <= 124.0:
			strike = &"punch" if distance < 90.0 and rng.randf() < 0.7 else &"kick"
		elif distance < 215.0 and rng.randf() < 0.16:
			jump = true
	second.step(delta, axis, jump, cpu_guard > 0.0, strike, rival_x)

func _separate(first_was_left: bool) -> void:
	first.position.x = clampf(first.position.x, BOUNDS.x, BOUNDS.y)
	second.position.x = clampf(second.position.x, BOUNDS.x, BOUNDS.y)
	if absf(first.elevation - second.elevation) > 73.0:
		return
	var left := first if first_was_left else second
	var right := second if first_was_left else first
	if right.position.x - left.position.x < BODY_WIDTH:
		var midpoint := (left.position.x + right.position.x) * 0.5
		left.position.x = clampf(midpoint - BODY_WIDTH * 0.5, BOUNDS.x, BOUNDS.y - BODY_WIDTH)
		right.position.x = left.position.x + BODY_WIDTH

func _show_contact(target: Fighter, blocked: bool) -> void:
	spark_time = 0.19
	spark_position = target.position + Vector2(target.face * 17.0, -target.elevation - 68.0)
	spark_color = Color("#91eeff") if blocked else Color("#ffd170")

func _end_round() -> void:
	if first.health > second.health:
		first_wins += 1
		result = first.fighter_name + " gana"
	elif second.health > first.health:
		second_wins += 1
		result = second.fighter_name + " gana"
	else:
		result = "Empate"
	if first_wins == ROUNDS_TO_WIN or second_wins == ROUNDS_TO_WIN:
		phase = Phase.MATCH_END
	else:
		phase = Phase.ROUND_END
		phase_left = 2.2
