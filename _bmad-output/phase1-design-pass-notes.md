**i will layer my comments into the printed output using <<my notes>>**

[SimClock] ready — seconds_per_slot=0.100 max_days=14
[WindowOrchestrator] ready — listening to SimClock.daily_tick and SimClock.weekly_tick
[Bootstrap] starting v0 prototype — 1 Region, 4 Actors, 3 Markets
[Wire] LaborMarket.clear ← WindowBus.labor_market_closed
[Wire] WholesaleMarket.clear ← WindowBus.wholesale_market_closed
[Wire] RetailMarket.clear ← WindowBus.retail_market_closed
[Wire] worker_1.tick_each_slot ← SimClock.daily_tick
[Wire] worker_1.seek_work ← WindowBus.labor_market_opened
[Wire] worker_1.begin_working ← WindowBus.work_window_opened
[Wire] worker_1.deliver_grain_and_bill ← WindowBus.work_window_closed
[Wire] worker_2.tick_each_slot ← SimClock.daily_tick
[Wire] worker_2.seek_work ← WindowBus.labor_market_opened
[Wire] worker_2.begin_working ← WindowBus.work_window_opened
[Wire] worker_2.deliver_grain_and_bill ← WindowBus.work_window_closed
[Wire] land_owner_1.tick_each_slot ← SimClock.daily_tick
[Wire] land_owner_1.post_open_jobs ← WindowBus.labor_market_opened
[Wire] land_owner_1.send_supply_to_wholesale ← WindowBus.work_window_closed
[Wire] land_owner_1.pay_outstanding_wages ← WindowBus.wages_due
[Wire] merchant_1.tick_each_slot ← SimClock.daily_tick
[Wire] merchant_1.weekly_restock ← WindowBus.merchant_restock
[Wire] merchant_1.ship_to_retail ← WindowBus.wholesale_market_closed
[Bootstrap] complete — actors: [&"worker_1", &"worker_2", &"land_owner_1", &"merchant_1"]
[Bootstrap] starting clock


[Day 1 EARLY_MORNING]

[Day 1 MID_MORNING]
  [Bus] open_work_window

[Day 1 LATE_MORNING]

[Day 1 EARLY_AFTERNOON]

[Day 1 LATE_AFTERNOON]

[Day 1 EARLY_EVENING]
  [Bus] close_work_window
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 1 LATE_EVENING]
  [Bus] open_labor_market
    worker_1.WorkingInterest.look_for_work() — offering self to LaborMarket
    LaborMarket.take_supply(worker_1, 1)
    worker_2.WorkingInterest.look_for_work() — offering self to LaborMarket
    LaborMarket.take_supply(worker_2, 1)
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=2 open_positions=2 → match 2; write LaborContract(s)
      contract: worker_1 ↔ land_owner_1 @ wage=1/slot, week=1
      contract: worker_2 ↔ land_owner_1 @ wage=1/slot, week=1
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=2)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=2)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=2)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=2)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 1 MIDDLE_OF_NIGHT]

[Day 2 EARLY_MORNING]

[Day 2 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 2 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 2 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 2 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 2 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 2 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=4)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=4)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=4)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=4)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 2 MIDDLE_OF_NIGHT]

[Day 3 EARLY_MORNING]

[Day 3 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 3 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 3 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 3 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 3 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 3 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=6)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=6)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=6)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=6)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 3 MIDDLE_OF_NIGHT]

[Day 4 EARLY_MORNING]

[Day 4 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 4 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 4 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 4 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 4 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 4 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=8)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=8)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=8)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=8)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 4 MIDDLE_OF_NIGHT]

[Day 5 EARLY_MORNING]

[Day 5 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 5 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 5 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 5 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 5 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 5 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=10)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=10)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=10)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=10)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 5 MIDDLE_OF_NIGHT]

[Day 6 EARLY_MORNING]

[Day 6 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 6 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 6 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 6 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 6 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 6 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=12)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=12)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=12)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=12)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 6 MIDDLE_OF_NIGHT]

[Day 7 EARLY_MORNING]
[SimClock] weekly_tick (day 7)
  [Orchestrator] weekly burst begins
  [Bus] merchant_restock
    merchant_1.MercantileInterest.place_buy_order_at_wholesale() — emit demand for 60 grain
    WholesaleMarketGrain.take_demand(merchant_1, 60)
  [Bus] open_wholesale_market
  [Bus] close_wholesale_market
    WholesaleMarket.clear(grain) — transfer grain owner→merchant at flat price; coin reverse
    WholesaleMarketGrain.reset_pools()
    merchant_1.MercantileInterest.send_inventory_to_retail() — emit grain supply to RetailMarket
    RetailMarketGrain.take_supply(merchant_1, 0)
  [Bus] open_retail_market
  [Bus] close_retail_market
    RetailMarket.clear(grain) — transfer grain merchant→consumers at flat price; coin reverse; consumers' outstanding_demand decremented
    RetailMarketGrain.reset_pools()
  [Bus] wages_due
    land_owner_1.pay_outstanding_wages() — walk 0 payable(s); decrement coin; pay each worker; clear payables
  [Orchestrator] weekly burst ends

