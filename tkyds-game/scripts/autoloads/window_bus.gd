extends Node

signal labor_market_opened
signal labor_market_closed
signal work_window_opened
signal work_window_closed
signal wholesale_market_opened
signal wholesale_market_closed
signal retail_market_opened
signal retail_market_closed
signal merchant_restock
signal wages_due
signal weekly_books_close

func open_labor_market() -> void:
	print("  [Bus] open_labor_market")
	labor_market_opened.emit()

func close_labor_market() -> void:
	print("  [Bus] close_labor_market")
	labor_market_closed.emit()

func open_work_window() -> void:
	print("  [Bus] open_work_window")
	work_window_opened.emit()

func close_work_window() -> void:
	print("  [Bus] close_work_window")
	work_window_closed.emit()

func open_wholesale_market() -> void:
	print("  [Bus] open_wholesale_market")
	wholesale_market_opened.emit()

func close_wholesale_market() -> void:
	print("  [Bus] close_wholesale_market")
	wholesale_market_closed.emit()

func open_retail_market() -> void:
	print("  [Bus] open_retail_market")
	retail_market_opened.emit()

func close_retail_market() -> void:
	print("  [Bus] close_retail_market")
	retail_market_closed.emit()

func fire_merchant_restock() -> void:
	print("  [Bus] merchant_restock")
	merchant_restock.emit()

func fire_wages_due() -> void:
	print("  [Bus] wages_due")
	wages_due.emit()

func fire_weekly_books_close() -> void:
	print("  [Bus] weekly_books_close")
	weekly_books_close.emit()
