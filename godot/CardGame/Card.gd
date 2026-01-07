extends Resource
class_name Card

## Представляет игральную карту

enum Suit {
	CLUBS,    # Трефы
	DIAMONDS, # Бубны
	HEARTS,   # Червы
	SPADES    # Пики
}

enum Rank {
	ACE = 1,
	TWO = 2,
	THREE = 3,
	FOUR = 4,
	FIVE = 5,
	SIX = 6,
	SEVEN = 7,
	EIGHT = 8,
	NINE = 9,
	TEN = 10,
	JACK = 11,
	QUEEN = 12,
	KING = 13
}

var suit: Suit
var rank: Rank
var face_up: bool = false

func _init(s: Suit = Suit.CLUBS, r: Rank = Rank.ACE, f: bool = false):
	suit = s
	rank = r
	face_up = f

## Получить значение карты для игры в очки (21)
func get_value() -> int:
	match rank:
		Rank.ACE:
			return 11  # Туз = 11 (или 1, если перебор)
		Rank.JACK, Rank.QUEEN, Rank.KING:
			return 10
		_:
			return rank

## Получить имя файла текстуры карты
func get_texture_name() -> String:
	if not face_up:
		return "cardBack_red1"  # Рубашка карты
	
	var suit_name = ""
	match suit:
		Suit.CLUBS:
			suit_name = "Clubs"
		Suit.DIAMONDS:
			suit_name = "Diamonds"
		Suit.HEARTS:
			suit_name = "Hearts"
		Suit.SPADES:
			suit_name = "Spades"
	
	var rank_name = ""
	match rank:
		Rank.ACE:
			rank_name = "A"
		Rank.JACK:
			rank_name = "J"
		Rank.QUEEN:
			rank_name = "Q"
		Rank.KING:
			rank_name = "K"
		Rank.TEN:
			rank_name = "10"
		_:
			rank_name = str(rank)
	
	return "card" + suit_name + rank_name

## Получить путь к текстуре карты
func get_texture_path() -> String:
	var texture_name = get_texture_name()
	return "res://boardgamePackAsset/PNG/Cards/" + texture_name + ".png"
