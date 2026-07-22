class_name LevelGenerator
extends RefCounted

const Solver = preload("res://scripts/LevelSolver.gd")

const MAX_STACK_HEIGHT := 4
const NUM_TRAYS := 5


static func generate(
	rng: RandomNumberGenerator,
	colors: Array[String],
	params: Dictionary,
) -> Array:
	var shuffle_count: int = params.get("shuffle_count", 10)

	for _attempt in range(25):
		var stacks := _create_solved(colors)
		var empty_tray := NUM_TRAYS - 1

		# Seed the spare tray; moves may ignore color rules but must be undoable in-game.
		_gen_reversible_move_to_tray(stacks, rng, empty_tray)
		_gen_reversible_move_to_tray(stacks, rng, empty_tray)

		for _i in shuffle_count:
			_gen_random_reversible_move(stacks, rng)

		if not Solver.is_solved(stacks):
			return stacks

	var fallback := _create_solved(colors)
	_gen_random_reversible_move(fallback, rng)
	return fallback


static func _create_solved(colors: Array[String]) -> Array:
	var stacks: Array = [[], [], [], [], []]
	for c in range(colors.size()):
		for _k in range(MAX_STACK_HEIGHT):
			stacks[c].append(colors[c])
	return stacks


static func _gen_reversible_move_to_tray(
	stacks: Array,
	rng: RandomNumberGenerator,
	target_tray: int,
) -> bool:
	var moves := _collect_reversible_moves(stacks, target_tray)
	if moves.is_empty():
		return false

	var move := moves[rng.randi_range(0, moves.size() - 1)]
	_apply_unconstrained_move(stacks, move.x, move.y)
	return true


static func _gen_random_reversible_move(stacks: Array, rng: RandomNumberGenerator) -> bool:
	var moves := _collect_reversible_moves(stacks)
	if moves.is_empty():
		return false

	var move := moves[rng.randi_range(0, moves.size() - 1)]
	_apply_unconstrained_move(stacks, move.x, move.y)
	return true


static func _collect_reversible_moves(
	stacks: Array,
	target_tray: int = -1,
) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []

	for source in range(NUM_TRAYS):
		if stacks[source].is_empty():
			continue
		for target in range(NUM_TRAYS):
			if source == target:
				continue
			if target_tray != -1 and target != target_tray:
				continue
			if _is_reversible_move(stacks, source, target):
				moves.append(Vector2i(source, target))

	return moves


static func _is_reversible_move(stacks: Array, source: int, target: int) -> bool:
	if not _can_move_unconstrained(stacks, source, target):
		return false

	var next := Solver.duplicate_stacks(stacks)
	_apply_unconstrained_move(next, source, target)
	# Undo must be a valid in-game move so the scramble can be reversed legally.
	return Solver.can_move(next, target, source)


static func _can_move_unconstrained(stacks: Array, source: int, target: int) -> bool:
	if stacks[source].is_empty():
		return false
	if stacks[target].size() >= MAX_STACK_HEIGHT:
		return false
	return true


static func _apply_unconstrained_move(stacks: Array, source: int, target: int) -> void:
	var cube = stacks[source].pop_back()
	stacks[target].push_back(cube)
