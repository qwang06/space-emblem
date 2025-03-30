extends Node

enum Faction { PLAYER, ENEMY, NEUTRAL }

@export var faction: Faction = Faction.PLAYER

func is_enemy_to(other_faction: int) -> bool:
    return faction != other_faction and faction != Faction.NEUTRAL and other_faction != Faction.NEUTRAL
