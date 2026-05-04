class_name RetailPurchaseActivity
extends Activity

# Persistent. One retail match: merchant sells `quantity` of `good_id` to
# `buyer` at price `unit_price` (P_m).
#
# v0 inventory tracking convention:
#   - Merchant: Inventory:grain in units. Cost basis = $1.00/unit (held over
#     from wholesale buy at price 1.00). On sale, COGS recognized at unit
#     cost; Sales_Revenue at sale price; the gap is profit.
#   - Buyer (consumer): Inventory:grain in units; Consumption_Expense absorbs
#     the markup paid above unit cost.

var merchant: Actor
var buyer: Actor
@export var good_id: StringName = &"grain"
@export var quantity: float = 0.0
@export var unit_price: float = 0.0      # P_m
@export var unit_cost_basis: float = 1.0 # merchant's cost basis per unit (v0: 1.00)

func _init() -> void:
	activity_type = &"RetailPurchaseActivity"

func on_close() -> bool:
	if merchant == null or buyer == null or quantity <= 0.0:
		return false
	var fb_merchant: FinancialBook = merchant.accounts.financial()
	var fb_buyer: FinancialBook = buyer.accounts.financial()
	if fb_merchant == null or fb_buyer == null:
		push_error("RetailPurchaseActivity: missing FinancialBook")
		return false

	var total_revenue: float = quantity * unit_price
	var total_cogs: float = quantity * unit_cost_basis
	var inv_account := Accounts.inventory_account(good_id)

	# Merchant Tx 1 — disposal at cost basis.
	var merchant_disposal_tx: Array[JournalEntry] = [
		JournalEntry.make(inv_account, total_cogs, closed_tick, &"RetailPurchaseActivity"),
		JournalEntry.make(Accounts.A_COGS, -total_cogs, closed_tick, &"RetailPurchaseActivity"),
	]
	if not fb_merchant.commit_transaction(merchant_disposal_tx):
		return false

	# Merchant Tx 2 — cash receipt at sale price.
	var merchant_receipt_tx: Array[JournalEntry] = [
		JournalEntry.make(Accounts.A_CASH, -total_revenue, closed_tick, &"RetailPurchaseActivity"),
		JournalEntry.make(Accounts.A_SALES_REVENUE, total_revenue, closed_tick, &"RetailPurchaseActivity"),
	]
	if not fb_merchant.commit_transaction(merchant_receipt_tx):
		return false

	# Buyer side — 3-leg balanced Tx:
	#   Inventory:grain up = -qty (debit at units);
	#   Cash down = +total_revenue (credit);
	#   Consumption_Expense up = -(total_revenue - qty) (debit, the markup gap).
	var markup_paid: float = total_revenue - quantity
	var buyer_tx: Array[JournalEntry] = [
		JournalEntry.make(inv_account, -quantity, closed_tick, &"RetailPurchaseActivity"),
		JournalEntry.make(Accounts.A_CASH, total_revenue, closed_tick, &"RetailPurchaseActivity"),
		JournalEntry.make(Accounts.A_CONSUMPTION_EXPENSE, -markup_paid, closed_tick, &"RetailPurchaseActivity"),
	]
	if not fb_buyer.commit_transaction(buyer_tx):
		return false

	print("    %s bought %.1f %s from %s @ %.2f (paid %.2f)" %
		[buyer.actor_id, quantity, good_id, merchant.actor_id, unit_price, total_revenue])
	return true
