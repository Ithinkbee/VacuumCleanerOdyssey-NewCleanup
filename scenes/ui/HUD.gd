extends CanvasLayer

@onready var heart_container = $HealthUI/HBoxContainer
@onready var pickup_label = $PickupLabel
@onready var active_icon = $ActiveSlot/Icon
@onready var active_cooldown_bar = $ActiveSlot/CooldownBar
@onready var active_name_label = $ActiveSlot/NameLabel

var texture_full = preload("res://assets/health.png")
var texture_half = preload("res://assets/health_half.png")
var texture_empty = preload("res://assets/health_empty.png")

@onready var minimap = $MinimapContainer/Minimap
@onready var desc_popup = $DescriptionPopup
@onready var desc_name = $DescriptionPopup/MarginContainer/VBoxContainer/NameLabel
@onready var desc_text = $DescriptionPopup/MarginContainer/VBoxContainer/DescLabel
@onready var restart_overlay = $RestartOverlay

@onready var rage_bar = $RageBar
@onready var active_ready_sound = $ActiveReadySound
@onready var rage_ready_sound = $RageReadySound
@onready var rage_activate_sound = $RageActivateSound
@onready var rage_end_sound = $RageEndSound

func _ready():
	pickup_label.visible = false
	active_icon.visible = false
	active_cooldown_bar.visible = false
	active_name_label.visible = false
	desc_popup.visible = false
	restart_overlay.modulate.a = 0.0
	rage_bar.max_value = 100.0
	rage_bar.value = 0.0

func show_artifact_description(item_name: String, description: String):
	desc_name.text = item_name
	desc_text.text = description
	desc_popup.visible = true

func hide_artifact_description():
	desc_popup.visible = false

func update_health(current_hp: int, max_hp: int):
	for child in heart_container.get_children():
		child.queue_free()

	var total_heart_slots = max_hp / 2

	for i in range(total_heart_slots):
		var heart = TextureRect.new()
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var hp_at_this_slot = current_hp - (i * 2)
		if hp_at_this_slot >= 2:
			heart.texture = texture_full
		elif hp_at_this_slot == 1:
			heart.texture = texture_half
		else:
			heart.texture = texture_empty

		heart_container.add_child(heart)

func update_minimap():
	if is_instance_valid(minimap):
		minimap.queue_redraw()

func show_artifact_pickup(item_name: String):
	pickup_label.text = item_name
	pickup_label.visible = true
	await get_tree().create_timer(3.0).timeout
	# Проверяем, что метка ещё существует (игрок мог умереть)
	if is_instance_valid(pickup_label):
		pickup_label.visible = false

func set_active_artifact(data: Dictionary):
	active_icon.self_modulate = data.get("color", Color.WHITE)
	active_icon.visible = true
	active_name_label.text = data["name"]
	active_name_label.visible = true
	active_cooldown_bar.visible = true
	var cooldown = data.get("effect", {}).get("cooldown", 1.0)
	active_cooldown_bar.max_value = cooldown
	active_cooldown_bar.value = cooldown

var _was_on_cooldown: bool = false

func update_active_cooldown(remaining: float, total: float):
	if not is_instance_valid(active_cooldown_bar):
		return

	active_cooldown_bar.max_value = total
	active_cooldown_bar.value = total - remaining

	if remaining <= 0.0 and _was_on_cooldown:
		_was_on_cooldown = false
		if is_instance_valid(active_ready_sound):
			active_ready_sound.play()
	elif remaining > 0.0:
		_was_on_cooldown = true

func on_rage_ready():
	if is_instance_valid(rage_ready_sound):
		rage_ready_sound.play()
	# Подсвечиваем шкалу жёлтым когда заполнена
	rage_bar.self_modulate = Color(1.0, 0.9, 0.2)

func on_rage_activated():
	if is_instance_valid(rage_activate_sound):
		rage_activate_sound.play()
	rage_bar.self_modulate = Color(1.0, 0.3, 0.3)

func on_rage_ended():
	if is_instance_valid(rage_end_sound):
		rage_end_sound.play()

func update_rage(current_rage: float, max_rage: float):
	if not is_instance_valid(rage_bar):
		return
	rage_bar.max_value = max_rage
	rage_bar.value = current_rage
	# Возвращаем обычный цвет если шкала не полная
	if current_rage < max_rage:
		rage_bar.self_modulate = Color.WHITE

func set_restart_overlay(value: float):
	restart_overlay.modulate.a = value
