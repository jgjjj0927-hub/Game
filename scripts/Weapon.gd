extends Node3D

enum Kind { PISTOL, KNIFE }
var kind: Kind = Kind.PISTOL
var cooldown := 0.0
var fire_rate := 0.15
var damage := 45.0
var range_m := 100.0
var is_melee := false

var muzzle_flash: OmniLight3D
var ray: RayCast3D
var player_ref: Node3D

func configure(weapon_name: String, player: Node3D) -> void:
	player_ref = player
	if weapon_name == "knife":
		kind = Kind.KNIFE
		is_melee = true
		fire_rate = 0.35
		damage = 80.0
		range_m = 2.2
	else:
		kind = Kind.PISTOL
		is_melee = false
		fire_rate = 0.15
		damage = 45.0
		range_m = 100.0

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.4) if not is_melee else Vector3(0.03, 0.03, 0.35)
	mesh.mesh = box
	mesh.position = Vector3(0.25, -0.15, -0.4)
	add_child(mesh)

	muzzle_flash = OmniLight3D.new()
	muzzle_flash.light_color = Color(1.0, 0.7, 0.3)
	muzzle_flash.light_energy = 0.0
	muzzle_flash.omni_range = 6.0
	muzzle_flash.position = Vector3(0.25, -0.15, -0.7)
	add_child(muzzle_flash)

	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -range_m)
	ray.collision_mask = 1 | 4  # world + enemy
	ray.position = Vector3(0.25, -0.15, -0.4)
	ray.enabled = true
	add_child(ray)

func _process(delta: float) -> void:
	cooldown -= delta
	if muzzle_flash.light_energy > 0.0:
		muzzle_flash.light_energy = move_toward(muzzle_flash.light_energy, 0.0, delta * 60.0)

func try_fire() -> void:
	if cooldown > 0.0:
		return
	cooldown = fire_rate
	if is_melee:
		_melee()
	else:
		_shoot()

func _shoot() -> void:
	muzzle_flash.light_energy = 4.0
	SoundManager.play_sfx(SoundManager.gunshot, -6.0, randf_range(0.95, 1.05))
	if not ray.is_colliding():
		return
	var hit: Object = ray.get_collider()
	var point: Vector3 = ray.get_collision_point()
	var normal: Vector3 = ray.get_collision_normal()
	Game.spawn_blood_decal(point, normal)
	SoundManager.play_sfx(SoundManager.flesh, -4.0, randf_range(0.8, 1.2))
	if hit and hit.has_method("take_hit"):
		var dir := (point - player_ref.global_position).normalized()
		hit.take_hit(damage, point, dir, false)

func _melee() -> void:
	SoundManager.play_sfx(SoundManager.knife, -8.0, randf_range(0.9, 1.1))
	var space := get_world_3d().direct_space_state
	var origin: Vector3 = player_ref.global_position + Vector3.UP
	var cam := player_ref.get_node("Head/Camera3D") as Camera3D
	var dir: Vector3 = -cam.global_transform.basis.z
	var params := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	params.shape = sphere
	params.transform = Transform3D(Basis(), origin + dir * 1.6)
	params.collision_mask = 4
	var results := space.intersect_shape(params, 4)
	for r in results:
		var c: Object = r.collider
		if c and c.has_method("take_hit"):
			SoundManager.play_sfx(SoundManager.flesh, -4.0, randf_range(0.8, 1.2))
			c.take_hit(damage, c.global_position, dir, true)
			break
