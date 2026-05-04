class_name WeeklyBurstActivity
extends Activity

# Persistent root activity for the weekly market burst. Holds the burst as an
# audit-trail anchor — child activities (WagePayment, WholesaleSale,
# RetailPurchase, LaborContract) are not declared as child_activities here in
# v0 since they live on individual actors' books and accounts.activities.
# Phase 3+ may collect them under the burst for "what happened this week"
# population queries.

@export var tick: int = 0

func _init() -> void:
	activity_type = &"WeeklyBurstActivity"
