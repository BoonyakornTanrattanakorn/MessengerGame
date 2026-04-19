extends TileMapLayer

class_name IceLayer

func is_on_ice(world_position: Vector2) -> bool:

	var cell = local_to_map(
		to_local(world_position)
	)

	var tile_data = get_cell_tile_data(cell)

	return tile_data and tile_data.get_custom_data("ice")
