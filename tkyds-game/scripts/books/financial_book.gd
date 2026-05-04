class_name FinancialBook
extends Book

# Strict double-entry: each Tx must net to zero (sum of credits == sum of debits).
# Returns true on success, false (with push_error) on imbalance — no partial writes.
const EPSILON := 0.0001

func commit_transaction(entries_in_tx: Array[JournalEntry]) -> bool:
	var net: float = 0.0
	for e in entries_in_tx:
		net += e.amount
	if abs(net) > EPSILON:
		push_error("FinancialBook.commit_transaction: unbalanced Tx, net=%.4f, entries=%d" % [net, entries_in_tx.size()])
		return false
	for e in entries_in_tx:
		journal.append(e)
	return true
