@tool
extends EditorScript

const LEVEL_PATH := "res://game/chapter_1/node_3/level_3.tscn"
const MASTER_TILESET_PATH := "res://assets/sprites/maps/tilesets/tileset_16px.tres"

# Only visual layers are migrated. Logic/special layers stay isolated.
const LAYERS_TO_MIGRATE := [
	"Hole",
	"Tile",
	"Prop",
	"PropNoCollider",
	"Red_Shuffle",
	"Blue_Shuffle",
	"Green_Shuffle",
]

func _run() -> void:
	var packed_scene := load(LEVEL_PATH) as PackedScene
	if packed_scene == null:
		push_error("Unable to load level scene: %s" % LEVEL_PATH)
		return

	var master_tileset := load(MASTER_TILESET_PATH) as TileSet
	if master_tileset == null:
		push_error("Unable to load master tileset: %s" % MASTER_TILESET_PATH)
		return

	var level := packed_scene.instantiate() as Node
	if level == null:
		push_error("Unable to instantiate level scene: %s" % LEVEL_PATH)
		return

	var timestamp := Time.get_unix_time_from_system()
	var level_backup_path := "%s.bak_%d" % [LEVEL_PATH, timestamp]
	var master_backup_path := "%s.bak_%d" % [MASTER_TILESET_PATH, timestamp]
	_backup_resource_file(LEVEL_PATH, level_backup_path)
	_backup_resource_file(MASTER_TILESET_PATH, master_backup_path)

	var added_sources := _sync_master_sources_from_layers(level, master_tileset)
	if added_sources < 0:
		level.free()
		return
	if added_sources > 0:
		var save_master_code := ResourceSaver.save(master_tileset, MASTER_TILESET_PATH)
		if save_master_code != OK:
			push_error("Unable to save master tileset after sync: %s" % error_string(save_master_code))
			level.free()
			return
		print("Master tileset synced with %d atlas source(s)." % added_sources)

	var migrated_layers := 0
	for layer_name in LAYERS_TO_MIGRATE:
		var layer := level.get_node_or_null(layer_name) as TileMapLayer
		if layer == null:
			push_warning("Layer not found, skipping: %s" % layer_name)
			continue

		if layer.tile_set == null:
			push_warning("Layer has no tileset, skipping: %s" % layer_name)
			continue

		if layer.tile_set.resource_path == MASTER_TILESET_PATH:
			print("Already on master tileset: %s" % layer_name)
			continue

		var result := _migrate_layer(layer, master_tileset)
		if not result.ok:
			push_error("Layer migration failed [%s]: %s" % [layer_name, result.message])
			level.free()
			return

		migrated_layers += 1
		print("Migrated %s (%d cells)" % [layer_name, result.cells])

	if migrated_layers == 0:
		print("No layers migrated. Scene unchanged.")
		level.free()
		return

	var out_scene := PackedScene.new()
	var pack_code := out_scene.pack(level)
	if pack_code != OK:
		push_error("Unable to pack migrated scene: %s" % error_string(pack_code))
		level.free()
		return

	var save_code := ResourceSaver.save(out_scene, LEVEL_PATH)
	if save_code != OK:
		push_error("Unable to save migrated scene: %s" % error_string(save_code))
		level.free()
		return

	print("Migration complete. Updated %d layers in %s" % [migrated_layers, LEVEL_PATH])
	level.free()

func _backup_resource_file(from_res_path: String, to_res_path: String) -> void:
	var from_global := ProjectSettings.globalize_path(from_res_path)
	var to_global := ProjectSettings.globalize_path(to_res_path)
	var copy_code := DirAccess.copy_absolute(from_global, to_global)
	if copy_code != OK:
		push_warning("Could not create backup (%s): %s" % [to_res_path, error_string(copy_code)])
	else:
		print("Backup created: %s" % to_res_path)

func _migrate_layer(layer: TileMapLayer, master_tileset: TileSet) -> Dictionary:
	var source_map := _build_source_remap(layer.tile_set, master_tileset)

	var used_cells := layer.get_used_cells()
	if used_cells.is_empty():
		layer.tile_set = master_tileset
		return {"ok": true, "cells": 0, "message": "empty layer"}

	var cells_to_rewrite: Array[Dictionary] = []
	for coords in used_cells:
		var old_source := layer.get_cell_source_id(coords)
		if old_source == -1:
			continue

		if not source_map.has(old_source):
			return {
				"ok": false,
				"cells": 0,
				"message": "No source remap for source_id=%d at %s" % [old_source, str(coords)],
			}

		var atlas_coords := layer.get_cell_atlas_coords(coords)
		var alternative_tile := layer.get_cell_alternative_tile(coords)
		var new_source: int = int(source_map[old_source])

		var master_source := master_tileset.get_source(new_source)
		if master_source is TileSetAtlasSource:
			var atlas_source := master_source as TileSetAtlasSource
			if not atlas_source.has_tile(atlas_coords):
				return {
					"ok": false,
					"cells": 0,
					"message": "Missing atlas coords %s in master source_id=%d" % [str(atlas_coords), new_source],
				}

		cells_to_rewrite.append({
			"coords": coords,
			"source": new_source,
			"atlas": atlas_coords,
			"alt": alternative_tile,
		})

	layer.tile_set = master_tileset
	for entry in cells_to_rewrite:
		layer.set_cell(entry.coords, entry.source, entry.atlas, entry.alt)

	return {"ok": true, "cells": cells_to_rewrite.size(), "message": "ok"}

func _build_source_remap(old_tileset: TileSet, master_tileset: TileSet) -> Dictionary:
	var old_by_texture := _atlas_sources_by_texture(old_tileset)
	var master_by_texture := _atlas_sources_by_texture(master_tileset)

	var map := {}
	for texture_path in old_by_texture.keys():
		if master_by_texture.has(texture_path):
			map[old_by_texture[texture_path]] = master_by_texture[texture_path]

	return map

func _sync_master_sources_from_layers(level: Node, master_tileset: TileSet) -> int:
	var master_textures := _atlas_sources_by_texture(master_tileset)
	var added := 0

	for layer_name in LAYERS_TO_MIGRATE:
		var layer := level.get_node_or_null(layer_name) as TileMapLayer
		if layer == null or layer.tile_set == null:
			continue

		for i in layer.tile_set.get_source_count():
			var source_id := layer.tile_set.get_source_id(i)
			var source := layer.tile_set.get_source(source_id)
			if source is TileSetAtlasSource:
				var atlas_source := source as TileSetAtlasSource
				if atlas_source.texture == null:
					continue
				var texture_path := atlas_source.texture.resource_path
				if texture_path == "" or master_textures.has(texture_path):
					continue

				var duplicate_source := atlas_source.duplicate(true)
				if duplicate_source == null:
					push_error("Unable to duplicate atlas source for texture: %s" % texture_path)
					return -1

				var add_code := master_tileset.add_source(duplicate_source)
				if add_code < 0:
					push_error("Unable to add atlas source to master for texture: %s" % texture_path)
					return -1

				master_textures[texture_path] = add_code
				added += 1

	return added

func _atlas_sources_by_texture(tileset: TileSet) -> Dictionary:
	var result := {}
	for i in tileset.get_source_count():
		var source_id := tileset.get_source_id(i)
		var source := tileset.get_source(source_id)
		if source is TileSetAtlasSource:
			var atlas_source := source as TileSetAtlasSource
			if atlas_source.texture != null and atlas_source.texture.resource_path != "":
				result[atlas_source.texture.resource_path] = source_id
	return result
