class_name Accounts
extends Resource

# Per-actor books. Keys: &"financial", &"skills", &"vitals".
# Phase 3+ may add &"reputation".
@export var books: Dictionary = {}

# Persistent agreements (not journal flow).
@export var contracts: Array[Contract] = []

# Persistent assets (parcels, mills, etc.).
@export var owned_resources: Array[ProductionResource] = []

# Activity tree — persistent activities the actor is the primary participant in.
# Transient activities live as child_activities of a persistent parent and are
# discarded after the parent reads their accumulated deltas.
@export var activities: Array[Activity] = []

# Universal account vocabulary — referenced by activities when writing entries.
# Adding a new account is a one-string change.
const A_CASH := &"Cash"
const A_OWNER_EQUITY := &"Owner_Equity"
const A_WAGES_INCOME := &"Wages_Income"
const A_WAGES_EXPENSE := &"Wages_Expense"
const A_SALES_REVENUE := &"Sales_Revenue"
const A_COGS := &"Cost_of_Goods_Sold"
const A_LORD_TAX_EXPENSE := &"Lord_Tax_Expense"
const A_CONSUMPTION_EXPENSE := &"Consumption_Expense"
const A_PRODUCTION_OUTPUT_VALUE := &"Production_Output_Value"

static func inventory_account(good_id: StringName) -> StringName:
	return StringName("Inventory:%s" % good_id)

static func payable_account(counterparty: StringName) -> StringName:
	return StringName("Payable:%s" % counterparty)

static func receivable_account(counterparty: StringName) -> StringName:
	return StringName("Receivable:%s" % counterparty)

func financial() -> FinancialBook:
	return books.get(&"financial", null) as FinancialBook

func skills() -> SkillsBook:
	return books.get(&"skills", null) as SkillsBook

func vitals() -> VitalsBook:
	return books.get(&"vitals", null) as VitalsBook

# Convenience: current cash balance (all-time). Cash is debit-natural, so the
# raw sum of entries is negative for held coin — we negate for natural reading.
func cash() -> float:
	var fb := financial()
	if fb == null:
		return 0.0
	return -fb.balance(A_CASH)

# Current inventory of a good (debit-natural; negated for natural reading).
func inventory_of(good_id: StringName) -> float:
	var fb := financial()
	if fb == null:
		return 0.0
	return -fb.balance(inventory_account(good_id))

# Convenience: outstanding payable to a specific counterparty.
func payable_to(counterparty: StringName) -> float:
	var fb := financial()
	if fb == null:
		return 0.0
	return fb.balance(payable_account(counterparty))

# All currently-outstanding payables: returns Array of {counterparty, amount}.
# Walks the journal once. Used by EmployerInterest at week's wage settlement.
func outstanding_payables() -> Array:
	var fb := financial()
	if fb == null:
		return []
	var totals: Dictionary = {}
	for e in fb.journal:
		var s: String = String(e.account)
		if not s.begins_with("Payable:"):
			continue
		var counterparty := StringName(s.substr(8))
		totals[counterparty] = totals.get(counterparty, 0.0) + e.amount
	var out: Array = []
	for cp in totals.keys():
		var amt: float = totals[cp]
		if abs(amt) > 0.0001:
			out.append({"counterparty": cp, "amount": amt})
	return out
