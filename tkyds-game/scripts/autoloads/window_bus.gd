extends Node

# WindowBus carries broadcast events with multiple unrelated listeners. v0
# keeps the daily work-window broadcasts (drives WorkingInterest's lifecycle)
# and drops all coordination signals (wages_due, weekly_books_close, market
# open/close) — those moved into structural orchestrator calls per the
# Phase 2.5 directive Section 7.2.

signal work_window_opened
signal work_window_closed

func open_work_window() -> void:
	print("  [Bus] open_work_window")
	work_window_opened.emit()

func close_work_window() -> void:
	print("  [Bus] close_work_window")
	work_window_closed.emit()
