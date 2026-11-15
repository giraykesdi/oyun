extends CharacterBody2D

signal stun_finished

const SPEED: float = 105.0
const CROUCH_SPEED: float = 65.0
const JUMP_VELOCITY: float = -238.0
const CLIMB_SPEED: float = 92.0
const GRAVITY: float = 680.0
const FALL_DEATH_Y: float = 205.0

@export var spawn_from_pipe: bool = true
@export var pipe_stun_duration: float = 1.25

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ceiling_check: RayCast2D = $CeilingCheck
@onready var sword_pivot: Node2D = $SwordPivot
@onready var weapon_sprite: Sprite2D = $SwordPivot/WeaponSprite
@onready var slash_visual: Polygon2D = $SwordPivot/SlashVisual
@onready var sword_hitbox: Area2D = $SwordPivot/SwordHitbox
@onready var interact_area: Area2D = $InteractArea
@onready var camera: Camera2D = $Camera2D

var facing_dir: int = 1
var is_crouching: bool = false
var is_climbing: bool = false
var is_attacking: bool = false
var falling_from_pipe: bool = false
var entering_pipe: bool = false
var stun_timer: float = 0.0
var stun_anim_time: float = 0.0
var invulnerable_timer: float = 0.0
var coyote_timer: float = 0.0
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var bounced_in_air: bool = false
var bounce_lock_timer: float = 0.0
var cutscene_lock: bool = false
var walk_step_timer: float = 0.0

var climbable_areas: Array[Node] = []
var nearby_interactables: Array[Node] = []

var stun_stars_root: Node2D
var stun_dots: Array[Polygon2D] = []
var speech_panel: PanelContainer
var speech_label: Label
var speech_tween: Tween
var neon_flame_timer: float = 0.0
var neon_flame_wisps: Array[ColorRect] = []

var tex_spiky_sword: Texture2D = preload("res://assets/sprites/item_spiky_sword.png")
var tex_neon_sword: Texture2D = preload("res://assets/sprites/item_neon_sword.png")
var tex_tape: Texture2D = preload("res://assets/sprites/item_cable_tape.png")
var tex_cell: Texture2D = preload("res://assets/sprites/item_energy_cell.png")
var tex_fish: Texture2D = preload("res://assets/sprites/item_fish.png")

func _ready() -> void:
	add_to_group("player")
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.screen_shake_requested.connect(_on_screen_shake)
	_update_equipped_visual()
	slash_visual.visible = false
	sword_hitbox.monitoring = true
	sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
	_create_stun_visuals()
	_create_speech_bubble()
	_create_neon_flame_wisps()

	if spawn_from_pipe:
		falling_from_pipe = true
		velocity = Vector2(0.0, 95.0)
		sprite.scale = Vector2(0.85, 1.15)
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.22)

