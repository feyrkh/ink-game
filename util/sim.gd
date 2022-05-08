extends Node

func _ready():
	for i in range(10):
		run_sim()

func run_sim():
	#var hour_pct = [.11, .11, .07, .1, .06, .07, .08]
	var hour_pct = [.33, .32, .21, .29, .18, .20, .23]
	#var hour_pct = [.66, .64, .41, .58, .36, .41, .46]
	var half_day_pct = [1, 1, .82, 1, .71, .81, .91]
	var hour_reward = 0
	var half_day_reward = 0
	for pct in hour_pct:
		for try in range(4):
			if randf() <= pct:
				hour_reward += 1
	for pct in half_day_pct:
		if randf() <= pct:
			half_day_reward += 1

	print("12h: ", half_day_reward, " vs 12x1h: ", hour_reward)
