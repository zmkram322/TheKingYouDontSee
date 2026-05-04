class_name Market
extends Node

# Markets in the rebuild use pull-on-open. Suppliers and demanders register
# during bootstrap; open_market(tick) polls them. Clearing creates+closes
# concrete activity Resources per match — the activity's on_close writes the
# books. The cost-basis bug class (where a cached field went stale relative
# to the books) is structurally eliminated: every cost-basis read is a
# FinancialBook period query.

var region: Region
@export var period_length: int = 7      # days per market period

# Filled at bootstrap. Kept as Actor refs (not NodePaths) since markets and
# their actors live in the same scene tree and we need fast iteration.
var registered_suppliers: Array[Actor] = []
var registered_demanders: Array[Actor] = []

# Most recent clearing event — D3 partial-supply visibility for player UI.
var last_clearing_event: MarketClearingEvent

func register_supplier(actor: Actor) -> void:
	if not registered_suppliers.has(actor):
		registered_suppliers.append(actor)

func register_demander(actor: Actor) -> void:
	if not registered_demanders.has(actor):
		registered_demanders.append(actor)

func open_market(_tick: int) -> void:
	pass

func clear_market(_tick: int) -> void:
	pass
