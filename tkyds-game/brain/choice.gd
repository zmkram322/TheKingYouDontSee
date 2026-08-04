class_name Choice
extends Step

# The seam where doing turns back into choosing. A Choice is a Step like any
# other, but instead of doing work itself it offers a set of Actions, ranks
# them, and gives the winner the time — so a decision can sit at any depth
# inside a plan, not only at the top.
#
# Its options are produced by a generator rather than held as a list, because
# the interesting cases aren't known when the plan is written: which inn, which
# customer, which field. A fixed set of alternatives is just a generator that
# returns the same list every time, so there's one kind of Choice, not two.
#
# The generator is the coarse pass — a world query, and nothing more. Resist
# putting judgment in it: anything it leaves out has effectively scored minus
# infinity and can never be outbid, no matter how desperate the subject gets.
# Narrow for cost, gate with `eligible`, discriminate with `score`.
#
# Re-derived like everything else: the ranking is redone every tick, so if the
# chosen inn closes mid-walk the next tick simply picks another and the
# character carries on from where they stand. Nothing is torn down because
# nothing was built.

var options: Callable   # (who) -> Array[Action]


func _init(new_options: Callable) -> void:
	options = new_options


# Done when what it would pick is itself done. Nothing to pick is NOT done —
# see is_possible. That distinction is the whole reason this class has three
# answers instead of two: a character with every inn shut has not finished
# eating, and must not be recorded as having done so.
#
# Asking what it would pick is what makes this a decision point rather than a
# holding pen. Without it a character who had finished eating would still be
# offered the inn — it's open, she can afford it — and would stand there being
# perpetually about to eat.
func is_satisfied(who) -> bool:
	var winner := _pick(who)
	if winner == null:
		return false
	return winner.body.is_satisfied(who)


# Nothing to pick means thwarted: every option was either never offered or
# gated shut. The work is real and still wanted — there is simply no way to get
# on with it from here. Whoever is driving must abandon it without recording it
# as done, and try again when the world has changed.
func is_possible(who) -> bool:
	var winner := _pick(who)
	if winner == null:
		return false
	return winner.body.is_possible(who)


func advance(who, delta: float) -> bool:
	var winner := _pick(who)
	if winner == null:
		return false
	return winner.body.advance(who, delta)


func describe(who) -> String:
	var winner := _pick(who)
	if winner == null:
		return "(nothing to choose from)"
	var inner := winner.body.describe(who)
	return winner.label if inner.is_empty() else "%s — %s" % [winner.label, inner]


# Borrows the subject's own brain purely as a scorer. Note this is the plain
# ranking path, not decide_action() — a nested decision must never disturb what
# the character is pursuing at the top level. It answers "which of these",
# not "what should I be doing with my life".
func _pick(who) -> Action:
	return who.brain.choose_action(who, options.call(who))
