class_name LevelSolver
extends RefCounted

const MAX_STACK_HEIGHT := 4
const NUM_TRAYS := 5

const COLOR_CODES := {
	"red": "r",
	"green": "g",
	"blue": "b",
	"yellow": "y",
}

const CODE_COLORS := {
	"r": "red",
	"g": "green",
	"b": "blue",
	"y": "yellow",
}

const HOME_COLORS := ["red", "green", "blue", "yellow"]


static func min_moves_to_solve(stacks: Array, max_depth: int = 50) -> int:
	if is_solved(stacks):
		return 0

	var visited := {}
	var queue: Array[Array] = [[duplicate_stacks(stacks), 0]]
	visited[state_key(stacks)] = true

	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var current: Array = item[0]
		var depth: int = item[1]

		if depth >= max_depth:
			continue

		for source in range(NUM_TRAYS):
			if current[source].is_empty():
				continue
			for target in range(NUM_TRAYS):
				if source == target:
					continue
				if not can_move(current, source, target):
					continue

				var next := duplicate_stacks(current)
				apply_move(next, source, target)
				var next_depth := depth + 1

				if is_solved(next):
					return next_depth

				var key := state_key(next)
				if visited.has(key):
					continue
				visited[key] = true
				queue.append([next, next_depth])

	return -1


static func is_solved(stacks_state: Array) -> bool:
	for i in range(HOME_COLORS.size()):
		var stack: Array = stacks_state[i]
		if stack.size() != MAX_STACK_HEIGHT:
			return false
		for color_name in stack:
			if color_name != HOME_COLORS[i]:
				return false

	for i in range(HOME_COLORS.size(), NUM_TRAYS):
		if not stacks_state[i].is_empty():
			return false

	return true


static func decode_state(encoded: String) -> Array:
	var stacks: Array = [[], [], [], [], []]
	var tray_parts := encoded.split("|")
	for i in range(mini(tray_parts.size(), NUM_TRAYS)):
		for code in tray_parts[i]:
			stacks[i].append(CODE_COLORS.get(code, "red"))
	return stacks


static func state_key(stacks_state: Array) -> String:
	var parts: PackedStringArray = []
	for stack in stacks_state:
		var encoded := ""
		for color_name in stack:
			encoded += COLOR_CODES.get(color_name, "?")
		parts.append(encoded)
	return "|".join(parts)


static func duplicate_stacks(source: Array) -> Array:
	var copy: Array = []
	for stack in source:
		copy.append(stack.duplicate())
	return copy


static func can_move(stacks_state: Array, source_index: int, target_index: int) -> bool:
	var source_stack: Array = stacks_state[source_index]
	var target_stack: Array = stacks_state[target_index]

	if source_stack.is_empty():
		return false
	if target_stack.size() >= MAX_STACK_HEIGHT:
		return false

	var moving_color: String = source_stack.back()
	if not target_stack.is_empty() and target_stack.back() != moving_color:
		return false

	return true


static func apply_move(stacks_state: Array, source_index: int, target_index: int) -> void:
	var moving_color: String = stacks_state[source_index].pop_back()
	stacks_state[target_index].push_back(moving_color)
