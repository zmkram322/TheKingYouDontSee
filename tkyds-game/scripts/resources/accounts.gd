class_name Accounts
extends Resource

@export var coin: int = 0
@export var inventory: Dictionary = {}
@export var owned_resources: Array[ProductionResource] = []
@export var contracts: Array[Contract] = []
@export var payables: Array[Payable] = []
@export var receivables: Array[Receivable] = []
