extends RefCounted

const SAVE_PATH = "user://math_plane_progress.cfg"


static func get_best_stars(world_key: String, mode_key: String) -> int:
	var config = ConfigFile.new()
	var load_result = config.load(SAVE_PATH)

	if load_result != OK:
		return 0

	return clampi(
		int(config.get_value(world_key, mode_key, 0)),
		0,
		3
	)


static func save_best_stars(world_key: String, mode_key: String, stars: int) -> int:
	var config = ConfigFile.new()
	config.load(SAVE_PATH)

	var current_best = clampi(
		int(config.get_value(world_key, mode_key, 0)),
		0,
		3
	)

	var new_best = maxi(current_best, clampi(stars, 0, 3))

	if new_best > current_best:
		config.set_value(world_key, mode_key, new_best)
		config.save(SAVE_PATH)

	return new_best
