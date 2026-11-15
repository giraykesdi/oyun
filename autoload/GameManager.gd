extends Node

signal health_changed(current_hp: int, max_hp: int)
signal inventory_changed(slots: Array, active_index: int)
signal interaction_prompt_changed(prompt_text: String)
signal status_message(message: String)
signal screen_shake_requested(intensity: float, duration: float)
signal crt_toggled(enabled: bool)
signal player_died(reason: String)
signal audio_settings_changed(music_vol: float, sfx_vol: float)

const MAX_HEALTH: int = 3
var current_health: int = 3
var checkpoint_scene: String = "res://scenes/levels/Level1_Junkyard.tscn"
var crt_enabled: bool = true
var is_dead: bool = false
var music_volume: float = 0.5
var sfx_volume: float = 0.5

# 4-Slot Hızlı Envanter Yapısı
var slots: Array = [null, null, null, null]
var active_slot: int = 0

# Oyun içi eşya veritabanı
const ITEM_DATABASE: Dictionary = {
	"spiky_sword": {
		"id": "spiky_sword",
		"name": "Dikensi Küçük Kılıç",
		"type": "weapon",
		"damage": 1,
		"slot_index": 0,
		"icon": "res://assets/sprites/item_spiky_sword.png"
	},
	"neon_sword": {
		"id": "neon_sword",
		"name": "Neon Güç Kılıcı",
		"type": "weapon",
		"damage": 3,
		"slot_index": 1,
		"icon": "res://assets/sprites/item_neon_sword.png"
	},
	"cable_tape": {
		"id": "cable_tape",
		"name": "İzole Kablo Bandı",
		"type": "tool",
		"damage": 0,
		"slot_index": 2,
		"icon": "res://assets/sprites/item_cable_tape.png"
	},
	"energy_cell": {
		"id": "energy_cell",
		"name": "Kalp (+1 Can)",
		"type": "consumable",
		"damage": 0,
		"slot_index": 3,
		"count": 1,
		"icon": "res://assets/sprites/item_energy_cell.png"
	},
	"fish": {
		"id": "fish",
		"name": "Siber Balık",
		"type": "quest",
		"damage": 0,
		"slot_index": 3,
		"icon": "res://assets/sprites/item_fish.png"
	}
}

const MusicManagerScript = preload("res://autoload/MusicManager.gd")
var _audio: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	_audio = MusicManagerScript.new()
	add_child(_audio)
	_audio.set_music_volume(music_volume)
	_audio.set_sfx_volume(sfx_volume)
	reset_for_new_game()

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	if _audio != null:
		_audio.set_music_volume(music_volume)
	emit_signal("audio_settings_changed", music_volume, sfx_volume)

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	if _audio != null:
		_audio.set_sfx_volume(sfx_volume)
	emit_signal("audio_settings_changed", music_volume, sfx_volume)

func play_music(role: String) -> void:
	if _audio != null:
		_audio.play_music(role)

func stop_music() -> void:
	if _audio != null:
		_audio.stop_music()

func play_victory() -> void:
	if _audio != null:
		_audio.play_victory()

func play_sfx(role: String, pitch_variation: float = 0.0) -> void:
	if _audio != null:
		_audio.play_sfx(role, pitch_variation)

func play_walk_step(pitch_variation: float = 0.08) -> void:
	if _audio != null:
		_audio.play_walk_step(pitch_variation)

func stop_walk_step() -> void:
	if _audio != null:
		_audio.stop_walk_step()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_crt"):
		crt_enabled = !crt_enabled
		emit_signal("crt_toggled", crt_enabled)
		emit_signal("status_message", "CRT Filtresi: " + ("AÇIK" if crt_enabled else "KAPALI"))

func _setup_inputs() -> void:
	_clear_and_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_clear_and_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_clear_and_bind_keys("move_up", [KEY_W, KEY_UP])
	_clear_and_bind_keys("move_down", [KEY_S, KEY_DOWN])
	_clear_and_bind_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_clear_and_bind_keys("crouch", [KEY_S, KEY_CTRL, KEY_DOWN])
	_clear_and_bind_keys("interact", [KEY_E])
	# Saldırı tuşu: Mouse Sol Tık ve Q tuşu
	_clear_and_bind_keys("attack", [KEY_Q])
	_bind_mouse("attack", MOUSE_BUTTON_LEFT)
	_clear_and_bind_keys("slot_1", [KEY_1])
	_clear_and_bind_keys("slot_2", [KEY_2])
	_clear_and_bind_keys("slot_3", [KEY_3])
	_clear_and_bind_keys("slot_4", [KEY_4])
	_clear_and_bind_keys("prev_item", [KEY_Z])
	_clear_and_bind_keys("next_item", [KEY_TAB])
	_clear_and_bind_keys("toggle_crt", [KEY_F1])
	_clear_and_bind_keys("toggle_help", [KEY_H])

