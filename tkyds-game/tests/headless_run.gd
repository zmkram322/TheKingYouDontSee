extends SceneTree

# Headless smoke run: boot the sim, step it, dump the log.
# Usage: godot --headless --path tkyds-game --script res://tests/headless_run.gd -- [ticks]

func _initialize() -> void:
	var ticks := 30
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0].is_valid_int():
		ticks = int(args[0])

	var sim := Simulation.new()
	sim.reset()
	for i in range(ticks):
		sim.advance_one_tick()

	for line in sim.log_lines:
		print(line)
	print("=== headless run complete: %d ticks ===" % ticks)
	quit(0)
