class_name WorkDayActivity
extends Activity

# Persistent — the smallest persistent unit of work. Books are written
# atomically at on_close from accumulators populated by transient
# WorkSlotActivity children.

# Set at construction.
var worker: Actor
var employer: Actor
var contract: LaborContract
@export var good_id: StringName = &"grain"

# Accumulators — incremented by WorkSlotActivity children at slot close.
@export var slots_worked: int = 0
@export var grain_produced_today: float = 0.0
@export var farming_xp_earned: float = 0.0
@export var calories_burned: float = 0.0
@export var fatigue_incurred: float = 0.0
@export var wages_accrued: float = 0.0

func _init() -> void:
	activity_type = &"WorkDayActivity"

func on_close() -> bool:
	if employer == null or worker == null:
		push_error("WorkDayActivity.on_close: missing participants")
		return false

	var fb_employer: FinancialBook = employer.accounts.financial()
	if fb_employer == null:
		push_error("WorkDayActivity: employer has no FinancialBook")
		return false

	# Tx 1 — accrue grain output. Inventory:grain (asset, debit-natural) up,
	# Production_Output_Value (revenue, credit-natural) up. Asset increase = debit
	# (negative entry); revenue increase = credit (positive entry). Net = 0.
	if grain_produced_today > 0.0:
		var inv_account := Accounts.inventory_account(good_id)
		var grain_tx: Array[JournalEntry] = [
			JournalEntry.make(inv_account, -grain_produced_today, closed_tick, &"WorkDayActivity"),
			JournalEntry.make(Accounts.A_PRODUCTION_OUTPUT_VALUE, grain_produced_today, closed_tick, &"WorkDayActivity"),
		]
		fb_employer.commit_transaction(grain_tx)

	# Tx 2 — accrue wages owed. Wages_Expense (debit-natural) up = -X.
	# Payable:{worker} (liability, credit-natural) up = +X. Net = 0.
	if wages_accrued > 0.0:
		var payable_account := Accounts.payable_account(worker.actor_id)
		var wage_tx: Array[JournalEntry] = [
			JournalEntry.make(Accounts.A_WAGES_EXPENSE, -wages_accrued, closed_tick, &"WorkDayActivity"),
			JournalEntry.make(payable_account, wages_accrued, closed_tick, &"WorkDayActivity"),
		]
		fb_employer.commit_transaction(wage_tx)

	# Worker SkillsBook — one daily entry per skill.
	if farming_xp_earned > 0.0:
		var sb: SkillsBook = worker.accounts.skills()
		if sb != null:
			sb.write_entry(JournalEntry.make(&"farming", farming_xp_earned, closed_tick, &"WorkDayActivity"))

	# Worker VitalsBook — depletion entries.
	var vb: VitalsBook = worker.accounts.vitals()
	if vb != null:
		if calories_burned > 0.0:
			vb.write_entry(JournalEntry.make(&"hunger", -calories_burned, closed_tick, &"WorkDayActivity"))
		if fatigue_incurred > 0.0:
			vb.write_entry(JournalEntry.make(&"fatigue", -fatigue_incurred, closed_tick, &"WorkDayActivity"))

	print("    %s WorkDayActivity closed — slots=%d grain=%.0f wages_accrued=%.2f" %
		[worker.actor_id, slots_worked, grain_produced_today, wages_accrued])

	# Transient children have already pushed deltas; release them.
	child_activities.clear()
	return true
