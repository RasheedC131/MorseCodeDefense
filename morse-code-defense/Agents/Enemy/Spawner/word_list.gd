class_name WordList
## Words that come as a whole wave every so many kills (see enemy_spawner.gd).
## Each word is spelled by one enemy per letter, left to right across the
## entrances, so a word can only appear on maps with at least that many
## entrances (3 on most maps, 4 on map_center).
##
## These are words people practise when learning Morse: short, everyday, and
## mostly built from the quick letters (E T A I M N S O H R).

const WORDS: Array[String] = [
	# Famous Morse words
	"SOS", "HI", "OK", "YES", "NO",
	# Two letters
	"AT", "IT", "IN", "ON", "AN", "TO", "SO", "ME", "GO", "HE",
	# Three letters
	"HAT", "TEA", "EAT", "SEA", "SET", "TEN", "NET", "SUN", "RUN", "MAN",
	"MEN", "ANT", "AIM", "ART", "HIT", "SIT", "TIN", "TOE", "ONE", "TWO",
	"CAT", "DOG", "HOT", "NOT", "RED",
	# Four letters (maps with 4 entrances)
	"HELP", "TEST", "TIME", "STOP", "HOME", "NAME", "MOON", "TREE", "STAR", "RAIN",
]
