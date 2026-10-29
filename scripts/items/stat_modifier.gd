class_name StatModifier
extends Resource
## One stat change per item copy. Copies stack: `additive` adds up, `multiplier` multiplies
## (two ×1.1 copies give ×1.21).

@export var stat := ""
@export var additive := 0.0
@export var multiplier := 1.0
