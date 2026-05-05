class_name WholesaleSaleActivity
extends Activity

# Persistent. One sale match: producer transfers `quantity` of `good_id` to
# merchant in exchange for `quantity * price` coin.
#
# Inventory:grain is tracked in units (one entry = one unit). The merchant
# carries any cost premium above $1/unit in `Cost_of_Inventory`, a
# debit-natural asset-adjustment account, so the merchant's Tx balances at
# any wholesale price. At v0 calibration (price=1.00) the premium leg is
# zero and the Tx collapses to the unit-cost case.

var producer: Actor
var merchant: Actor
@export var good_id: StringName = &"grain"
@export var quantity: float = 0.0
@export var price: float = 0.0

func _init() -> void:
	activity_type = &"WholesaleSaleActivity"

func on_close() -> bool:
	if producer == null or merchant == null or quantity <= 0.0:
		return false
	var fb_producer: FinancialBook = producer.accounts.financial()
	var fb_merchant: FinancialBook = merchant.accounts.financial()
	if fb_producer == null or fb_merchant == null:
		push_error("WholesaleSaleActivity: missing FinancialBook")
		return false

	var total_revenue: float = quantity * price
	var inv_account := Accounts.inventory_account(good_id)

	# Producer Tx 1 — inventory disposal at unit cost basis:
	#   Inventory:grain (debit-natural) down = +qty;
	#   COGS (debit-natural) up = -qty.
	var producer_disposal_tx: Array[JournalEntry] = [
		JournalEntry.make(inv_account, quantity, closed_tick, &"WholesaleSaleActivity"),
		JournalEntry.make(Accounts.A_COGS, -quantity, closed_tick, &"WholesaleSaleActivity"),
	]
	if not fb_producer.commit_transaction(producer_disposal_tx):
		return false

	# Producer Tx 2 — cash receipt:
	#   Cash up = -total_revenue (debit on debit-natural);
	#   Sales_Revenue up = +total_revenue (credit on credit-natural).
	var producer_receipt_tx: Array[JournalEntry] = [
		JournalEntry.make(Accounts.A_CASH, -total_revenue, closed_tick, &"WholesaleSaleActivity"),
		JournalEntry.make(Accounts.A_SALES_REVENUE, total_revenue, closed_tick, &"WholesaleSaleActivity"),
	]
	if not fb_producer.commit_transaction(producer_receipt_tx):
		return false

	# Merchant side — 3-leg balanced Tx:
	#   Inventory:grain up = -qty (debit, units in);
	#   Cost_of_Inventory up = -(total_revenue - qty) (debit, cost premium captured);
	#   Cash down = +total_revenue (credit, cash out).
	var cost_premium: float = total_revenue - quantity
	var merchant_tx: Array[JournalEntry] = [
		JournalEntry.make(inv_account, -quantity, closed_tick, &"WholesaleSaleActivity"),
		JournalEntry.make(Accounts.A_COST_OF_INVENTORY, -cost_premium, closed_tick, &"WholesaleSaleActivity"),
		JournalEntry.make(Accounts.A_CASH, total_revenue, closed_tick, &"WholesaleSaleActivity"),
	]
	if not fb_merchant.commit_transaction(merchant_tx):
		return false

	print("    %s sold %.0f %s to %s @ %.2f (total %.2f)" %
		[producer.actor_id, quantity, good_id, merchant.actor_id, price, total_revenue])
	return true
