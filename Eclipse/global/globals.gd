extends Node

const MAX_DAYS: int = 10

enum SIMULATION_BATTLE_RESULT {
	NO_DEPLOYED_MINION,
	MINION_LOOK_AROUND,
	MINION_WIN,
	MINION_LOST,
	BATTLE_TRIGGER
 }

var current_day: int = 0

func next_day() -> void:
	current_day += 1

func new_game() -> void:
	current_day = 0
