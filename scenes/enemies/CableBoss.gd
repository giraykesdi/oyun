extends Area2D

@export var chase_speed: float = 75.0
@export var stop_x: float = 3420.0
@export var start_delay: float = 1.35

@onready var whip1: ColorRect = $Whip1
@onready var whip2: ColorRect = $Whip2
@onready var whip3: ColorRect = $Whip3
@onready var sprite: Sprite2D = $Sprite2D
@onready var dark_aura: ColorRect = $DarkAura

var time_acc: float = 0.0
var delay_timer: float = 0.0
var active: bool = true
var is_dying: bool = false

var front_cables: Array[Dictionary] = []
var back_cables: Array[Dictionary] = []
var eye_left: ColorRect
var eye_right: ColorRect
var power_core: Polygon2D

func _ready() -> void:
	delay_timer = start_delay
	body_entered.connect(_on_body_entered)
	_build_cable_details()

func _build_cable_details() -> void:
	# Arka gövdeden sarkan kalın kablo demetleri
	var back_configs := [
		{"y": -26.0, "len": 44.0, "color": Color(0.0, 0.85, 1.0, 0.9), "phase": 0.0},
		{"y": -8.0,  "len": 52.0, "color": Color(1.0, 0.15, 0.55, 0.9), "phase": 1.2},
		{"y": 10.0,  "len": 48.0, "color": Color(1.0, 0.82, 0.15, 0.9), "phase": 2.4},
		{"y": 26.0,  "len": 40.0, "color": Color(0.2, 1.0, 0.6, 0.9), "phase": 3.5},
	]
	for cfg in back_configs:
		var outer := Line2D.new()
		outer.width = 4.5
		outer.default_color = Color(0.08, 0.09, 0.14, 1.0)
		outer.z_index = -1
		add_child(outer)

		var inner := Line2D.new()
		inner.width = 1.8
		inner.default_color = cfg["color"]
		inner.z_index = -1
		add_child(inner)

		back_cables.append({
			"outer": outer,
			"inner": inner,
			"base_y": cfg["y"],
			"len": cfg["len"],
			"phase": cfg["phase"]
		})

	# Öne uzanan kıvrımlı mekanik kablo kolları (6 adet)
	var front_configs := [
		{"y": -28.0, "len": 38.0, "color": Color(1.0, 0.18, 0.45, 1.0), "phase": 0.3},
		{"y": -16.0, "len": 46.0, "color": Color(0.0, 0.95, 1.0, 1.0), "phase": 1.1},
		{"y": -4.0,  "len": 50.0, "color": Color(1.0, 0.85, 0.15, 1.0), "phase": 2.0},
		{"y": 8.0,   "len": 45.0, "color": Color(0.0, 0.95, 1.0, 1.0), "phase": 2.9},
		{"y": 20.0,  "len": 40.0, "color": Color(1.0, 0.18, 0.45, 1.0), "phase": 3.8},
		{"y": 30.0,  "len": 34.0, "color": Color(0.3, 1.0, 0.65, 1.0), "phase": 4.7},
	]
	for cfg in front_configs:
		var outer := Line2D.new()
		outer.width = 4.0
		outer.default_color = Color(0.1, 0.12, 0.18, 1.0)
		add_child(outer)

		var inner := Line2D.new()
		inner.width = 1.6
		inner.default_color = cfg["color"]
		add_child(inner)

		var tip := ColorRect.new()
		tip.size = Vector2(4, 4)
		tip.color = Color(1.0, 0.95, 0.5, 1.0)
		add_child(tip)

		front_cables.append({
			"outer": outer,
			"inner": inner,
			"tip": tip,
			"base_y": cfg["y"],
			"len": cfg["len"],
			"phase": cfg["phase"]
		})

	# Parlayan Dijital Çekirdek ve Kızgın Gözler
	power_core = Polygon2D.new()
	power_core.position = Vector2(2, 4)
	power_core.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)
	])
	power_core.color = Color(1.0, 0.2, 0.5, 0.95)
	add_child(power_core)

	eye_left = ColorRect.new()
	eye_left.position = Vector2(-2, -16)
	eye_left.size = Vector2(5, 3)
	eye_left.color = Color(1.0, 0.15, 0.25, 1.0)
	add_child(eye_left)

	eye_right = ColorRect.new()
	eye_right.position = Vector2(8, -16)
	eye_right.size = Vector2(5, 3)
	eye_right.color = Color(1.0, 0.15, 0.25, 1.0)
	add_child(eye_right)

