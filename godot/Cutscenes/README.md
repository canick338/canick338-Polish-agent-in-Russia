# Каталог для ПОЛНОЭКРАННЫХ видео кат-сцен

**ВАЖНО:** Это папка ТОЛЬКО для полноэкранных кат-сцен (занимают весь экран).

Для анимированных портретов персонажей используйте:
```
godot/Characters/Animations/{Character}/
```

Поместите сюда ваши видео файлы в формате `.ogv` или `.webm`

## Примеры файлов (создайте их):

- `prologue_casino_intro.ogv` - Вступление в казино
- `arrival_train.ogv` - Прибытие поезда в Обоянь
- `interrogation_room.ogv` - Комната допроса
- `mission_success.ogv` - Успешная миссия
- `ending_arrested.ogv` - Концовка: арест
- `ending_escape.ogv` - Концовка: побег
- `ending_hero.ogv` - Концовка: герой

## ⚠️ НЕ размещайте здесь:

- Анимированные портреты персонажей (используйте `Characters/Animations/`)
- Короткие зацикленные анимации (используйте `Characters/Animations/`)

## Как создать видео

См. `/godot/CUTSCENE_GUIDE.md` для подробных инструкций.

## Быстрая конвертация

```bash
ffmpeg -i input.mp4 -c:v libtheora -qscale:v 7 -c:a libvorbis -qscale:a 5 output.ogv
```

