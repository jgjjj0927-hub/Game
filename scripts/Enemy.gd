extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var left_arm: Node3D = $LeftArm
@onready var right_arm: Node3D = $RightArm
@onready var left_leg: Node3D = $LeftLeg
@onready var right_leg: Node3D = $RightLeg

var hp := 100.0
var max_hp := 100.0
var dead := false
var target: Node3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var wander_time := 0.0
var wander_dir := Vector3.ZERO

const LIMB_DAMAGE_THRESHOLD := 55.0

func _ready() -> void:
	add_to_group("enemy")
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta

	wander_time -= delta
	if wander_time <= 0.0:
		wander_time = randf_range(1.5, 3.5)
		wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

	if target and global_position.distance_to(target.global_position) < 18.0:
		var to := (target.global_position - global_position)
		to.y = 0
		to = to.normalized()
		velocity.x = to.x * 3.2
		velocity.z = to.z * 3.2
	else:
		velocity.x = wander_dir.x * 1.5
		velocity.z = wander_dir.z * 1.5

	move_and_slide()

func take_hit(dmg: float, point: Vector3, dir: Vector3, melee: bool) -> void:
	if dead:
		return
	hp -= dmg
	if dmg >= LIMB_DAMAGE_THRESHOLD:
		_sever_random_limb(dir)
	elif melee and randf() < 0.35:
		_sever_random_limb(dir)

	if hp <= 0.0:
		_die(dir)
	else:
		velocity += dir.normalized() * 2.0

func _sever_random_limb(dir: Vector3) -> void:
	var candidates: Array = []
	if head.visible: candidates.append(head)
	if left_arm.visible: candidates.append(left_arm)
	if right_arm.visible: candidates.append(right_arm)
	if left_leg.visible: candidates.append(left_leg)
	if right_leg.visible: candidates.append(right_leg)
	if candidates.is_empty():
		return
	_detach_limb(candidates.pick_random(), dir)

func _detach_limb(node: Node3D, dir: Vector3) -> void:
	Game.spawn_blood_decal(node.global_position, Vector3.UP, 1.2)
	SoundManager.play_sfx(SoundManager.sever, -2.0, randf_range(0.7, 1.0))

	var gib := RigidBody3D.new()
	gib.mass = 0.4
	gib.collision_layer = 8
	gib.collision_mask = 1 | 8
	gib.gravity_scale = 1.5

	var mesh_copy := node.duplicate()
	gib.add_child(mesh_copy)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.25, 0.5, 0.25)
	col.shape = shape
	gib.add_child(col)

	gib.global_position = node.global_position
	gib.linear_velocity = dir.normalized() * randf_range(4.0, 8.0) + Vector3.UP * randf_range(1.0, 2.0)
	gib.angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))
	get_tree().current_scene.add_child(gib)

	node.visible = false
	var cs := node.get_node_or_null("Hitbox")
	if cs:
		cs.set_deferred("disabled", true)

func _die(dir: Vector3) -> void:
	dead = true
	velocity = Vector3.ZERO
	for n in [head, left_arm, right_arm, left_leg, right_leg]:
		if n.visible:
			_detach_limb(n, dir + Vector3(randf_range(-1, 1), randf_range(0.5, 1.5), randf_range(-1, 1)))
	Game.spawn_blood_decal(global_position, Vector3.UP, 2.5)
	get_tree().create_timer(8.0).timeout.connect(queue_free)
