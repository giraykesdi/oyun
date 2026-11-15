extends CharacterBody2D

@export var max_hp: int = 6
@export var patrol_distance: float = 36.0
@export var move_speed: float = 48.0
@export_enum("slime", "frog") var mob_type: String = "slime"

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_area: Area2D = $HitboxArea
@onready var hp_bar_fill: ColorRect = $HPBarBG/HPBarFill

var hp: int = 6
var start_x: float = 0.0
var dir: int = 1
var knockback_x: float = 0.0
var anim_t: float = 0.0
var frog_state_timer: float = 0.4
var frog_crouching: bool = false

func _ready() -> void:
	hp = max_hp
	start_x = global_position.x
	hitbox_area.body_entered.connect(_on_body_entered)
	_update_hp_bar()
	_setup_mob_visual()

func _setup_mob_visual() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if mob_type == "frog":
		sprite.texture = preload("res://assets/sprites/enemy_frog_sheet.png")
		sprite.hframes = 4
		sprite.frame = 0
		sprite.position = Vector2(0, -4)
	else:
		sprite.texture = preload("res://assets/sprites/enemy_slime.png")
		sprite.hframes = 1
		sprite.frame = 0
		sprite.position = Vector2(0, 1)

func _physics_process(delta: float) -> void:
	anim_t += delta * 12.0
	if not is_on_floor():
		velocity.y += 650.0 * delta

	if abs(knockback_x) > 5.0:
		velocity.x = knockback_x
		knockback_x = move_toward(knockback_x, 0.0, 520.0 * delta)
	elif mob_type == "frog":
		_process_frog_ai(delta)
	else:
		velocity.x = dir * move_speed
		if global_position.x > start_x + patrol_distance:
			dir = -1
		elif global_position.x < start_x - patrol_distance:
			dir = 1
		if is_on_wall():
			dir *= -1

	if mob_type == "frog":
		# Kurbağa görseli sola bakıyor -> sağa giderken flip_h = true
		sprite.flip_h = (dir > 0)
		if not is_on_floor():
			sprite.frame = 3 if velocity.y < -20.0 else 2
		elif frog_crouching:
			sprite.frame = 1
		else:
			sprite.frame = 0
	else:
		# Slime ezilip zıplayan sevimli animasyon
		sprite.flip_h = (dir < 0)
		var hop: float = abs(sin(anim_t * 0.48))
		sprite.scale = Vector2(1.12 - hop * 0.22, 0.86 + hop * 0.26)
		sprite.position.y = 1.5 - hop * 3.8

	move_and_slide()

func _process_frog_ai(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		frog_state_timer -= delta
		if not frog_crouching and frog_state_timer <= 0.16:
			frog_crouching = true
		if frog_state_timer <= 0.0:
			frog_crouching = false
			if global_position.x > start_x + patrol_distance:
				dir = -1
			elif global_position.x < start_x - patrol_distance:
				dir = 1
			velocity.y = -175.0
			velocity.x = float(dir) * move_speed * 1.45
			frog_state_timer = randf_range(0.55, 0.85)
			GameManager.play_sfx("frog_croak", 0.08)
	else:
		velocity.x = float(dir) * move_speed * 1.45
		if is_on_wall():
			dir *= -1

func take_sword_damage(dmg: int, attacker_pos: Vector2) -> void:
	# 1. Kılıç (1 Hasar) -> 6 vuruşta öldürür
	# 2. Kılıç (3 Hasar) -> 2 vuruşta öldürür
	hp -= dmg
	_update_hp_bar()
	var push_dir: float = sign(global_position.x - attacker_pos.x)
	if push_dir == 0.0:
		push_dir = 1.0
	knockback_x = push_dir * 110.0
	velocity.y = -75.0
	sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	GameManager.trigger_hitstop(0.1, 0.03)
	GameManager.request_screen_shake(2.0, 0.1)

	if hp <= 0:
		GameManager.play_sfx("enemy_die")
		queue_free()
	else:
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self):
			sprite.modulate = Color(1, 1, 1, 1)

func _update_hp_bar() -> void:
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	hp_bar_fill.size.x = 16.0 * ratio

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("hurt_player"):
		if mob_type == "frog":
			GameManager.play_sfx("frog_bite")
		body.hurt_player(1, global_position, false)
