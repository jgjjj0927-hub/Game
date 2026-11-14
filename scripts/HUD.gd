extends CanvasLayer

var cross: ColorRect
var weapon_label: Label

func _ready() -> void:
	cross = ColorRect.new()
	cross.color = Color(1, 1, 1, 0.9)
	cross.size = Vector2(4, 4)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	add_child(cross)

	weapon_label = Label.new()
	weapon_label.position = Vector2(20, 680)
	weapon_label.text = "WEAPON: PISTOL"
	add_child(weapon_label)

func _process(_d: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.weapons.size() > 0:
		var w = p.weapons[p.current_weapon]
		weapon_label.text = "WEAPON: " + ("KNIFE" if w.is_melee else "PISTOL")
