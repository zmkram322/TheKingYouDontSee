extends Node

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

	var worker_1 := _make_worker(&"worker_1", labor_market, retail_market)
	region.add_child(worker_1)
	region.actors.append(worker_1)

	var worker_2 := _make_worker(&"worker_2", labor_market, retail_market)
	region.add_child(worker_2)
	region.actors.append(worker_2)

	var land_owner := _make_land_owner(&"land_owner_1", plot, labor_market, wholesale_market, retail_market)
	region.add_child(land_owner)
	region.actors.append(land_owner)

	var merchant := _make_merchant(&"merchant_1", wholesale_market, retail_market)
	region.add_child(merchant)
	region.actors.append(merchant)

	print("[Bootstrap] complete — actors: %s" % str(region.actors.map(func(a): return a.actor_id)))
	print("[Bootstrap] starting clock\n")

func _make_worker(id: StringName, labor_market: LaborMarket, retail_market: RetailMarket) -> Actor:
	var w := Actor.new()
	w.name = String(id)
	w.actor_id = id
	w.accounts = Accounts.new()
	var working := WorkingInterest.new()
	working.labor_market = labor_market
	var grain := GrainInterest.new()
	grain.retail_market = retail_market
	w.interests = [working, grain]
	return w

func _make_land_owner(id: StringName, plot: LandPlot, labor_market: LaborMarket, wholesale_market: WholesaleMarket, retail_market: RetailMarket) -> Actor:
	var lo := Actor.new()
	lo.name = String(id)
	lo.actor_id = id
	lo.accounts = Accounts.new()
	lo.accounts.coin = 200
	lo.accounts.owned_resources = [plot]
	var production := ProductionInterest.new()
	production.plot = plot
	production.wholesale_market = wholesale_market
	var employer := EmployerInterest.new()
	employer.labor_market = labor_market
	employer.desired_workers = 2
	var grain := GrainInterest.new()
	grain.retail_market = retail_market
	lo.interests = [production, employer, grain]
	return lo

func _make_merchant(id: StringName, wholesale_market: WholesaleMarket, retail_market: RetailMarket) -> Actor:
	var m := Actor.new()
	m.name = String(id)
	m.actor_id = id
	m.accounts = Accounts.new()
	m.accounts.coin = 100
	var mercantile := MercantileInterest.new()
	mercantile.wholesale_market = wholesale_market
	mercantile.retail_market = retail_market
	mercantile.good_id = &"grain"
	mercantile.target_inventory = 60
	var grain := GrainInterest.new()
	grain.retail_market = retail_market
	m.interests = [mercantile, grain]
	return m
