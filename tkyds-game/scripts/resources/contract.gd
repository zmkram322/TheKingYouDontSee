class_name Contract
extends Resource

enum Status { ACTIVE, EXPIRED, BREACHED }

@export var status: Status = Status.ACTIVE
