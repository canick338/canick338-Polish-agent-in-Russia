# Примеры использования кат-сцен в сценариях

## Базовое использование
```
cutscene prologue_casino_intro
"Вот так начинается моя история..."
```

## С полным путем
```
cutscene res://Cutscenes/month1_arrival_train.ogv
danila "Наконец-то я прибыл в Обоянь..."
```

## Запретить пропуск (важная сцена)
```
cutscene ending_arrested false
"КОНЕЦ - Арестован"
```

## Не автопродолжать после видео (дождаться нажатия кнопки)
```
cutscene mission_success true false
danila "Миссия выполнена!"
```

---

## Полный синтаксис команды cutscene

```
cutscene <видео_файл> [можно_пропустить] [автопродолжение]
```

### Параметры:
1. **видео_файл** (обязательный) - имя файла или полный путь
   - `prologue_intro` → `res://Cutscenes/prologue_intro.ogv`
   - `res://Cutscenes/ending.webm` → используется как есть

2. **можно_пропустить** (опциональный, по умолчанию true)
   - `true` - можно пропустить любой кнопкой
   - `false` - нельзя пропустить (для важных сцен)

3. **автопродолжение** (опциональный, по умолчанию true)
   - `true` - автоматически продолжить сюжет после видео
   - `false` - ждать нажатия кнопки после видео

---

## Примеры для вашей игры

### Пролог - Казино
```
# Вступительная кат-сцена
cutscene casino_intro
"Добро пожаловать в казино 'Три топора'..."

# Игра в казино здесь...

cutscene casino_win
danila "Ха! Три семерки!"
```

### Прибытие в Обоянь
```
background dani_bedroom fade_in

cutscene arrival_train
danila "Обоянь... Маленький провинциальный городок."
danila "Никто не должен узнать, кто я на самом деле."
```

### Первый допрос
```
cutscene interrogation_room
volkov "Итак, товарищ Данила..."

# Диалог допроса...

if suspicion > 50:
	cutscene interrogation_suspicion
	volkov "Что-то в вас не так..."
```

### Миссия - Фотографирование
```
danila "Нужно быстро сфотографировать документы..."

cutscene photo_mission false
"Вспышка камеры... Кто-то идет!"

choice:
	"Спрятаться":
		set stealth +10
        "Вы успели спрятаться"
	"Бежать":
		set suspicion +20
        "Вы привлекли внимание"
```

### Концовки
```
# Концовка 1: Арест
cutscene ending_arrested false
"Ваша операция провалилась..."
"КОНЕЦ - Арестован"

# Концовка 2: Побег
cutscene ending_escape false
"Вы успели сбежать..."
"КОНЕЦ - Побег"

# Концовка 3: Двойной агент
cutscene ending_double_agent false
"Вы работали на обе стороны..."
"КОНЕЦ - Двойной агент"

# Концовка 4: Герой
cutscene ending_hero false
"Вы стали героем России..."
"КОНЕЦ - Неожиданный герой"
```

---

## Интеграция в существующие сценарии

### prologue.txt
```
# Начало игры
cutscene prologue_intro

background dani_bedroom fade_in
danila neutral "Меня зовут Данила..."
```

### act1_arrival.txt
```
mark arrival_start

cutscene arrival_train
background dani_bedroom fade_in

danila neutral "Вот и Обоянь..."
```

### interrogations/interrogation_month1.txt
```
mark interrogation1_start

cutscene interrogation_room_enter

background dani_bedroom fade_in
volkov "Проходите, товарищ Данила."
```

### endings/ending_system.txt
```
mark check_ending

if suspicion >= 80:
	cutscene ending_arrested false
	jump ending_arrested
elif stealth >= 70 and suspicion < 50:
	cutscene ending_hero false
	jump ending_hero
```

---

## Советы по использованию

### ✅ Хорошие практики:
1. Короткие видео (5-15 секунд) для обычных сцен
2. Длинные видео (30-60 секунд) только для концовок
3. Запрещать пропуск только для важных сюжетных моментов
4. Использовать кат-сцены для передачи времени или места

### ❌ Избегайте:
1. Слишком частые кат-сцены (раздражают игрока)
2. Очень длинные видео без возможности пропуска
3. Кат-сцены в середине важного диалога

---

## Технические детали

### Поддерживаемые форматы:
- `.ogv` (Ogg Theora) - рекомендуется
- `.webm` (VP8/VP9)

### Автоматические префиксы:
```
cutscene intro          → res://Cutscenes/intro.ogv
cutscene intro.webm     → res://Cutscenes/intro.webm
cutscene res://my.ogv   → res://my.ogv (без изменений)
```

### Управление во время просмотра:
- **Любая кнопка** - пропустить (если разрешено)
- **ESC** - пропустить (если разрешено)
- **Клик мыши** - пропустить (если разрешено)
