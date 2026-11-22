extends GutTest
## Checkpoint.reached：第一次激活发一次，之后不再发


func test_notify_reached_emits_once() -> void:
	var checkpoint := Checkpoint.new()
	add_child_autofree(checkpoint)
	watch_signals(checkpoint)
	checkpoint.notify_reached()
	assert_signal_emitted_with_parameters(checkpoint, "level_event", ["reached"])
	checkpoint.notify_reached()
	checkpoint.notify_reached()
	assert_signal_emit_count(checkpoint, "level_event", 1, "只有第一次激活发事件")
