extends Node
class_name GameGlobal

## Глобальное состояние игры
## Хранит деньги игрока и другие персистентные данные

# Статические переменные доступны отовсюду через GameGlobal.variable
static var player_money: int = 30
static var player_reputation: int = 0

static func add_money(amount: int):
	player_money += amount
	print("Money added: ", amount, ". Total: ", player_money)

static func remove_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		print("Money removed: ", amount, ". Total: ", player_money)
		return true
	return false
