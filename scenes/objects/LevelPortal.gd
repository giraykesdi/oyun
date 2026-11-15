extends Area2D

@export_file("*.tscn") var next_scene_path: String = "res://scenes/levels/Level2_Labyrinth.tscn"
@export var portal_label: String = "SONRAKİ BÖLÜM"

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if body.is_in_group("player") and next_scene_path != "":
		triggered = true
		if body.has_method("enter_exit_pipe"):
			body.enter_exit_pipe(global_position, next_scene_path)
		else:
			GameManager.call_deferred("set_checkpoint_and_load_level", next_scene_path)
