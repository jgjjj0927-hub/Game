extends Node

var blood_decals: Array = []
const MAX_DECALS := 80

func spawn_blood_decal(pos: Vector3, normal: Vector3, scale_amt: float = 1.0) -> void:
	var decal := Decal.new()
	decal.texture_albedo = _make_blood_texture()
	decal.size = Vector3(0.9, 1.2, 0.9) * scale_amt
	decal.cull_mask = 1
	decal.global_position = pos
	decal.look_at_from_position(pos, pos + normal, Vector3.UP)
	get_tree().current_scene.add_child(decal)
	blood_decals.append(decal)
	if blood_decals.size() > MAX_DECALS:
		var old = blood_decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()

func _make_blood_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for x in size:
		for y in size:
			var dx := (x - size / 2.0) / (size / 2.0)
			var dy := (y - size / 2.0) / (size / 2.0)
			var d := sqrt(dx * dx + dy * dy)
			var a := clamp(1.0 - d * 1.3, 0.0, 1.0)
			a *= randf_range(0.6, 1.0)
			img.set_pixel(x, y, Color(0.4, 0.01, 0.01, a))
	return ImageTexture.create_from_image(img)
