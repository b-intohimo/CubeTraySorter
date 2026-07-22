extends SceneTree

const Solver = preload("res://scripts/LevelSolver.gd")


func _initialize() -> void:
	var buckets: Dictionary = {}
	for i in range(3, 11):
		buckets[i] = []

	var start: Array = [
		["red", "red", "red", "red"],
		["green", "green", "green", "green"],
		["blue", "blue", "blue", "blue"],
		[],
		[],
	]

	var all_states: Array[Array] = []
	var queue: Array = [start]
	var seen := {Solver.state_key(start): true}

	while not queue.is_empty():
		var current: Array = queue.pop_front()
		if not Solver.is_solved(current):
			all_states.append(current)

		for source in range(5):
			if current[source].is_empty():
				continue
			for target in range(5):
				if source == target or not Solver.can_move(current, source, target):
					continue
				var next := Solver.duplicate_stacks(current)
				Solver.apply_move(next, source, target)
				var k := Solver.state_key(next)
				if seen.has(k):
					continue
				seen[k] = true
				queue.append(next)

	print("total states:", all_states.size())
	for current in all_states:
		var min_moves: int = Solver.min_moves_to_solve(current, 22)
		if min_moves >= 3 and min_moves <= 10:
			var bucket: Array = buckets[min_moves]
			var encoded := Solver.state_key(current)
			if bucket.size() < 20 and not bucket.has(encoded):
				bucket.append(encoded)

	for min_moves in range(3, 11):
		print("min=%d count=%d" % [min_moves, buckets[min_moves].size()])

	var lines: PackedStringArray = ["extends Resource", "", "const PUZZLES := {"]
	for min_moves in range(3, 11):
		var entries: Array = buckets[min_moves]
		var encoded_entries: PackedStringArray = []
		for entry in entries:
			encoded_entries.append('"%s"' % entry)
		lines.append("\t%d: [%s]," % [min_moves, ", ".join(encoded_entries)])
	lines.append("}")

	DirAccess.make_dir_recursive_absolute("/Users/kgorecki/Projects/CubeTraySorter/resources")
	var file := FileAccess.open("res://resources/puzzle_bank.gd", FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
	print("done")
	quit()
