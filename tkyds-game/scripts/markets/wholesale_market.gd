class_name WholesaleMarket
extends Market

@export var good_id: StringName = &"grain"

func _ready() -> void:
	WindowBus.wholesale_market_closed.connect(clear)
	print("[Wire] WholesaleMarket.clear ← WindowBus.wholesale_market_closed")

func clear() -> void:
	print("    WholesaleMarket.clear(%s) — transfer grain owner→merchant at flat price; coin reverse" % good_id)
	reset_pools()
