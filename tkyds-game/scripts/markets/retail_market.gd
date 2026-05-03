class_name RetailMarket
extends Market

@export var good_id: StringName = &"grain"

func _ready() -> void:
	WindowBus.retail_market_closed.connect(clear)
	print("[Wire] RetailMarket.clear ← WindowBus.retail_market_closed")

func clear() -> void:
	print("[CLEAR]    RetailMarket.clear(%s) — transfer grain merchant→consumers at flat price; coin reverse; consumers' outstanding_demand decremented" % good_id)
	reset_pools()
