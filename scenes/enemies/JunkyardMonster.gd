extends CharacterBody2D

@export var max_hp: int = 3
@export var patrol_distance: float = 48.0
@export var move_speed: float = 42.0
@export var drops_neon_sword: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_area: Area2D = $HitboxArea
@onready var hp_bar_fill: ColorRect = $HPBarBG/HPBarFill

var hp: int = 3
var start_x: float = 0.0
var dir: int = -1
var knockback_x: float = 0.0
var anim_t: float = 0.0
var antenna_tip: ColorRect
var eyes_node: Node2D
var pickup_scene: PackedScene = preload("res://scenes/objects/PickupItem.tscn")

func _ready() -> void:
	hp = max_hp
	start_x = global_position.x
	hitbox_area.body_entered.connect(_on_body_entered)
	_update_hp_bar()
	_build_details()

func _build_details() -> void:
	# Tepeden çıkan kıvılcımlı hurda anteni
	var stem := ColorRect.new()
	stem.position = Vector2(-1, -16)
	stem.size = Vector2(2, 6)
	stem.color = Color(0.55, 0.62, 0.72, 1.0)
	sprite.add_child(stem)

	antenna_tip = ColorRect.new()
	antenna_tip.position = Vector2(-2, -19)
	antenna_tip.size = Vector2(4, 3)
	antenna_tip.color = Color(1.0, 0.85, 0.15, 1.0)
	sprite.add_child(antenna_tip)

	# Metal hurda omuz plakaları ve parlayan kırmızı gözler
	var plate := ColorRect.new()
	plate.position = Vector2(-9, -4)
	plate.size = Vector2(18, 4)
	plate.color = Color(0.28, 0.34, 0.45, 0.9)
	sprite.add_child(plate)

	eyes_node = Node2D.new()
	sprite.add_child(eyes_node)
	for ex in [-4.0, 2.0]:
		var eye := ColorRect.new()
		eye.position = Vector2(ex, -7)
		eye.size = Vector2(3, 2)
		eye.color = Color(1.0, 0.2, 0.35, 1.0)
		eyes_node.add_child(eye)

func _physics_process(delta: float) -> void:
	anim_t += delta * 10.0
	if not is_on_floor():
		velocity.y += 650.0 * delta

	if abs(knockback_x) > 5.0:
		velocity.x = knockback_x
		knockback_x = move_toward(knockback_x, 0.0, 500.0 * delta)
	else:
		velocity.x = dir * move_speed
		if global_position.x > start_x + patrol_distance:
			dir = -1
		elif global_position.x < start_x - patrol_distance:
			dir = 1
		if is_on_wall():
			dir *= -1

	sprite.flip_h = (dir > 0)
	sprite.position.y = abs(sin(anim_t)) * -1.8
	sprite.rotation_degrees = sin(anim_t) * 4.5
	if antenna_tip != null:
		antenna_tip.color = Color(1.0, 0.95, 0.3, 1.0) if int(anim_t * 2.0) % 2 == 0 else Color(1.0, 0.35, 0.1, 1.0)
	move_and_slide()

func take_sword_damage(dmg: int, attacker_pos: Vector2) -> void:
	hp -= dmg
	_update_hp_bar()
	var push_dir: float = sign(global_position.x - attacker_pos.x)
	if push_dir == 0.0:
		push_dir = 1.0
	knockback_x = push_dir * 120.0
	velocity.y = -90.0
	sprite.modulate = Color(2.0, 0.4, 0.4, 1.0)
	GameManager.trigger_hitstop(0.1, 0.04)
	GameManager.request_screen_shake(2.5, 0.12)

	if hp <= 0:
		_die()
	else:
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(self):
			sprite.modulate = Color(1, 1, 1, 1)

func _update_hp_bar() -> void:
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	hp_bar_fill.size.x = 20.0 * ratio

func _die() -> void:
	GameManager.play_sfx("enemy_die")
	if drops_neon_sword and get_parent() != null:
		var drop = pickup_scene.instantiate()
		drop.item_id = "neon_sword"
		drop.global_position = global_position + Vector2(0, -4)
		get_parent().call_deferred("add_child", drop)
		GameManager.emit_signal("status_message", "Canavar Yenildi! İçinden NEON GÜÇ KILICI Düştü [E ile Al]")
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("hurt_player"):
		body.hurt_player(1, global_position, false)
