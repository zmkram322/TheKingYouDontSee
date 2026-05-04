class_name MarketClearingEvent
extends Resource

# Player-readable record of a single market clearing (D3 — partial-supply
# visibility). Held on the market as `last_clearing_event`. Lists who
# responded, who didn't, totals, and the clearing price. UI reads this directly.

@export var tick: int = 0
@export var market_name: StringName = &""
@export var good_id: StringName = &""

@export var responding_suppliers: Array[NodePath] = []
@export var non_responding_suppliers: Array[NodePath] = []
@export var responding_demanders: Array[NodePath] = []
@export var non_responding_demanders: Array[NodePath] = []

@export var total_supply: float = 0.0
@export var total_demand: float = 0.0
@export var clearing_price: float = 0.0
