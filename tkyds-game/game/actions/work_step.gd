class_name WorkStep
extends ActionStep

# The working itself. Like every step it holds no progress — no furrow counter,
# no elapsed anything. Which plot he is working is re-derived every tick from
# the same get_best_candidate the gate and score used, and who holds the plot
# lives on the plot.

func advance(person: Person, _hours: float) -> bool:
	var work := get_parent() as WorkTheField
	if work == null:
		push_warning("a WorkStep's parent must be a WorkTheField — it has no idea what to work")
		return true
	var station := work.get_best_candidate(person)
	if station == null:
		# Gone between deciding and doing. The serial loop means nothing runs
		# in between today, so this cannot happen yet — kept as a quiet no-op
		# rather than an assumption the day the loop stops being serial.
		return true
	# RENEWED BY USE — claim() on EVERY tick this advances, not once at the
	# start. He is present and it is already his, so the call re-stamps today
	# and dawn passes under him; nothing else keeps a claim alive. claim() is
	# also the presence check: a man not standing at the plot's place gets
	# false, and rung 4's answer to that false is "walk there first".
	if not station.claim(person):
		return false
	# The work has nothing to move yet — grain arrives with inventory at rung 5
	# and work-that-takes-time at 9a. Holding the plot IS this rung's work.
	return false


func describe(_person: Person) -> String:
	return "in the furrows"