func _clear_and_bind_keys(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		InputMap.action_erase_events(action_name)
	else:
		InputMap.add_action(action_name)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not InputMap.action_has_event(action_name, ev):
			InputMap.action_add_event(action_name, ev)

func _bind_mouse(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	if not InputMap.action_has_event(action_name, ev):
		InputMap.action_add_event(action_name, ev)

func reset_for_new_game() -> void:
	is_dead = false
	Engine.time_scale = 1.0
	current_health = MAX_HEALTH
	slots = [null, null, null, null]
	# Oyuncu 1. Bölüme elinde Dikensi Küçük Kılıç ile başlar
	add_item("spiky_sword")
	select_slot(0)
	emit_signal("health_changed", current_health, MAX_HEALTH)
	emit_signal("inventory_changed", slots, active_slot)

func add_item(item_id: String) -> bool:
	if item_id == "energy_cell" or item_id == "heart":
		if current_health < MAX_HEALTH:
			heal(1)
			emit_signal("status_message", "+1 Kalp Yenilendi!")
			return true
		emit_signal("status_message", "Canın zaten dolu (3/3)!")
		return false
	if not ITEM_DATABASE.has(item_id):
		return false
	var template: Dictionary = ITEM_DATABASE[item_id].duplicate(true)
	var idx: int = template.get("slot_index", 0)
	slots[idx] = template
	emit_signal("inventory_changed", slots, active_slot)
	emit_signal("status_message", "Eşya Alındı: " + template["name"])
	return true

func has_item(item_id: String) -> bool:
	for s in slots:
		if s != null and s.get("id", "") == item_id:
			return true
	return false

func consume_item(item_id: String) -> bool:
	for i in range(slots.size()):
		if slots[i] != null and slots[i].get("id", "") == item_id:
			if slots[i].has("count") and slots[i]["count"] > 1:
				slots[i]["count"] -= 1
			else:
				slots[i] = null
			emit_signal("inventory_changed", slots, active_slot)
			return true
	return false

func select_slot(index: int) -> void:
	active_slot = clampi(index, 0, 3)
	emit_signal("inventory_changed", slots, active_slot)
	var item = get_active_item()
	if item != null:
		emit_signal("status_message", "Seçili: " + item["name"])

func cycle_slot(direction: int) -> void:
	active_slot = wrapi(active_slot + direction, 0, 4)
	select_slot(active_slot)

func get_active_item() -> Variant:
	return slots[active_slot]

func get_active_weapon_damage() -> int:
	var item = get_active_item()
	if item != null and item.get("type", "") == "weapon":
		return int(item.get("damage", 1))
	if slots[active_slot] == null or slots[active_slot].get("type", "") != "weapon":
		if slots[1] != null:
			return int(slots[1].get("damage", 3))
		elif slots[0] != null:
			return int(slots[0].get("damage", 1))
	return 1

func use_active_consumable() -> bool:
	var item = get_active_item()
	if item != null and item.get("type", "") == "consumable":
		if current_health < MAX_HEALTH:
			heal(1)
			consume_item(item["id"])
			emit_signal("status_message", "Kalp Kullanıldı (+1 Can)")
			return true
		else:
			emit_signal("status_message", "Kalpler zaten dolu (3/3)!")
	return false

func take_damage(amount: int, reason: String = "Tüm Kalpler Tükendi!") -> void:
	if is_dead:
		return
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, MAX_HEALTH)
	trigger_hitstop(0.08, 0.07)
	request_screen_shake(4.0, 0.22)
	if current_health <= 0:
		is_dead = true
		Engine.time_scale = 1.0
		play_sfx("death")
		emit_signal("status_message", "ÖLDÜN! " + reason)
		emit_signal("player_died", reason)
	else:
		play_sfx("hurt", 0.08)

func heal(amount: int) -> void:
	if is_dead:
		return
	play_sfx("heart")
	current_health = min(MAX_HEALTH, current_health + amount)
	emit_signal("health_changed", current_health, MAX_HEALTH)

func set_checkpoint_and_load_level(scene_path: String) -> void:
	get_tree().paused = false
	is_dead = false
	Engine.time_scale = 1.0
	checkpoint_scene = scene_path
	current_health = MAX_HEALTH
	emit_signal("health_changed", current_health, MAX_HEALTH)
	get_tree().change_scene_to_file(scene_path)

func respawn_at_checkpoint() -> void:
	get_tree().paused = false
	is_dead = false
	Engine.time_scale = 1.0
	current_health = MAX_HEALTH
	# Ölünce kılıçlar dışındaki tüm eşyaları sıfırla
	for i in range(slots.size()):
		if slots[i] != null and slots[i].get("type", "") != "weapon":
			slots[i] = null
	if slots[active_slot] == null:
		active_slot = 1 if slots[1] != null else 0
	emit_signal("inventory_changed", slots, active_slot)
	emit_signal("health_changed", current_health, MAX_HEALTH)
	var target: String = checkpoint_scene if checkpoint_scene != "" else "res://scenes/levels/Level1_Junkyard.tscn"
	var err: Error = get_tree().change_scene_to_file(target)
	if err != OK:
		get_tree().change_scene_to_file("res://scenes/levels/Level1_Junkyard.tscn")

func go_to_main_menu() -> void:
	get_tree().paused = false
	reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func request_screen_shake(intensity: float = 3.0, duration: float = 0.18) -> void:
	emit_signal("screen_shake_requested", intensity, duration)

func trigger_hitstop(time_scale: float = 0.1, duration: float = 0.05) -> void:
	if is_dead:
		Engine.time_scale = 1.0
		return
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