[Day 7 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 7 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 7 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 7 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 7 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 7 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=14)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=14)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=14)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=14)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 7 MIDDLE_OF_NIGHT]

[Day 8 EARLY_MORNING]

[Day 8 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 8 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 8 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 8 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 8 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 8 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=16)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=16)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=16)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=16)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 8 MIDDLE_OF_NIGHT]

[Day 9 EARLY_MORNING]

[Day 9 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 9 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 9 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 9 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 9 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 9 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=18)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=18)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=18)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=18)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 9 MIDDLE_OF_NIGHT]

[Day 10 EARLY_MORNING]

[Day 10 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 10 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 10 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 10 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 10 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 10 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=20)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=20)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=20)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=20)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 10 MIDDLE_OF_NIGHT]

[Day 11 EARLY_MORNING]

[Day 11 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 11 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 11 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 11 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 11 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 11 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=22)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=22)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=22)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=22)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 11 MIDDLE_OF_NIGHT]

[Day 12 EARLY_MORNING]

[Day 12 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 12 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 12 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 12 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 12 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)
  ERROR: res://scripts/sim/routine.gd:11 - Parse Error: Identifier "E" not declared in the current scope.
  ERROR: modules/gdscript/gdscript.cpp:3022 - Failed to load script "res://scripts/sim/routine.gd" with error "Parse error".
  ERROR: res://scripts/sim/routine.gd:11 - Parse Error: Identifier "E" not declared in the current scope.

[Day 12 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=24)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=24)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=24)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=24)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 12 MIDDLE_OF_NIGHT]

[Day 13 EARLY_MORNING]

[Day 13 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 13 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 13 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 13 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 13 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 13 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=26)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=26)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=26)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=26)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 13 MIDDLE_OF_NIGHT]

[Day 14 EARLY_MORNING]
[SimClock] weekly_tick (day 14)
  [Orchestrator] weekly burst begins
  [Bus] merchant_restock
    merchant_1.MercantileInterest.place_buy_order_at_wholesale() — emit demand for 60 grain
    WholesaleMarketGrain.take_demand(merchant_1, 60)
  [Bus] open_wholesale_market
  [Bus] close_wholesale_market
    WholesaleMarket.clear(grain) — transfer grain owner→merchant at flat price; coin reverse
    WholesaleMarketGrain.reset_pools()
    merchant_1.MercantileInterest.send_inventory_to_retail() — emit grain supply to RetailMarket
    RetailMarketGrain.take_supply(merchant_1, 0)
  [Bus] open_retail_market
  [Bus] close_retail_market
    RetailMarket.clear(grain) — transfer grain merchant→consumers at flat price; coin reverse; consumers' outstanding_demand decremented
    RetailMarketGrain.reset_pools()
  [Bus] wages_due
    land_owner_1.pay_outstanding_wages() — walk 0 payable(s); decrement coin; pay each worker; clear payables
  [Orchestrator] weekly burst ends

[Day 14 MID_MORNING]
  [Bus] open_work_window
    worker_1.work_state → WORKING
    worker_2.work_state → WORKING
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 14 LATE_MORNING]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 14 EARLY_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 14 LATE_AFTERNOON]
    worker_1.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory
    worker_2.WorkingInterest.do_one_work_slot() — +1 grain to worker inventory

[Day 14 EARLY_EVENING]
  [Bus] close_work_window
    worker_1.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_1.work_state → EMPLOYED_NOT_WORKING
    worker_2.WorkingInterest.hand_grain_to_owner_and_bill() — transfer grain to LandOwner; emit Payable (wages)
    worker_2.work_state → EMPLOYED_NOT_WORKING
    land_owner_1.ProductionInterest.send_grain_to_wholesale() — emit grain supply
    WholesaleMarketGrain.take_supply(land_owner_1, 0)

[Day 14 LATE_EVENING]
  [Bus] open_labor_market
    land_owner_1.ProductionInterest.post_jobs() — open_positions=2
    LaborMarket.take_demand(land_owner_1, 2)
  [Bus] close_labor_market
    LaborMarket.clear() — available_workers=0 open_positions=2 → match 0; write LaborContract(s)
    LaborMarket.reset_pools()
    worker_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=28)
    RetailMarketGrain.take_demand(worker_1, 2)
    worker_2.GrainInterest.place_grain_order() — +2 grain demand (outstanding=28)
    RetailMarketGrain.take_demand(worker_2, 2)
    land_owner_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=28)
    RetailMarketGrain.take_demand(land_owner_1, 2)
    merchant_1.GrainInterest.place_grain_order() — +2 grain demand (outstanding=28)
    RetailMarketGrain.take_demand(merchant_1, 2)

[Day 14 MIDDLE_OF_NIGHT]

[SimClock] reached max_days=14, stopping
