extends Node

# Phase 2.5 v0 bootstrap. Constructs region + 3 markets + 4 actors. Each
# actor gets fresh per-category Books, plus an opening capitalization Tx
# (Cash debit / Owner_Equity credit) for actors with starting coin.
# Markets are populated with their registered_suppliers / registered_demanders
# so pull-on-open finds them.

func _ready() -> void:
	print("[Bootstrap] starting v0 prototype — 1 Region, 4 Actors, 3 Markets")

	var region := Region.new()
	region.region_id = &"region_1"
	region.name = "Region1"
	add_child(region)

	var labor_market := LaborMarket.new()
	labor_market.region = region
	labor_market.name = "LaborMarket"
	region.add_child(labor_market)
	region.labor_market = labor_market

	var wholesale_market := WholesaleMarket.new()
	wholesale_market.region = region
	wholesale_market.name = "WholesaleMarketGrain"
	region.add_child(wholesale_market)
	region.wholesale_markets[&"grain"] = wholesale_market

	var retail_market := RetailMarket.new()
	retail_market.region = region
	retail_market.name = "RetailMarketGrain"
	region.add_child(retail_market)
	region.retail_markets[&"grain"] = retail_market

	var plot := LandPlot.new()
	plot.resource_id = &"plot_1"
	plot.size = 1.0
	plot.producible_goods = [&"grain"]
	plot.base_output_per_work_unit = 1.0

	var worker_1 := _make_worker(&"worker_1")
	region.add_child(worker_1)
	region.actors.append(worker_1)

	var worker_2 := _make_worker(&"worker_2")
	region.add_child(worker_2)
	region.actors.append(worker_2)

	var land_owner := _make_land_owner(&"land_owner_1", plot, wholesale_market)
	region.add_child(land_owner)
	region.actors.append(land_owner)

	var merchant := _make_merchant(&"merchant_1", wholesale_market, retail_market)
	region.add_child(merchant)
	region.actors.append(merchant)

	# Opening capitalization — Cash up = -X (debit on debit-natural),
	# Owner_Equity up = +X (credit on credit-natural). Net = 0.
	_seed_cash(land_owner, 200.0)
	_seed_cash(merchant, 100.0)

	# Market registrations: pull-on-open polls these arrays.
	labor_market.register_supplier(worker_1)
	labor_market.register_supplier(worker_2)
	labor_market.register_demander(land_owner)

	wholesale_market.register_supplier(land_owner)
	wholesale_market.register_demander(merchant)

	retail_market.register_supplier(merchant)
	retail_market.register_demander(worker_1)
	retail_market.register_demander(worker_2)
	retail_market.register_demander(land_owner)
	retail_market.register_demander(merchant)

	WindowOrchestrator.bind_region(region)

	print("[Bootstrap] complete — actors: %s" % str(region.actors.map(func(a): return a.actor_id)))
	print("[Bootstrap] starting clock\n")

func _fresh_accounts() -> Accounts:
	var a := Accounts.new()
	a.books[&"financial"] = FinancialBook.new()
	a.books[&"skills"] = SkillsBook.new()
	a.books[&"vitals"] = VitalsBook.new()
	return a

func _seed_cash(actor: Actor, amount: float) -> void:
	if amount <= 0.0:
		return
	var fb: FinancialBook = actor.accounts.financial()
	var seed_tx: Array[JournalEntry] = [
		JournalEntry.make(Accounts.A_CASH, -amount, 0, &"OpeningBalance"),
		JournalEntry.make(Accounts.A_OWNER_EQUITY, amount, 0, &"OpeningBalance"),
	]
	fb.commit_transaction(seed_tx)

func _make_worker(id: StringName) -> Actor:
	var w := Actor.new()
	w.name = String(id)
	w.actor_id = id
	w.accounts = _fresh_accounts()
	var working := WorkingInterest.new()
	var grain := GrainInterest.new()
	w.interests = [working, grain]
	return w

func _make_land_owner(id: StringName, plot: LandPlot, wholesale_market: WholesaleMarket) -> Actor:
	var lo := Actor.new()
	lo.name = String(id)
	lo.actor_id = id
	lo.accounts = _fresh_accounts()
	lo.accounts.owned_resources = [plot]
	var production := ProductionInterest.new()
	production.plot = plot
	production.wholesale_market = wholesale_market
	var employer := EmployerInterest.new()
	employer.desired_workers = 2
	var grain := GrainInterest.new()
	lo.interests = [production, employer, grain]
	return lo

func _make_merchant(id: StringName, wholesale_market: WholesaleMarket, retail_market: RetailMarket) -> Actor:
	var m := Actor.new()
	m.name = String(id)
	m.actor_id = id
	m.accounts = _fresh_accounts()
	var mercantile := MercantileInterest.new()
	mercantile.wholesale_market = wholesale_market
	mercantile.retail_market = retail_market
	mercantile.good_id = &"grain"
	mercantile.target_inventory = 60
	var grain := GrainInterest.new()
	m.interests = [mercantile, grain]
	return m
