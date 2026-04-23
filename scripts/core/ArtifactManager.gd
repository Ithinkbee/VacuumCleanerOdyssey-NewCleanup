extends Node

# Типы эффектов:
# "stat"    — изменяет числовое поле игрока (speed, damage и т.д.)
# "bullet"  — изменяет поведение пуль (флаги и параметры)
# "active"  — активная способность, вызываемая по кнопке
# "visual"  — меняет внешность игрока / пуль

var registry: Dictionary = {
	
	# ── ПАССИВНЫЕ СТАТЫ ─────────────────────────────────────────
	"swift_boots": {
		"name": "Быстрые ботинки",
		"description": "Скорость передвижения значительно возрастает.",
		"type": "stat",
		"effect": {"stat": "speed", "value": 80.0},
		"color": Color(0.4, 0.8, 1.0)
	},
	"iron_heart": {
		"name": "Железное сердце",
		"description": "Максимальное здоровье увеличивается на 2.",
		"type": "stat",
		"effect": {"stat": "max_hp", "value": 2},
		"color": Color(1.0, 0.3, 0.3)
	},
	"sharp_tears": {
		"name": "Острые слёзы",
		"description": "Урон от пуль значительно увеличивается.",
		"type": "stat",
		"effect": {"stat": "damage", "value": 4},
		"color": Color(1.0, 0.6, 0.0)
	},
	"rapid_fire": {
		"name": "Скорострел",
		"description": "Задержка между выстрелами уменьшается.",
		"type": "stat",
		"effect": {"stat": "shoot_delay", "value": -0.15},
		"color": Color(0.6, 1.0, 0.4)
	},
	"long_barrel": {
	"name": "Длинный ствол",
	"description": "Пули летят значительно дальше.",
	"type": "bullet",
	"effect": {"flag": "range", "value": 250.0},
	"color": Color(0.7, 0.9, 0.7)
	},
	"rage_amp": {
		"name": "Красная тряпка",
		"description": "Шкала ярости заполняется быстрее.",
		"type": "stat",
		"effect": {"stat": "rage_gain_mult", "value": 1.5},
		"color": Color(1.0, 0.2, 0.0)
	},
	
	# ── ИЗМЕНЕНИЕ ПУЛЬ ──────────────────────────────────────────
	"bouncy_tears": {
		"name": "Мячик",
		"description": "Пули отскакивают от стен до 3 раз.",
		"type": "bullet",
		"effect": {"flag": "bounce", "value": 3},
		"color": Color(0.5, 1.0, 0.5)
	},
	"homing_tears": {
		"name": "Самонаводка",
		"description": "Пули слегка тянутся к ближайшему врагу.",
		"type": "bullet",
		"effect": {"flag": "homing", "value": 1},
		"color": Color(1.0, 0.4, 1.0)
	},
	"big_tears": {
		"name": "Большие слёзы",
		"description": "Пули крупнее и наносят больше урона, но летят медленнее.",
		"type": "bullet",
		"effect": {"flag": "big", "value": 1},
		"color": Color(0.3, 0.6, 1.0)
	},
	# ── АКТИВНЫЕ ────────────────────────────────────────────────
	"dash": {
		"name": "Рывок",
		"description": "Мгновенный рывок в сторону движения. Кулдаун: 3 сек.",
		"type": "active",
		"effect": {"ability": "dash", "cooldown": 3.0},
		"color": Color(1.0, 1.0, 0.3)
	},
	"bomb": {
		"name": "Бомба",
		"description": "Взрыв вокруг игрока, наносящий урон всем врагам в комнате. Кулдаун: 8 сек.",
		"type": "active",
		"effect": {"ability": "bomb", "cooldown": 8.0},
		"color": Color(1.0, 0.5, 0.0)
	},

	# ── ВИЗУАЛЬНЫЕ / СТРАННЫЕ ───────────────────────────────────
	"slow_world": {
		"name": "Стеклянное время",
		"description": "Мир замедляется. Постоянно.",
		"type": "visual",
		"effect": {"visual": "slow_time", "value": 0.6},
		"color": Color(0.7, 0.9, 1.0)
	},
}


# Подобранные артефакты за забег
var collected: Array[String] = []
# Флаги пуль, накопленные со всех предметов
var bullet_flags: Dictionary = {}
# Активный артефакт (ID или "")
var active_artifact: String = ""

func reset():
	collected.clear()
	bullet_flags.clear()
	active_artifact = ""

func get_random_id() -> String:
	var available: Array = registry.keys().filter(
		func(k): return not collected.has(k)
	)
	if available.is_empty():
		return ""
	return available.pick_random()

func get_data(id: String) -> Dictionary:
	return registry.get(id, {})

func apply_bullet_flag(flag: String, value):
	bullet_flags[flag] = value

func has_bullet_flag(flag: String) -> bool:
	return bullet_flags.has(flag)

func get_bullet_flag(flag: String, default = null):
	return bullet_flags.get(flag, default)