func _update_cables(speed_mult: float = 1.0) -> void:
	for c in back_cables:
		var pts := PackedVector2Array()
		var base_y: float = c["base_y"]
		var total_len: float = c["len"]
		var ph: float = c["phase"]
		for s in range(5):
			var t := float(s) / 4.0
			var px := -14.0 - t * total_len
			var py := base_y + sin(time_acc * speed_mult + ph + t * 3.5) * (4.0 + t * 6.0)
			pts.append(Vector2(px, py))
		c["outer"].points = pts
		c["inner"].points = pts

	for c in front_cables:
		var pts := PackedVector2Array()
		var base_y: float = c["base_y"]
		var total_len: float = c["len"]
		var ph: float = c["phase"]
		var last_pt := Vector2.ZERO
		for s in range(5):
			var t := float(s) / 4.0
			var px := 14.0 + t * total_len
			var py := base_y + cos(time_acc * speed_mult * 1.1 + ph + t * 3.8) * (3.0 + t * 7.5)
			last_pt = Vector2(px, py)
			pts.append(last_pt)
		c["outer"].points = pts
		c["inner"].points = pts
		c["tip"].position = last_pt - Vector2(2, 2)

func _physics_process(delta: float) -> void:
	if is_dying:
		time_acc += delta * 18.0
		_update_cables(1.8)
		whip1.rotation_degrees = sin(time_acc) * 35.0
		whip2.rotation_degrees = cos(time_acc * 1.4) * 40.0
		whip3.rotation_degrees = sin(time_acc * 0.9) * 32.0
		return

	if not active or GameManager.is_dead:
		time_acc += delta * 4.5
		_update_cables(0.8)
		return

	time_acc += delta * 6.5
	_update_cables(1.0)

	if power_core != null:
		var pulse := 0.85 + 0.2 * sin(time_acc * 1.8)
		power_core.scale = Vector2(pulse, pulse)

	# Sallanan kabloların animasyonu
	whip1.rotation_degrees = sin(time_acc) * 18.0
	whip2.rotation_degrees = cos(time_acc * 1.3) * 22.0
	whip3.rotation_degrees = sin(time_acc * 0.8 + 1.5) * 15.0

	if delay_timer > 0.0:
		delay_timer -= delta
		return

	if global_position.x < stop_x:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var current_speed: float = chase_speed
		if player != null:
			var dist_x: float = player.global_position.x - global_position.x
			if dist_x > 220.0:
				current_speed = chase_speed * 1.38
			elif dist_x > 150.0:
				current_speed = chase_speed * 1.15
			global_position.y = move_toward(global_position.y, player.global_position.y - 10.0, 48.0 * delta)
		global_position.x += current_speed * delta

func _on_body_entered(body: Node) -> void:
	if not active or is_dying:
		return
	if body.is_in_group("player") and body.has_method("hurt_player"):
		body.hurt_player(3, global_position, true, "Kablo Boss'u Seni Yakaladı!")

func _spawn_spark_burst(count: int = 12) -> void:
	for i in range(count):
		var spark := ColorRect.new()
		spark.size = Vector2(3, 3)
		var colors := [Color(1.0, 0.92, 0.2, 1.0), Color(0.0, 0.95, 1.0, 1.0), Color(1.0, 0.2, 0.55, 1.0)]
		spark.color = colors[i % colors.size()]
		spark.position = Vector2(randf_range(-16, 20), randf_range(-28, 28))
		add_child(spark)
		var dir := Vector2(randf_range(-55, 65), randf_range(-75, 25))
		var tw := create_tween().set_parallel(true)
		tw.tween_property(spark, "position", spark.position + dir, randf_range(0.35, 0.65)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "modulate:a", 0.0, 0.6)
		tw.chain().tween_callback(spark.queue_free)

func play_death_cinematic() -> void:
	active = false
	is_dying = true
	monitoring = false
	monitorable = false

	# Kısa devre ve kıvılcım patlamaları
	for burst in range(4):
		if not is_instance_valid(self):
			return
		_spawn_spark_burst(14)
		GameManager.request_screen_shake(4.0, 0.18)
		GameManager.play_sfx("attack_neon" if burst % 2 == 0 else "stun", 0.15)
		sprite.modulate = Color(2.2, 2.2, 2.2, 1.0) if burst % 2 == 0 else Color(1.0, 0.25, 0.4, 1.0)
		eye_left.color = Color(1.0, 1.0, 1.0, 1.0) if burst % 2 == 0 else Color(0.15, 0.05, 0.1, 1.0)
		eye_right.color = eye_left.color
		await get_tree().create_timer(0.24).timeout

	# Son büyük patlama ve yere çöküş
	_spawn_spark_burst(24)
	GameManager.request_screen_shake(6.0, 0.35)
	GameManager.play_sfx("death")
	eye_left.color = Color(0.1, 0.1, 0.14, 1.0)
	eye_right.color = Color(0.1, 0.1, 0.14, 1.0)
	power_core.color = Color(0.1, 0.1, 0.15, 0.8)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", position.y + 28.0, 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", -22.0, 0.65)
	tw.tween_property(sprite, "modulate", Color(0.18, 0.18, 0.22, 0.0), 0.9)
	tw.tween_property(dark_aura, "modulate:a", 0.0, 0.8)
	tw.tween_property(self, "modulate:a", 0.0, 0.95)
	await tw.finished
	is_dying = false
	queue_free()
