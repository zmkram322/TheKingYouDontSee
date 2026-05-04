class_name WorkPattern
extends Resource

# Bundles "what does work on this resource look like" — the activity classes
# to instantiate, the good produced, the skill exercised. Set on a LandPlot,
# Workshop, etc. New work patterns (blacksmithing, viniculture) are new .tres
# instances pointing at the matching Activity subclasses.

@export var pattern_id: StringName = &""
@export var slot_activity_script: Script
@export var day_activity_script: Script
@export var good_id: StringName = &""
@export var skill_id: StringName = &""
@export var job_category: StringName = &""

func create_slot_activity() -> Activity:
	if slot_activity_script == null:
		push_error("WorkPattern[%s]: no slot_activity_script" % pattern_id)
		return null
	return slot_activity_script.new() as Activity

func create_day_activity() -> Activity:
	if day_activity_script == null:
		push_error("WorkPattern[%s]: no day_activity_script" % pattern_id)
		return null
	return day_activity_script.new() as Activity
