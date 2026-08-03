class_name SandboxCatalog
extends RefCounted

# The example action set — all content, no machinery. This file is the
# template for authoring new behavior: every option is built with
# ActionOption's builder so it reads as a stanza (place, appeal, gate,
# effect), and nothing in behavior/ knows any of these four exist.

static func build() -> Array[ActionOption]:
	var options: Array[ActionOption] = []

	# The eligibility example: a possession gate, authored as data. Without
	# coin, this option simply isn't offered — no special-case in the brain.
	# Also gated by THREATENED, same as every non-crisis option below: the
	# safety interrupt is expressed entirely as data predicates, not as a
	# priority check anywhere in the brain.
	options.append(
		ActionOption.make(&"eat_at_inn", "eating at the inn", &"inn", 2.0)
			.only_if(func(store: StatStore, actor: Actor) -> bool:
				var has_coin: bool = int(store.get_primary(actor, Stat.COIN)) >= SandboxTune.MEAL_PRICE
				var calm: bool = not bool(store.get_derived(actor, Stat.THREATENED))
				return has_coin and calm)
			.scored_by(func(store: StatStore, actor: Actor) -> float:
				# Quadratic — urgency compounds as hunger climbs, rather than
				# growing appeal in a straight line. The curve example.
				var hunger: float = store.get_primary(actor, Stat.HUNGER)
				return SandboxTune.W_EAT * pow(hunger / SandboxTune.HUNGER_MAX, 2.0))
			.then(func(store: StatStore, actor: Actor) -> void:
				# Sandbox sinks the coin here; the real sim conserves money by
				# routing it through a keeper actor instead of deleting it.
				var coin: int = store.get_primary(actor, Stat.COIN)
				store.write_primary(actor, Stat.COIN, coin - SandboxTune.MEAL_PRICE)
				var hunger: float = store.get_primary(actor, Stat.HUNGER)
				store.write_primary(actor, Stat.HUNGER, maxf(0.0, hunger - SandboxTune.MEAL_RELIEVES_HUNGER)))
	)

	options.append(
		ActionOption.make(&"work_field", "working the field", &"field", 3.0)
			.only_if(func(store: StatStore, actor: Actor) -> bool:
				return not bool(store.get_derived(actor, Stat.THREATENED)))
			.scored_by(func(store: StatStore, actor: Actor) -> float:
				# The derived-stat-inside-scoring example: VIGOR folds energy
				# and hunger together, so a wrung-out actor stops chasing work
				# even while coin is still tight.
				var coin: int = store.get_primary(actor, Stat.COIN)
				var vigor: float = store.get_derived(actor, Stat.VIGOR)
				return SandboxTune.W_WORK * clampf(1.0 - coin / SandboxTune.COIN_COMFORT, 0.0, 1.0) * vigor)
			.then(func(store: StatStore, actor: Actor) -> void:
				var coin: int = store.get_primary(actor, Stat.COIN)
				store.write_primary(actor, Stat.COIN, coin + SandboxTune.WAGE)
				var energy: float = store.get_primary(actor, Stat.ENERGY)
				store.write_primary(actor, Stat.ENERGY, maxf(0.0, energy - SandboxTune.WORK_DRAINS_ENERGY)))
	)

	options.append(
		ActionOption.make(&"rest_home", "resting at home", &"home", 2.5)
			.only_if(func(store: StatStore, actor: Actor) -> bool:
				return not bool(store.get_derived(actor, Stat.THREATENED)))
			.scored_by(func(store: StatStore, actor: Actor) -> float:
				var energy: float = store.get_primary(actor, Stat.ENERGY)
				return SandboxTune.W_REST * pow(1.0 - energy / SandboxTune.ENERGY_MAX, 2.0))
			.then(func(store: StatStore, actor: Actor) -> void:
				var energy: float = store.get_primary(actor, Stat.ENERGY)
				store.write_primary(actor, Stat.ENERGY, minf(SandboxTune.ENERGY_MAX, energy + SandboxTune.REST_RESTORES_ENERGY)))
	)

	# The floor every real need must outbid — "everything outbids, nothing
	# overrides" in miniature. No effect: just somewhere to be. Still gated by
	# THREATENED like the other non-crisis options, so a scared actor has
	# nothing to fall back to except the safety response below.
	options.append(
		ActionOption.make(&"pass_time_well", "passing the time at the well", &"well", 1.5)
			.only_if(func(store: StatStore, actor: Actor) -> bool:
				return not bool(store.get_derived(actor, Stat.THREATENED)))
			.scored_by(func(_store: StatStore, _actor: Actor) -> float:
				return SandboxTune.IDLE_APPEAL)
	)

	# The safety interrupt. Deliberately carries no only_if — this is the
	# protected-set member (PRD: survival/direct-interpersonal actions are
	# never identity- or eligibility-pruned) — so it always competes, but its
	# appeal is ~0 while calm and dominant once FEAR clears THREAT_THRESHOLD.
	# "Stays until safe" needs no special machinery: each cycle it finishes,
	# the actor re-chooses, and while still threatened everything else is
	# ineligible, so shelter just gets picked again.
	options.append(
		ActionOption.make(&"shelter_home", "sheltering at home", &"home", SandboxTune.SHELTER_DURATION)
			.scored_by(func(store: StatStore, actor: Actor) -> float:
				var fear: float = store.get_primary(actor, Stat.FEAR)
				return SandboxTune.W_SHELTER * pow(fear / SandboxTune.FEAR_MAX, 2.0))
	)

	# The passerby greeting. place == &"" is the "wherever I already am"
	# sentinel — see _build_goal — so choosing this never sends anyone
	# walking anywhere; it just briefly interrupts whatever they were doing
	# in place, same front-insert/resume path the fear interrupt uses. Gated
	# by NEARBY (written by SandboxWorld's proximity scan, not readable here
	# some other way — position lives outside the store on purpose) and by
	# GREET_COOLDOWN so two villagers lingering close by don't re-fire every
	# tick. Deliberately can't name who's nearby — see the eligibility
	# predicate's comment for why.
	options.append(
		ActionOption.make(&"greet_passerby", "nodding to someone passing by", &"", SandboxTune.GREET_DURATION)
			.only_if(func(store: StatStore, actor: Actor) -> bool:
				var nearby: bool = store.get_primary(actor, Stat.NEARBY)
				var cooldown: float = store.get_primary(actor, Stat.GREET_COOLDOWN)
				return nearby and cooldown <= 0.0)
			.scored_by(func(_store: StatStore, _actor: Actor) -> float:
				return SandboxTune.W_GREET)
			.then(func(store: StatStore, actor: Actor) -> void:
				store.write_primary(actor, Stat.GREET_COOLDOWN, SandboxTune.GREET_COOLDOWN_SECONDS))
	)

	return options
