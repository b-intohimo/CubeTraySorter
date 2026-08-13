extends Node3D

const MAX_STACK_HEIGHT := 4
const CUBE_SIZE := 0.8
const CUBE_SPACING := 0.85
const TRAY_TOP_Y := 0.2 # Based on tray mesh height (0.4) centered at y=0
const CUBE_BASE_Y := TRAY_TOP_Y + (CUBE_SIZE * 0.5)

const NUM_TRAYS := 5
const NUM_COLORS := NUM_TRAYS - 1

# Animation tuning
const MOVE_UP_HEIGHT := 2.0
const MOVE_UP_TIME := 0.18
const MOVE_OVER_TIME := 0.22
const MOVE_DOWN_TIME := 0.22

const COLOR_RED := "red"
const COLOR_GREEN := "green"
const COLOR_BLUE := "blue"
const COLOR_YELLOW := "yellow"

const COLOR_MAP := {
	COLOR_RED: Color(0.95, 0.2, 0.2, 1.0),
	COLOR_GREEN: Color(0.2, 0.9, 0.35, 1.0),
	COLOR_BLUE: Color(0.2, 0.45, 0.95, 1.0),
	COLOR_YELLOW: Color(0.95, 0.85, 0.15, 1.0),
}

@onready var camera: Camera3D = $Camera3D
@onready var tray_nodes: Array[StaticBody3D] = [
	$Tray0,
	$Tray1,
	$Tray2,
	$Tray3,
	$Tray4,
]
@onready var win_banner: Control = $WinBannerCanvas/WinBanner

var stacks: Array = []
var selected_tray_index := -1
var game_over := false
var is_animating_move := false

func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.2, 0.0), Vector3.UP)
	_initialize_stacks()
	_refresh_all_trays()



func _unhandled_input(event: InputEvent) -> void:
	if game_over or is_animating_move:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tray_index := _pick_tray_index(event.position)
		if tray_index == -1:
			return
		_handle_tray_click(tray_index)

func _initialize_stacks() -> void:
	stacks = []
	for _i in tray_nodes.size():
		stacks.push_back([])

	var colors: Array[String] = [COLOR_RED, COLOR_GREEN, COLOR_BLUE, COLOR_YELLOW]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	game_over = false

	var gen_params := _get_generation_params()
	stacks = LevelGenerator.generate(rng, colors, gen_params)


func _get_generation_params() -> Dictionary:
	return {
		"shuffle_count": GameConfig.get_shuffle_count(),
	}


func _handle_tray_click(tray_index: int) -> void:
	if selected_tray_index == -1:
		if stacks[tray_index].is_empty():
			return
		selected_tray_index = tray_index
		_refresh_all_trays()
		return

	if tray_index == selected_tray_index:
		selected_tray_index = -1
		_refresh_all_trays()
		return

	if _can_move(selected_tray_index, tray_index):
		is_animating_move = true
		await _animate_and_commit_move(selected_tray_index, tray_index)
		selected_tray_index = -1
		_refresh_all_trays()
		if _is_solved():
			game_over = true
			_show_win_banner()
		is_animating_move = false
		return

	# Keep selection active to let the player try another tray.
	_refresh_all_trays()


func _can_move(source_index: int, target_index: int) -> bool:
	var source_stack: Array = stacks[source_index]
	var target_stack: Array = stacks[target_index]

	if source_stack.is_empty():
		return false
	if target_stack.size() >= MAX_STACK_HEIGHT:
		return false

	var moving_color: String = source_stack.back()
	if not target_stack.is_empty():
		var target_color: String = target_stack.back()
		if target_color != moving_color:
			return false

	return true


func _show_win_banner() -> void:
	if not is_instance_valid(win_banner):
		return
	win_banner.visible = true


