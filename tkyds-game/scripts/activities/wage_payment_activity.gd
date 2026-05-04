class_name WagePaymentActivity
extends Activity

# Persistent. Settles one outstanding Payable:{worker} on the employer's books
# by transferring cash and clearing the payable. Mirror entry on the worker's
# books (Cash ↑, Wages_Income credited).

var employer: Actor
var worker: Actor
@export var amount: float = 0.0      # coin to transfer

func _init() -> void:
	activity_type = &"WagePaymentActivity"

func on_close() -> bool:
	if employer == null or worker == null or amount <= 0.0:
		return false
	var fb_employer: FinancialBook = employer.accounts.financial()
	var fb_worker: FinancialBook = worker.accounts.financial()
	if fb_employer == null or fb_worker == null:
		push_error("WagePaymentActivity: missing FinancialBook")
		return false

	if employer.accounts.cash() < amount:
		push_error("WagePaymentActivity: %s lacks %.2f coin to pay %s (has %.2f)" %
			[employer.actor_id, amount, worker.actor_id, employer.accounts.cash()])
		return false

	var payable_acct := Accounts.payable_account(worker.actor_id)

	# Employer side: clear Payable (liability down = -X), drain Cash (asset
	# down = credit = +X). Net = 0.
	var emp_tx: Array[JournalEntry] = [
		JournalEntry.make(payable_acct, -amount, closed_tick, &"WagePaymentActivity"),
		JournalEntry.make(Accounts.A_CASH, amount, closed_tick, &"WagePaymentActivity"),
	]
	if not fb_employer.commit_transaction(emp_tx):
		return false

	# Worker side: Cash up (asset increase = debit = -X), Wages_Income up
	# (revenue = credit = +X). Net = 0.
	var work_tx: Array[JournalEntry] = [
		JournalEntry.make(Accounts.A_CASH, -amount, closed_tick, &"WagePaymentActivity"),
		JournalEntry.make(Accounts.A_WAGES_INCOME, amount, closed_tick, &"WagePaymentActivity"),
	]
	if not fb_worker.commit_transaction(work_tx):
		return false

	print("      paid %s: %.2f coin (clears Payable:%s on %s)" %
		[worker.actor_id, amount, worker.actor_id, employer.actor_id])
	return true
