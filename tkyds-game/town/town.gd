extends Node2D

# Builds the TileSet in code from the raw atlas texture, then paints the two
# TileMapLayers from TownMap's data. See town_map.gd for the actual layout.

const TILE_SIZE := 16
const ATLAS_COLUMNS := 12
const ATLAS_ROWS := 11
const TOWN_TILESET_TEXTURE := preload("res://assets/tiny_town/tilemap_packed.png")
const PLAYER_SCENE := preload("res://town/player.tscn")

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var props_layer: TileMapLayer = $World/PropsLayer
@onready var world: Node2D = $World

var _marked_solid: Dictionary = {}  # tile_index -> true, avoids re-adding collision polygons


func _ready() -> void:
	var tile_set := _build_tile_set()
	ground_layer.tile_set = tile_set
	props_layer.tile_set = tile_set
	_paint_map(tile_set)
	_spawn_player()


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()

	var atlas := TileSetAtlasSource.new()
	atlas.texture = TOWN_TILESET_TEXTURE
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in range(ATLAS_ROWS):
		for x in range(ATLAS_COLUMNS):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, 0)
	return tile_set


func _paint_map(tile_set: TileSet) -> void:
	var rows := TownMap.get_rows()
	for y in range(rows.size()):
		var row := rows[y]
		for x in range(row.length()):
			var glyph := row[x]
			if not TownMap.LEGEND.has(glyph):
				push_warning("town_map: no legend entry for '%s' at (%d,%d)" % [glyph, x, y])
				continue
			var spec: Dictionary = TownMap.LEGEND[glyph]
			var cell := Vector2i(x, y)
			ground_layer.set_cell(cell, 0, TownMap.atlas_coords_for_index(spec.ground))
			if spec.prop >= 0:
				props_layer.set_cell(cell, 0, TownMap.atlas_coords_for_index(spec.prop))
				if spec.solid:
					_mark_solid(tile_set, spec.prop)
			elif spec.solid:
				_mark_solid(tile_set, spec.ground)


func _mark_solid(tile_set: TileSet, tile_index: int) -> void:
	if _marked_solid.has(tile_index):
		return
	_marked_solid[tile_index] = true

	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	var coords := TownMap.atlas_coords_for_index(tile_index)
	var data := atlas.get_tile_data(coords, 0)
	data.add_collision_polygon(0)
	var half := TILE_SIZE / 2.0
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half),
	]))


func _spawn_player() -> void:
	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(
		TownMap.SPAWN.x * TILE_SIZE + TILE_SIZE / 2.0,
		TownMap.SPAWN.y * TILE_SIZE + TILE_SIZE / 2.0
	)
	world.add_child(player)
	var camera := player.get_node("Camera2D") as Camera2D
	if camera:
		camera.make_current()
