extends CSGBox

func get_overlapping_cards():
	var overlapping_areas = $OverlapDetector.get_overlapping_areas()
	var overlapping_cards = []
	for area in overlapping_areas:
		overlapping_cards.append(area.owner)
	#print("Overlapping cards: ", overlapping_cards)
	return overlapping_cards
