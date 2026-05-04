class_name Book
extends Resource

# === Sign convention (FinancialBook) ===
# Strict double-entry, credit-positive: amount > 0 = credit, amount < 0 = debit.
# Each Tx must net to zero across the pair.
#
# Per-category: which side of the entry corresponds to a balance INCREASE on
# that account?
#   - Asset accounts (Cash, Inventory:*, Receivable:*): increase = debit (-X)
#   - Expense accounts (Wages_Expense, COGS, Lord_Tax_Expense): increase = debit (-X)
#   - Liability accounts (Payable:*): increase = credit (+X)
#   - Revenue accounts (Wages_Income, Sales_Revenue, Production_Output_Value): increase = credit (+X)
#   - Equity accounts (Owner_Equity): increase = credit (+X)
#
# `balance(account)` returns the raw sum of entries — which is the natural
# reading for credit-natural accounts (liability/revenue/equity) and the
# negated reading for debit-natural accounts (asset/expense). Callers needing
# natural reads on assets use the Accounts helpers (`cash()`, `inventory_of()`).
#
# SkillsBook and VitalsBook do NOT enforce balance; entries are bare deltas.
# - SkillsBook: positive XP credit per skill (read natural).
# - VitalsBook: negative entry = depletion, positive entry = replenishment;
#   `balance(vital)` = current vital level.

@export var journal: Array[JournalEntry] = []

func write_entry(entry: JournalEntry) -> void:
	journal.append(entry)

# Closed-interval period query. Pass -1 for either bound to mean "unbounded".
func balance(account: StringName, period_start: int = -1, period_end: int = -1) -> float:
	var total: float = 0.0
	for e in journal:
		if e.account != account:
			continue
		if period_start >= 0 and e.tick < period_start:
			continue
		if period_end >= 0 and e.tick > period_end:
			continue
		total += e.amount
	return total

func entries(account: StringName, period_start: int = -1, period_end: int = -1) -> Array[JournalEntry]:
	var out: Array[JournalEntry] = []
	for e in journal:
		if e.account != account:
			continue
		if period_start >= 0 and e.tick < period_start:
			continue
		if period_end >= 0 and e.tick > period_end:
			continue
		out.append(e)
	return out

# All entries in a window, regardless of account — for population aggregations
# and audit views. v0 ships the per-actor variant; cross-actor wrapping lives
# in the v0.5 Population layer.
func entries_in_period(period_start: int = -1, period_end: int = -1) -> Array[JournalEntry]:
	var out: Array[JournalEntry] = []
	for e in journal:
		if period_start >= 0 and e.tick < period_start:
			continue
		if period_end >= 0 and e.tick > period_end:
			continue
		out.append(e)
	return out
