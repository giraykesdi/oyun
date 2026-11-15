extends Area2D

@export var item_id: String = "cable_tape"
@export var auto_pickup_on_touch: bool = false

@onready var sprite: Sprite2D = $Sprite2D

var base_y: float = 0.0
var time_passed: float = 0.0

var tex_spiky: Texture2D = preload("res://assets/sprites/item_spiky_sword.png")
var tex_neon: Texture2D = preload("res://assets/sprites/item_neon_sword.png")
var tex_tape: Texture2D = preload("res://assets/sprites/item_cable_tape.png")
var tex_cell: Texture2D = preload("res://assets/sprites/item_energy_cell.png")
var tex_fish: Texture2D = preload("res://assets/sprites/item_fish.png")

func _ready() -> void:
	base_y = sprite.position.y
	_update_texture()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	time_passed += delta * 3.5
	sprite.position.y = base_y + sin(time_passed) * 2.5

func _update_texture() -> void:
	match item_id:
		"spiky_sword":
			sprite.texture = tex_spiky
		"neon_sword":
			sprite.texture = tex_neon
		"cable_tape":
			sprite.texture = tex_tape
		"fish":
			sprite.texture = tex_fish
			var glow_f := get_node_or_null("GlowRect") as ColorRect
			if glow_f != null:
				glow_f.color = Color(0.35, 0.85, 1.0, 0.25)
		"energy_cell", "heart":
			var heart_tex: Texture2D = LevelBuilder.load_sprite_texture("res://assets/sprites/item_heart.png")
			sprite.texture = heart_tex if heart_tex != null else tex_cell
			var glow := get_node_or_null("GlowRect") as ColorRect
			if glow != null:
				glow.color = Color(1.0, 0.2, 0.45, 0.22)

func get_interaction_prompt() -> String:
	if item_id == "energy_cell" or item_id == "heart":
		return "[E] Kalp Al (+1 Can)"
	var item_info: Dictionary = GameManager.ITEM_DATABASE.get(item_id, {})
	var item_name: String = item_info.get("name", item_id)
	return "[E] Al: " + item_name

func interact(player: Node) -> void:
	_collect(player)

func _collect(player: Node) -> void:
	var added: bool = GameManager.add_item(item_id)
	if not added:
		return
	if player.has_method("unregister_interactable"):
		player.unregister_interactable(self)
	if item_id != "energy_cell" and item_id != "heart":
		GameManager.play_sfx("pickup")
	if item_id == "neon_sword":
		GameManager.select_slot(1)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if auto_pickup_on_touch:
			_collect(body)
		elif body.has_method("register_interactable"):
			body.register_interactable(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