func _on_win_ok_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _animate_and_commit_move(source_index: int, target_index: int) -> void:
	# Animate the currently visible top cube in the source tray.
	var source_holder: Node3D = tray_nodes[source_index].get_node("CubeHolder")
	var cube_top_count := source_holder.get_child_count()
	if cube_top_count <= 0:
		return

	var cube_body := source_holder.get_child(cube_top_count - 1) as Node3D

	var target_holder: Node3D = tray_nodes[target_index].get_node("CubeHolder")
	var target_stack: Array = stacks[target_index]

	var dest_landing_local := Vector3(0.0, CUBE_BASE_Y + target_stack.size() * CUBE_SPACING, 0.0)
	var dest_landing_global := target_holder.to_global(dest_landing_local)
	var start_global := cube_body.global_position

	var lift_global := start_global + Vector3(0.0, MOVE_UP_HEIGHT, 0.0)
	var dest_above_global := dest_landing_global + Vector3(0.0, MOVE_UP_HEIGHT, 0.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(cube_body, "global_position", lift_global, MOVE_UP_TIME)
	tween.tween_property(cube_body, "global_position", dest_above_global, MOVE_OVER_TIME)

	tween.tween_property(cube_body, "global_position", dest_landing_global, MOVE_DOWN_TIME)
	# Descend and spin 360 degrees around vertical axis.
	tween.parallel().tween_property(cube_body, "rotation:y", cube_body.rotation.y + TAU, MOVE_DOWN_TIME)

	await tween.finished

	# Commit the logical move after the animation completes.
	_try_move(source_index, target_index)


func _try_move(source_index: int, target_index: int) -> bool:
	var source_stack: Array = stacks[source_index]
	var target_stack: Array = stacks[target_index]

	if source_stack.is_empty():
		return false
	if target_stack.size() >= MAX_STACK_HEIGHT:
		return false

	var moving_color: String = source_stack.back()
	if not target_stack.is_empty():
		var target_color: String = target_stack.back()
		if target_color != moving_color:
			return false

	source_stack.pop_back()
	target_stack.push_back(moving_color)
	stacks[source_index] = source_stack
	stacks[target_index] = target_stack
	return true


func _pick_random_non_empty_tray(rng: RandomNumberGenerator) -> int:
	var non_empty: Array[int] = []
	for i in range(tray_nodes.size()):
		if not stacks[i].is_empty():
			non_empty.append(i)
	if non_empty.is_empty():
		return -1
	return non_empty[rng.randi_range(0, non_empty.size() - 1)]


func _is_solved() -> bool:
	return LevelSolver.is_solved(stacks)


func _pick_tray_index(mouse_position: Vector2) -> int:
	var from := camera.project_ray_origin(mouse_position)
	var to := from + camera.project_ray_normal(mouse_position) * 200.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	# Be permissive: trays should be hittable even if collision layers
	# are not on the default mask.
	query.collision_mask = 0xFFFFFFFF
	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		var collider: Object = result["collider"] as Object
		if collider is StaticBody3D:
			if collider.is_in_group("tray"):
				return int(collider.get_meta("tray_index", -1))
			if collider.is_in_group("cube"):
				return int(collider.get_meta("tray_index", -1))

	# Fallback: when physics picking doesn't hit (common with thin/empty
	# stacks), pick the tray geometrically based on proximity to the mouse ray.
	var by_dist := _pick_tray_index_by_ray_distance(from, to)
	if by_dist != -1:
		return by_dist

	# Secondary fallback (kept for stability in some camera angles).
	return _pick_tray_index_by_projection(from, to)


func _pick_tray_index_by_projection(from: Vector3, to: Vector3) -> int:
	# Choose a plane around tray top/cube area (world-space Y).
	var tray_top_y := 0.2
	var dir := to - from
	if absf(dir.y) < 0.00001:
		return -1

	var t := (tray_top_y - from.y) / dir.y
	if t < 0.0 or t > 1.0:
		return -1

	var hit_point := from + dir * t

	var best_index := -1
	var best_dist_sq := INF

	var TRAY_PICK_RADIUS := 2.2
	var radius_sq := TRAY_PICK_RADIUS * TRAY_PICK_RADIUS

	for i in tray_nodes.size():
		var center := tray_nodes[i].global_position
		var dx := hit_point.x - center.x
		var dz := hit_point.z - center.z
		var dist_sq := dx * dx + dz * dz
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_index = i

	if best_dist_sq <= radius_sq:
		return best_index
	return -1


func _pick_tray_index_by_ray_distance(from: Vector3, to: Vector3) -> int:
	var dir := to - from
	var ray_len := dir.length()
	if ray_len < 0.0001:
		return -1
	var dir_norm := dir / ray_len

	var best_index := -1
	var best_dist_sq := INF

	# Tray spacing is 2.5 units. A radius around 1.6 should still keep tray
	# choices unambiguous while making clicking feel forgiving.
	var TRAY_XZ_RADIUS := 1.6
	var radius_sq := TRAY_XZ_RADIUS * TRAY_XZ_RADIUS

	for i in tray_nodes.size():
		var center := tray_nodes[i].global_position

		# Closest point on the ray to the tray center.
		var w := center - from
		var t := w.dot(dir_norm)
		t = clampf(t, 0.0, ray_len)
		var closest := from + dir_norm * t

		var dx := closest.x - center.x
		var dz := closest.z - center.z
		var dist_sq := dx * dx + dz * dz

		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_index = i

	if best_dist_sq <= radius_sq:
		return best_index
	return -1


func _refresh_all_trays() -> void:
	for i in tray_nodes.size():
		_refresh_tray(i)


func _refresh_tray(index: int) -> void:
	var tray := tray_nodes[index]
	var holder := tray.get_node("CubeHolder")

	for child in holder.get_children():
		child.queue_free()

	var stack: Array = stacks[index]
	for cube_index in stack.size():
		var color_name: String = stack[cube_index]
		var cube_body := StaticBody3D.new()
		cube_body.add_to_group("cube")
		cube_body.set_meta("tray_index", index)
		# Position cubes so the bottom face rests on the tray top surface.
		cube_body.position = Vector3(0.0, CUBE_BASE_Y + cube_index * CUBE_SPACING, 0.0)

		var collision_shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
		collision_shape.shape = box_shape
		cube_body.add_child(collision_shape)

		var cube := MeshInstance3D.new()
		cube.mesh = BoxMesh.new()
		cube.scale = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)

		var material := StandardMaterial3D.new()
		material.albedo_color = COLOR_MAP.get(color_name, Color.WHITE)
		material.roughness = 0.35
		material.metallic = 0.05
		cube.material_override = material
		cube_body.add_child(cube)

		# Highlight the currently selected tray's top cube.
		if index == selected_tray_index and cube_index == stack.size() - 1:
			cube_body.scale = Vector3(1.12, 1.12, 1.12)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 1.0, 1.0)
			material.emission_energy_multiplier = 0.8

		holder.add_child(cube_body)
