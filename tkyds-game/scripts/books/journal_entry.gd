class_name JournalEntry
extends Resource

@export var account: StringName = &""
@export var amount: float = 0.0      # positive = credit, negative = debit
@export var tick: int = 0
@export var activity_ref: StringName = &""
@export var note: StringName = &""

static func make(account_: StringName, amount_: float, tick_: int, activity_ref_: StringName = &"", note_: StringName = &"") -> JournalEntry:
	var e := JournalEntry.new()
	e.account = account_
	e.amount = amount_
	e.tick = tick_
	e.activity_ref = activity_ref_
	e.note = note_
	return e
