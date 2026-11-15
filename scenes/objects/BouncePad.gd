extends Area2D

@export var bounce_velocity: float = -350.0
@export var bounce_velocity_x: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var custom_tex: Texture2D = LevelBuilder.load_sprite_texture("res://assets/sprites/bounce_pad.png")
	if custom_tex != null:
		sprite.texture = custom_tex
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("apply_bounce"):
		body.apply_bounce(bounce_velocity, bounce_velocity_x)
		GameManager.play_sfx("bounce", 0.06)
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.25, 0.65), 0.06)
		tw.tween_property(sprite, "scale", Vector2(0.9, 1.15), 0.08)
		tw.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.08)
