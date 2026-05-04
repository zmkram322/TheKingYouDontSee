class_name LandPlot
extends ProductionResource

@export var size: float = 1.0
@export var producible_goods: Array[StringName] = [&"grain"]
@export var base_output_per_work_unit: float = 1.0

# The work pattern attached to this plot — drives which Activity subclasses
# WorkingInterest instantiates, what good is produced, which skill is gained.
# Multiple plots with different patterns coexist; each plot is the source of
# truth for the work that happens on it.
@export var work_pattern: WorkPattern