func _create_stun_visuals() -> void:
	stun_stars_root = Node2D.new()
	stun_stars_root.position = Vector2(0, -14)
	stun_stars_root.visible = false
	add_child(stun_stars_root)

	for i in range(3):
		var star := Polygon2D.new()
		star.polygon = PackedVector2Array([
			Vector2(0, -3), Vector2(1, -1), Vector2(3, 0), Vector2(1, 1),
			Vector2(0, 3), Vector2(-1, 1), Vector2(-3, 0), Vector2(-1, -1)
		])
		star.color = Color(1.0, 0.92, 0.2, 1.0) if i % 2 == 0 else Color(0.2, 0.95, 1.0, 1.0)
		stun_stars_root.add_child(star)
		stun_dots.append(star)

	var stun_lbl := Label.new()
	stun_lbl.position = Vector2(-24, -13)
	stun_lbl.size = Vector2(48, 12)
	stun_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stun_lbl.add_theme_font_size_override("font_size", 6)
	stun_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25, 0.95))
	stun_lbl.text = "SERSEMLEDİ!"
	stun_stars_root.add_child(stun_lbl)

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_dead or entering_pipe or falling_from_pipe or stun_timer > 0.0:
		return

	if event.is_action_pressed("slot_1"):
		GameManager.select_slot(0)
	elif event.is_action_pressed("slot_2"):
		GameManager.select_slot(1)
	elif event.is_action_pressed("slot_3"):
		GameManager.select_slot(2)
	elif event.is_action_pressed("slot_4"):
		GameManager.select_slot(3)
	elif event.is_action_pressed("prev_item"):
		GameManager.cycle_slot(-1)
	elif event.is_action_pressed("next_item"):
		GameManager.cycle_slot(1)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			GameManager.cycle_slot(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			GameManager.cycle_slot(1)

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("attack"):
		var active_item = GameManager.get_active_item()
		if active_item != null and active_item.get("id", "") == "fish":
			GameManager.emit_signal("status_message", "Pandalar bambu sever!")
		elif active_item != null and active_item.get("type", "") == "consumable":
			GameManager.use_active_consumable()
		else:
			_perform_sword_attack()

func _physics_process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO

	if GameManager.is_dead:
		GameManager.stop_walk_step()
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if not is_on_floor():
			velocity.y = min(velocity.y + GRAVITY * delta, 420.0)
		move_and_slide()
		return

	if entering_pipe or cutscene_lock:
		GameManager.stop_walk_step()
		if cutscene_lock and not is_on_floor():
			velocity.y = min(velocity.y + GRAVITY * delta, 420.0)
			velocity.x = 0.0
			move_and_slide()
		return

	# Haritadan aşağı / boşluğa düşme kontrolü -> Anında Ölüm
	if global_position.y > FALL_DEATH_Y:
		hurt_player(GameManager.MAX_HEALTH, global_position, true, "Haritadan Aşağı Düştün!")
		return

	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		sprite.modulate.a = 0.4 if int(invulnerable_timer * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

	# Borudan ilk düşüş ve yere çarpınca sersemleme (Stun) kontrolü
	if falling_from_pipe:
		velocity.x = 0.0
		velocity.y = min(velocity.y + GRAVITY * delta, 420.0)
		move_and_slide()
		sprite.frame = 4
		if is_on_floor():
			falling_from_pipe = false
			stun_timer = pipe_stun_duration
			stun_anim_time = 0.0
			stun_stars_root.visible = true
			weapon_sprite.visible = false
			GameManager.request_screen_shake(3.5, 0.22)
			GameManager.play_sfx("stun")
			GameManager.emit_signal("status_message", "PO Borudan Düştü! Sersemledi...")
		return

	if stun_timer > 0.0:
		stun_timer -= delta
		stun_anim_time += delta * 9.0
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if not is_on_floor():
			velocity.y = min(velocity.y + GRAVITY * delta, 420.0)
		move_and_slide()
		sprite.frame = 7
		sprite.rotation_degrees = sin(stun_anim_time * 2.2) * 2.5
		for i in range(stun_dots.size()):
			var ang: float = stun_anim_time + float(i) * (TAU / 3.0)
			stun_dots[i].position = Vector2(cos(ang) * 9.0, sin(ang) * 3.0)
		if stun_timer <= 0.0:
			sprite.rotation_degrees = 0.0
			stun_stars_root.visible = false
			weapon_sprite.visible = true
			sprite.frame = 0
			stun_finished.emit()
		return

	# Tırmanılabilir kablo/merdiven kontrolü
	_cleanup_invalid_refs()
	var active_cable: Node = _get_active_climbable()
	if active_cable == null:
		is_climbing = false
	elif not is_climbing and (Input.is_action_pressed("move_up") or (Input.is_action_pressed("move_down") and not is_on_floor())):
		is_climbing = true

	# Eğilme (Crouch) kontrolü
	var wants_crouch: bool = Input.is_action_pressed("crouch") and not is_climbing
	if wants_crouch:
		_set_crouch_state(true)
	elif is_crouching and not ceiling_check.is_colliding():
		_set_crouch_state(false)

	# Hareket ve Fizik
	var input_x: float = Input.get_axis("move_left", "move_right")
	if input_x != 0.0:
		facing_dir = 1 if input_x > 0.0 else -1
		sprite.flip_h = (facing_dir < 0)
		sword_pivot.scale.x = float(facing_dir)

	if is_climbing:
		var climb_y: float = Input.get_axis("move_up", "move_down")
		velocity.y = climb_y * CLIMB_SPEED
		velocity.x = input_x * (SPEED * 0.8)
		if active_cable != null and abs(input_x) < 0.1 and not is_on_wall():
			global_position.x = move_toward(global_position.x, active_cable.global_position.x, 45.0 * delta)
		if Input.is_action_just_pressed("jump") and not Input.is_action_pressed("move_up"):
			is_climbing = false
			velocity.y = JUMP_VELOCITY
	else:
		if is_on_floor():
			coyote_timer = 0.1
		else:
			coyote_timer -= delta
			velocity.y = min(velocity.y + GRAVITY * delta, 420.0)

		if Input.is_action_just_pressed("jump") and coyote_timer > 0.0 and not is_crouching:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0.0
			GameManager.play_sfx("jump", 0.05)

		var target_speed: float = CROUCH_SPEED if is_crouching else SPEED
		if bounce_lock_timer > 0.0:
			bounce_lock_timer -= delta
		elif input_x != 0.0:
			velocity.x = move_toward(velocity.x, input_x * target_speed, 900.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)

	move_and_slide()

	if is_climbing:
		bounced_in_air = false
		walk_step_timer = 0.0
		GameManager.stop_walk_step()
	else:
		if bounced_in_air and is_on_floor():
			bounced_in_air = false
			GameManager.play_sfx("bounce_land")

		if is_on_floor() and abs(input_x) > 0.1 and abs(velocity.x) > 15.0:
			walk_step_timer -= delta
			if walk_step_timer <= 0.0:
				GameManager.play_walk_step(0.08)
				if not is_crouching:
					_spawn_run_dust()
				walk_step_timer = 0.22 if is_crouching else 0.15
		else:
			walk_step_timer = 0.0
			GameManager.stop_walk_step()

	_update_sprite_frame(input_x)
	_update_interaction_prompt()
	_update_neon_flame_fx(delta)

func enter_exit_pipe(pipe_global_pos: Vector2, next_scene_path: String) -> void:
	if entering_pipe or GameManager.is_dead:
		return
	entering_pipe = true
	is_climbing = false
	velocity = Vector2.ZERO
	weapon_sprite.visible = false
	slash_visual.visible = false
	stun_stars_root.visible = false
	GameManager.emit_signal("interaction_prompt_changed", "")
	GameManager.emit_signal("status_message", "Boruya Giriliyor... Sonraki Bölüme Geçiliyor!")
	GameManager.request_screen_shake(2.5, 0.25)
	GameManager.play_sfx("pipe")

	var tw := create_tween()
	tw.tween_property(self, "global_position", pipe_global_pos + Vector2(0, -4), 0.16)
	tw.tween_property(self, "global_position", pipe_global_pos + Vector2(0, 10), 0.26)
	tw.parallel().tween_property(sprite, "scale", Vector2(0.25, 0.25), 0.26)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.26)
	await tw.finished
	GameManager.set_checkpoint_and_load_level(next_scene_path)

func _set_crouch_state(crouching: bool) -> void:
	if is_crouching == crouching:
		return
	is_crouching = crouching
	var rect_shape := collision_shape.shape as RectangleShape2D
	if crouching:
		rect_shape.size = Vector2(10.0, 11.0)
		collision_shape.position = Vector2(0.0, 5.5)
	else:
		rect_shape.size = Vector2(10.0, 20.0)
		collision_shape.position = Vector2(0.0, 1.0)

func _spawn_run_dust() -> void:
	if get_parent() == null:
		return
	var dust := ColorRect.new()
	dust.size = Vector2(3, 2)
	dust.color = Color(0.65, 0.85, 1.0, 0.65)
	dust.global_position = global_position + Vector2(-float(facing_dir) * 4.0, 9.0)
	get_parent().add_child(dust)
	var tw := dust.create_tween().set_parallel(true)
	tw.tween_property(dust, "global_position", dust.global_position + Vector2(-float(facing_dir) * 7.0, -4.0), 0.22)
	tw.tween_property(dust, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(dust.queue_free)

func _update_sprite_frame(input_x: float) -> void:
	var t := float(Time.get_ticks_msec()) * 0.001
	if is_climbing:
		weapon_sprite.visible = false
		if abs(velocity.y) > 5.0 or abs(velocity.x) > 5.0:
			var climb_step: int = int(t * 8.0) % 2
			sprite.frame = 5 if climb_step == 0 else 6
			var climb_wave := sin(t * 16.0)
			sprite.position.y = abs(climb_wave) * -1.0
			sprite.rotation_degrees = climb_wave * 4.0
			sprite.scale = Vector2(1.0, 1.0)
		else:
			sprite.frame = 5
			sprite.position.y = 0.0
			sprite.rotation_degrees = 0.0
			sprite.scale = Vector2(1.0, 1.0)
	elif is_crouching:
		sprite.frame = 4
		weapon_sprite.visible = true
		sprite.rotation_degrees = 0.0
		sprite.position.y = 0.0
		sprite.scale = Vector2(1.04, 0.96)
		if abs(input_x) > 0.1:
			sprite.position.y = abs(sin(t * 12.0)) * -0.7
	elif not is_on_floor():
		sprite.frame = 1 if velocity.y < 0.0 else 3
		weapon_sprite.visible = true
		sprite.position.y = 0.0
		sprite.rotation_degrees = clampf(velocity.y * 0.025, -6.0, 6.0) * float(facing_dir)
		if velocity.y < -40.0:
			sprite.scale = Vector2(0.92, 1.08)
		else:
			sprite.scale = Vector2(1.03, 0.97)
	elif abs(input_x) > 0.1 and is_on_floor():
		weapon_sprite.visible = true
		var walk_cycle := [1, 2, 3, 2]
		sprite.frame = walk_cycle[int(t * 11.0) % 4]
		var stride := sin(t * 20.0)
		sprite.position.y = -abs(stride) * 1.5
		sprite.rotation_degrees = float(facing_dir) * 4.0 + stride * 2.5
		sprite.scale = Vector2(1.0 + abs(stride) * 0.04, 1.0 - abs(stride) * 0.04)
		if not is_attacking:
			weapon_sprite.position.y = 1.0 + stride * 1.5
			weapon_sprite.rotation_degrees = stride * 10.0
	else:
		sprite.frame = 0
		weapon_sprite.visible = true
		var breath := sin(t * 3.5)
		sprite.position.y = breath * 0.35
		sprite.rotation_degrees = 0.0
		sprite.scale = Vector2(1.0, 1.0 + breath * 0.02)
		if not is_attacking:
			weapon_sprite.position.y = 1.0 + breath * 0.4
			weapon_sprite.rotation_degrees = 0.0

func _create_neon_flame_wisps() -> void:
	for i in range(4):
		var wisp := ColorRect.new()
		wisp.size = Vector2(2, 2)
		wisp.color = Color(0.25, 0.92, 1.0, 0.9) if i % 2 == 0 else Color(0.45, 0.72, 1.0, 0.85)
		wisp.visible = false
		wisp.z_index = 2
		weapon_sprite.add_child(wisp)
		neon_flame_wisps.append(wisp)

func _update_neon_flame_fx(delta: float) -> void:
	var is_neon_active: bool = (GameManager.get_active_weapon_damage() >= 3) and weapon_sprite.visible and not is_climbing and stun_timer <= 0.0 and not falling_from_pipe
	var t: float = float(Time.get_ticks_msec()) * 0.001
	for i in range(neon_flame_wisps.size()):
		var w: ColorRect = neon_flame_wisps[i]
		w.visible = is_neon_active
		if is_neon_active:
			var phase: float = t * 14.0 + float(i) * 1.7
			w.position = Vector2(sin(phase) * 2.5 - 1.0, -3.0 - float(i) * 2.6 - abs(cos(phase)) * 1.5)
			w.modulate.a = 0.55 + 0.45 * abs(sin(phase * 1.3))
	if not is_neon_active or get_parent() == null:
		return
	neon_flame_timer -= delta
	if neon_flame_timer <= 0.0:
		neon_flame_timer = 0.075
		var ember := ColorRect.new()
		ember.size = Vector2(2, 2)
		ember.color = Color(0.2, 0.92, 1.0, 0.9) if randf() > 0.4 else Color(0.55, 0.85, 1.0, 0.85)
		ember.z_index = 12
		ember.global_position = weapon_sprite.global_position + Vector2(randf_range(-2.0, 3.0) * float(facing_dir), randf_range(-8.0, -2.0))
		get_parent().add_child(ember)
		var tw := ember.create_tween().set_parallel(true)
		tw.tween_property(ember, "global_position", ember.global_position + Vector2(randf_range(-3.0, 3.0), -8.0), 0.24)
		tw.tween_property(ember, "modulate:a", 0.0, 0.24)
		tw.chain().tween_callback(ember.queue_free)

func _perform_sword_attack() -> void:
	if is_attacking:
		return
	is_attacking = true
	var dmg: int = GameManager.get_active_weapon_damage()
	var is_neon: bool = (dmg >= 3)
	GameManager.play_sfx("attack_neon" if is_neon else "attack_spiky", 0.06)

	slash_visual.color = Color(0.1, 0.95, 1.0, 0.92) if is_neon else Color(1.0, 0.82, 0.28, 0.85)
	slash_visual.scale = Vector2(0.75, 0.75)
	slash_visual.visible = true

	# Güzel vuruş animasyonu: hafif geri çekilme -> hızlı savurma -> toparlanma
	weapon_sprite.rotation_degrees = -35.0
	var tw_swing := create_tween()
	tw_swing.tween_property(weapon_sprite, "rotation_degrees", 102.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_swing.parallel().tween_property(slash_visual, "scale", Vector2(1.25, 1.18), 0.09).set_trans(Tween.TRANS_QUAD)
	tw_swing.parallel().tween_property(slash_visual, "modulate:a", 0.0, 0.14)

	# Kılıç savurma kıvılcımları
	if get_parent() != null:
		for s in range(4):
			var spk := ColorRect.new()
			spk.size = Vector2(2, 2)
			spk.color = Color(0.2, 0.95, 1.0, 0.95) if is_neon else Color(1.0, 0.78, 0.25, 0.95)
			spk.z_index = 15
			spk.global_position = global_position + Vector2(float(facing_dir) * 10.0, randf_range(-6.0, 4.0))
			get_parent().add_child(spk)
			var tw_s := spk.create_tween().set_parallel(true)
			tw_s.tween_property(spk, "global_position", spk.global_position + Vector2(float(facing_dir) * randf_range(8.0, 16.0), randf_range(-8.0, 8.0)), 0.18)
			tw_s.tween_property(spk, "modulate:a", 0.0, 0.18)
			tw_s.chain().tween_callback(spk.queue_free)

	var hit_targets: Array = []
	for body in sword_hitbox.get_overlapping_bodies():
		if body.has_method("take_sword_damage") and not hit_targets.has(body):
			hit_targets.append(body)
			body.take_sword_damage(dmg, global_position)
	for area in sword_hitbox.get_overlapping_areas():
		if area.has_method("take_sword_damage") and not hit_targets.has(area):
			hit_targets.append(area)
			area.take_sword_damage(dmg, global_position)

	await get_tree().create_timer(0.14).timeout
	if is_instance_valid(self):
		slash_visual.visible = false
		slash_visual.modulate.a = 1.0
		slash_visual.scale = Vector2(1.0, 1.0)
		var tw_ret := create_tween()
		tw_ret.tween_property(weapon_sprite, "rotation_degrees", 0.0, 0.07)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self):
		is_attacking = false

func _on_sword_hitbox_body_entered(body: Node) -> void:
	if is_attacking and body.has_method("take_sword_damage"):
		var dmg: int = GameManager.get_active_weapon_damage()
		body.take_sword_damage(dmg, global_position)

func apply_bounce(bounce_vel: float = -340.0, bounce_vel_x: float = 0.0) -> void:
	if GameManager.is_dead or entering_pipe:
		return
	is_climbing = false
	falling_from_pipe = false
	stun_timer = 0.0
	stun_stars_root.visible = false
	sprite.rotation_degrees = 0.0
	weapon_sprite.visible = true
	bounced_in_air = true
	velocity.y = bounce_vel
	if abs(bounce_vel_x) > 1.0:
		velocity.x = bounce_vel_x
		bounce_lock_timer = 0.28
		facing_dir = 1 if bounce_vel_x > 0.0 else -1
		sprite.flip_h = (facing_dir < 0)
		sword_pivot.scale.x = float(facing_dir)
	GameManager.request_screen_shake(2.0, 0.1)

func _create_speech_bubble() -> void:
	speech_panel = PanelContainer.new()
	speech_panel.visible = false
	speech_panel.z_index = 40
	speech_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.92)
	style.border_color = Color(0.25, 0.88, 1.0, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	speech_panel.add_theme_stylebox_override("panel", style)
	speech_label = Label.new()
	speech_label.add_theme_font_size_override("font_size", 7)
	speech_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_label.custom_minimum_size = Vector2(130, 0)
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_panel.add_child(speech_label)
	add_child(speech_panel)

func say(text: String, duration: float = 3.2) -> void:
	if not is_instance_valid(speech_panel):
		return
	speech_label.text = text
	speech_panel.reset_size()
	speech_panel.position = Vector2(-speech_panel.size.x * 0.5, -24.0 - speech_panel.size.y)
	speech_panel.visible = true
	speech_panel.modulate.a = 1.0
	GameManager.play_sfx("story_text", 0.08)
	if speech_tween and speech_tween.is_valid():
		speech_tween.kill()
	speech_tween = create_tween()
	speech_tween.tween_interval(max(duration - 0.35, 0.5))
	speech_tween.tween_property(speech_panel, "modulate:a", 0.0, 0.35)
	speech_tween.tween_callback(func():
		if is_instance_valid(speech_panel):
			speech_panel.visible = false
	)

func hurt_player(damage: int, hazard_pos: Vector2 = Vector2.ZERO, instant_kill: bool = false, reason: String = "") -> void:
	if GameManager.is_dead or entering_pipe:
		return
	if instant_kill:
		var kill_reason: String = reason if reason != "" else "Kritik Tehlike!"
		GameManager.take_damage(GameManager.MAX_HEALTH, kill_reason)
		if GameManager.is_dead:
			_apply_death_pose()
		return
	if invulnerable_timer > 0.0:
		return
	invulnerable_timer = 1.0
	var knock_dir: float = sign(global_position.x - hazard_pos.x)
	if knock_dir == 0.0:
		knock_dir = -float(facing_dir)
	velocity = Vector2(knock_dir * 130.0, -150.0)
	var dmg_reason: String = reason if reason != "" else "Tüm Kalplerin Tükendi!"
	GameManager.take_damage(damage, dmg_reason)
	if GameManager.is_dead:
		_apply_death_pose()

func _apply_death_pose() -> void:
	GameManager.stop_walk_step()
	stun_stars_root.visible = false
	weapon_sprite.visible = false
	slash_visual.visible = false
	sprite.rotation_degrees = -90.0
	sprite.modulate = Color(1.0, 0.35, 0.45, 0.9)

func register_climbable(node: Node) -> void:
	if not climbable_areas.has(node):
		climbable_areas.append(node)

func unregister_climbable(node: Node) -> void:
	climbable_areas.erase(node)

func _get_active_climbable() -> Node:
	for c in climbable_areas:
		if is_instance_valid(c) and c.has_method("is_climb_enabled") and c.is_climb_enabled():
			return c
	return null

func register_interactable(node: Node) -> void:
	if not nearby_interactables.has(node):
		nearby_interactables.append(node)

func unregister_interactable(node: Node) -> void:
	nearby_interactables.erase(node)

func _cleanup_invalid_refs() -> void:
	climbable_areas = climbable_areas.filter(func(n): return is_instance_valid(n))
	nearby_interactables = nearby_interactables.filter(func(n): return is_instance_valid(n))

func _update_interaction_prompt() -> void:
	if nearby_interactables.is_empty():
		GameManager.emit_signal("interaction_prompt_changed", "")
		return
	var target = nearby_interactables.back()
	if is_instance_valid(target) and target.has_method("get_interaction_prompt"):
		GameManager.emit_signal("interaction_prompt_changed", target.get_interaction_prompt())
	else:
		GameManager.emit_signal("interaction_prompt_changed", "")

func _try_interact() -> void:
	_cleanup_invalid_refs()
	if nearby_interactables.is_empty():
		var active_item = GameManager.get_active_item()
		if active_item != null and active_item.get("id", "") == "fish":
			GameManager.emit_signal("status_message", "Pandalar bambu sever!")
		return
	var target = nearby_interactables.back()
	if is_instance_valid(target) and target.has_method("interact"):
		target.interact(self)
		_update_interaction_prompt()

func _on_inventory_changed(_slots: Array, _active_idx: int) -> void:
	_update_equipped_visual()

func _update_equipped_visual() -> void:
	var item = GameManager.get_active_item()
	if item == null:
		weapon_sprite.texture = tex_spiky_sword
		weapon_sprite.modulate = Color(1, 1, 1, 0.5)
		return
	weapon_sprite.modulate = Color(1, 1, 1, 1)
	match item.get("id", ""):
		"spiky_sword":
			weapon_sprite.texture = tex_spiky_sword
		"neon_sword":
			weapon_sprite.texture = tex_neon_sword
		"cable_tape":
			weapon_sprite.texture = tex_tape
		"energy_cell":
			weapon_sprite.texture = tex_cell
		"fish":
			weapon_sprite.texture = tex_fish

func _on_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration
