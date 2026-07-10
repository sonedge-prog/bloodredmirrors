extends Node

signal task_completed(task_id: String)
signal task_progress(task_id: String, current: int, total: int)
signal all_tasks_completed

var tasks := {}
var task_order := []

func add_task(task_id: String, label: String):
	tasks[task_id] = { "label": label, "done": false, "progress": 0, "total": 1 }
	task_order.append(task_id)

func add_progress_task(task_id: String, label: String, total: int):
	tasks[task_id] = { "label": label, "done": false, "progress": 0, "total": total }
	task_order.append(task_id)

func complete_task(task_id: String):
	if not tasks.has(task_id) or tasks[task_id]["done"]:
		return
	var task = tasks[task_id]
	task["progress"] += 1

	if task["progress"] >= task["total"]:
		task["done"] = true
		task_completed.emit(task_id)
	else:
		task_progress.emit(task_id, task["progress"], task["total"])

	if _all_done():
		all_tasks_completed.emit()

func _all_done() -> bool:
	for task_id in tasks:
		if not tasks[task_id]["done"]:
			return false
	return true

func get_display_lines() -> Array:
	var lines = []
	for task_id in task_order:
		var task = tasks[task_id]
		if task["total"] > 1:
			var prefix = "[x] " if task["done"] else "[ ] "
			lines.append(prefix + task["label"] + " (%d/%d)" % [task["progress"], task["total"]])
		else:
			var prefix = "[x] " if task["done"] else "[ ] "
			lines.append(prefix + task["label"])
	return lines
