class_name FarmingDayActivity
extends Activity

# Persistent — the smallest persistent unit of farming work. Books are written
# atomically at on_close from accumulators populated by transient
# FarmingSlotActivity children.
#
# `good_id` and `skill_id` are set by the WorkPattern resource on the
# LandPlot — same class drives any field-crop work pattern; sibling classes
# (BlacksmithDayActivity, etc.) cover non-farming work.

# Set at construction.
var worker: Actor
var employer: Actor
var contract: LaborContract
@export var good_id: StringName = &"grain"
@export var skill_id: StringName = &"farming"

# Accumulators — incremented by FarmingSlotActivity children at slot close.
@export var slots_worked: int = 0
@export var output_produced_today: float = 0.0
@export var skill_xp_earned: float = 0.0
@export var calories_burned: float = 0.0
@export var fatigue_incurred: float = 0.0
@export var wages_accrued: float = 0.0

func _init() -> void:
	activity_type = &"FarmingDayActivity"

func on_close() -> bool:
	if employer == null or worker == null:
		push_error("FarmingDayActivity.on_close: missing participants")
		return false

	var fb_employer: FinancialBook = employer.accounts.financial()
	if fb_employer == null:
		push_error("FarmingDayActivity: employer has no FinancialBook")
		return false

	# Tx 1 — output accrual. Inventory:{good_id} (asset, debit-natural) up = -X;
	# Production_Output_Value (revenue, credit-natural) up = +X. Net = 0.
	if output_produced_today > 0.0:
		var inv_account := Accounts.inventory_account(good_id)
		var output_tx: Array[JournalEntry] = [
			JournalEntry.make(inv_account, -output_produced_today, closed_tick, activity_type),
			JournalEntry.make(Accounts.A_PRODUCTION_OUTPUT_VALUE, output_produced_today, closed_tick, activity_type),
		]
		fb_employer.commit_transaction(output_tx)

	# Tx 2 — wage accrual. Wages_Expense up = -X; Payable:{worker} up = +X.
	if wages_accrued > 0.0:
		var payable_account := Accounts.payable_account(worker.actor_id)
		var wage_tx: Array[JournalEntry] = [
			JournalEntry.make(Accounts.A_WAGES_EXPENSE, -wages_accrued, closed_tick, activity_type),
			JournalEntry.make(payable_account, wages_accrued, closed_tick, activity_type),
		]
		fb_employer.commit_transaction(wage_tx)

	# Worker SkillsBook — one daily entry per skill.
	if skill_xp_earned > 0.0:
		var sb: SkillsBook = worker.accounts.skills()
		if sb != null:
			sb.write_entry(JournalEntry.make(skill_id, skill_xp_earned, closed_tick, activity_type))

	# Worker VitalsBook — depletion entries.
	var vb: VitalsBook = worker.accounts.vitals()
	if vb != null:
		if calories_burned > 0.0:
			vb.write_entry(JournalEntry.make(&"hunger", -calories_burned, closed_tick, activity_type))
		if fatigue_incurred > 0.0:
			vb.write_entry(JournalEntry.make(&"fatigue", -fatigue_incurred, closed_tick, activity_type))

	print("    %s FarmingDayActivity closed — slots=%d %s=%.0f wages_accrued=%.2f" %
		[worker.actor_id, slots_worked, good_id, output_produced_today, wages_accrued])

	# Transient children have already pushed deltas; release them.
	child_activities.clear()
	return true
