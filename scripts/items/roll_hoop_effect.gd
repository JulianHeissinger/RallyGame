class_name RollHoopEffect
extends ItemEffect
## Cancels the rollover penalty. `Car` passes the penalty in a mutable dictionary before it
## emits `rolled_over`.


func on_activate(_car: Node, data: Variant) -> bool:
	data["penalty"] = 0.0
	return true
