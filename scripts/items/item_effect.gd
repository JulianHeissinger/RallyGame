class_name ItemEffect
extends Resource
## Behaviour of an item beyond stat modifiers. Each new behaviour is one subclass; items that
## reuse existing effects and modifiers are pure `.tres` data.


## Called when a mounted item fires, by button or by its trigger event.
func on_activate(_car: Node) -> void:
	pass


## Called for every car or stage event while the item's condition is met.
func on_event(_car: Node, _event: String, _data: Variant) -> void:
	pass
