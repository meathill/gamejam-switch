extends GutTest
## 每一关都要有解法（tests/solutions/<id>.json），并且按解法能通关

const Runner := preload("res://tests/level_script_runner.gd")
const LEVEL_SCENE := preload("res://scenes/levels/level.tscn")
const SOLUTION_DIR := "res://tests/solutions/"


func test_every_level_is_solvable() -> void:
	for level_id in LevelCatalog.get_ids():
		var path := SOLUTION_DIR + level_id + ".json"
		assert_true(FileAccess.file_exists(path), "%s 没有解法文件" % level_id)
		if FileAccess.file_exists(path):
			await _play(level_id, JSON.parse_string(FileAccess.get_file_as_string(path)))


func _play(level_id: String, solution: Dictionary) -> void:
	GameState.current_level_id = level_id
	GameState.seen_intros[level_id] = true
	var level: Level = LEVEL_SCENE.instantiate()
	add_child(level)
	await wait_physics_frames(4)
	await Runner.new(self, level).run(solution["steps"])
	assert_true(GameState.is_level_complete, "%s 按解法没能通关" % level_id)
	level.queue_free()
	await wait_physics_frames(2)
