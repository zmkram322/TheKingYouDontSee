class_name TownMap
extends RefCounted

# The town layout, as data. Edit the ASCII picture below to reshape the town —
# town.gd just reads this file and paints tiles, it has no map knowledge of its own.
#
# Every character in MAP is one 16x16 tile. Each legend entry names:
#   ground  — tile index (row-major, 12 columns wide) painted on the ground layer
#   prop    — tile index painted on the props layer above the ground, or -1 for none
#   solid   — whether the tile blocks movement (collision is added to whichever
#             layer actually has a tile: the prop if there is one, else the ground)
#
# Tile indices refer to tkyds-game/assets/tiny_town/tilemap_packed.png,
# a 12 column x 11 row atlas of 16x16 tiles, no spacing (index = row * 12 + col).

const ATLAS_COLUMNS := 12

const SPAWN := Vector2i(20, 6)  # tile coords, on the road just below the player's cottage door

const MAP := """
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
T.............T....A...............B...T
T........B..................T.........AT
T..789.789.789.789.789.................T
T..qdz.qdz.qdz.qdzBqdx.A...............T
T...................~............T.....T
T..~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....T
TB......~...........~...T..A...........T
TT......~...........~...............B.TT
T.......~.B.A..T....~..................T
T.......~...........~........T.A.......T
T.....T.~..........B~..................T
T..-----~------.A.pppppppppp...........T
T..|ffffffffff|...pKppppppppB.....TA...T
TAB|ffffffffff|~~~pppppppppp...........T
T..|ffffffffff|...ppppWppppp.........B.T
T.T|ffffffffff|...pppppppppp...........T
T..|ffffffffff|.T.pppppppppp...........T
T..|ffffffffff|...ppppppppKp..T........T
T..------------...pppppppppp...........T
T........A..........~T.......B.........T
T..B..............abbbc.....A......T...T
T...........T.....jkjkj...............BT
T...........BA....jjnjj...T............T
T..T............................A......T
T................T...B.................T
T................A.............T.......T
T.......T.....................B.....A..T
T.A.B.................T................T
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
"""

# char -> {ground: int, prop: int, solid: bool}
const LEGEND := {
	# -- open ground --
	".": {"ground": 0, "prop": -1, "solid": false},    # plain grass
	"~": {"ground": 25, "prop": -1, "solid": false},    # dirt road
	"f": {"ground": 41, "prop": -1, "solid": false},    # tilled field earth
	"p": {"ground": 109, "prop": -1, "solid": false},   # town square paving

	# -- fence (tilled field boundary) --
	"-": {"ground": 0, "prop": 81, "solid": true},      # fence, horizontal rail
	"|": {"ground": 0, "prop": 56, "solid": true},      # fence, vertical rail

	# -- scatter / world-edge greenery --
	"T": {"ground": 0, "prop": 4, "solid": true},       # pine tree
	"A": {"ground": 0, "prop": 3, "solid": true},       # autumn tree
	"B": {"ground": 0, "prop": 5, "solid": true},       # bush

	# -- town square furniture --
	"W": {"ground": 109, "prop": 103, "solid": true},   # well
	"K": {"ground": 109, "prop": 93, "solid": true},    # barrel

	# -- grey/stone cottages (worker housing + player's cottage), 3 wide x 2 tall --
	"7": {"ground": 0, "prop": 60, "solid": true},      # roof, left
	"8": {"ground": 0, "prop": 63, "solid": true},      # roof, peak
	"9": {"ground": 0, "prop": 62, "solid": true},      # roof, right
	"q": {"ground": 0, "prop": 76, "solid": true},      # wall, left
	"d": {"ground": 0, "prop": 89, "solid": true},      # wall, door
	"z": {"ground": 0, "prop": 77, "solid": true},      # wall, right (worker cottages)
	"x": {"ground": 0, "prop": 79, "solid": true},      # wall, window (player's cottage — marks it as distinct)

	# -- red-roofed tavern (wood walls + shingled roof), 5 wide x 3 tall --
	"a": {"ground": 0, "prop": 64, "solid": true},      # roof, left shingle
	"b": {"ground": 0, "prop": 67, "solid": true},      # roof, peak
	"c": {"ground": 0, "prop": 66, "solid": true},      # roof, right shingle
	"j": {"ground": 0, "prop": 72, "solid": true},      # wall, plain
	"k": {"ground": 0, "prop": 84, "solid": true},      # wall, window
	"n": {"ground": 0, "prop": 85, "solid": true},      # wall, door
}


static func get_rows() -> PackedStringArray:
	return MAP.strip_edges().split("\n")


static func atlas_coords_for_index(tile_index: int) -> Vector2i:
	return Vector2i(tile_index % ATLAS_COLUMNS, tile_index / ATLAS_COLUMNS)
