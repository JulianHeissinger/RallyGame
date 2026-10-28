class_name ItemDef
extends Resource
## One item type as data. New items are new `.tres` files; `ItemManager` needs no change.

enum Kind { PASSIVE, ACTIVE }
enum Mount { ROOF, FRONT_BUMPER, REAR, TRUNK }
enum Activation { NONE, BUTTON, TRIGGER }

@export var id := ""
@export var name := ""
@export_multiline var description := ""
## Passive items stack without limit; active items take one mount slot.
@export var kind := Kind.PASSIVE
## Strong bonus with a permanent drawback, marked when offered.
@export var cursed := false
## Applied once per owned copy while the condition is met.
@export var modifiers: Array[StatModifier] = []
## Slot of an active item. Ignored for passive items.
@export var mount := Mount.ROOF
@export var activation := Activation.NONE
## Event that fires a TRIGGER item, e.g. "gear_shift".
@export var trigger_event := ""
## Seconds before a mounted item can fire again.
@export var cooldown := 0.0
## Part name or part group (e.g. "brake") that must be broken for the item to work. Any broken
## part of the group meets it. Empty: always on.
@export var condition_broken := ""
@export var effect: ItemEffect
