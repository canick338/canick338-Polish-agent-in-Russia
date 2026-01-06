# Польский агент в России / Polish Agent in Russia

## 🎮 О игре / About the Game

Симулятор жизни польского шпиона **Данилы Ковальского** в российском городе Обоянь.  
A life simulator of Polish spy **Danila Kowalski** in the Russian city of Oboyan.

### Описание / Description

Вы - польский агент под прикрытием бизнесмена. Ваша миссия: собрать разведданные о местном заводе в течение 6 месяцев, не раскрыв своей личности.

You're a Polish agent undercover as a businessman. Your mission: gather intelligence about the local factory over 6 months without revealing your identity.

## ✨ Особенности / Features

- 🎰 **Казино "Три топора"** - мини-игра в начале / "Three Axes" casino mini-game at start
- 📅 **6 месяцев миссии** - февраль-июль / 6 months mission - February to July
- 🎭 **Система скрытности** - поддерживайте прикрытие / Stealth system - maintain your cover
- 🕵️ **Ежемесячные допросы** - майор ФСБ следит за вами / Monthly interrogations by FSB major
- 🎯 **Прогрессивные задания** - от простых к сложным / Progressive missions from easy to hard
- 🎮 **Мини-игры** - фотография, диалоги, кража данных / Mini-games - photography, dialogues, data theft
- 🎬 **6 концовок** - ваши выборы имеют значение / 6 endings - your choices matter

## 🎯 Игровые механики / Game Mechanics

### Система скрытности / Stealth System
- **0-20**: Критический уровень / Critical level
- **21-40**: Низкий / Low
- **41-60**: Средний / Medium
- **61-80**: Хороший / Good
- **81-100**: Отличный / Excellent

### Подозрения майора / Major's Suspicion
- Если > 80 - арест! / If > 80 - arrest!
- Каждый месяц - допрос / Every month - interrogation
- Ваши ответы влияют на результат / Your answers affect the outcome

## 🎬 Концовки / Endings

1. ⭐ **Идеальная** - миссия выполнена безупречно / Perfect - mission completed flawlessly
2. ✅ **Хорошая** - успешное завершение / Good - successful completion
3. 🏃 **Средняя** - эвакуация / Neutral - evacuation
4. ❌ **Плохая** - провал миссии / Bad - mission failed
5. 🚔 **Арест** - вас раскрыли / Arrested - you were exposed
6. ❤️ **Секретная** - любовь и новая жизнь / Secret - love and new life

## 🚀 Установка / Installation

### Требования / Requirements
- **Godot Engine 4.3+**
- Windows/Linux/MacOS

### Запуск / Launch
1. Клонируйте репозиторий / Clone the repository:
```bash
git clone https://github.com/canick338/canick338-Polish-agent-in-Russia.git
cd canick338-Polish-agent-in-Russia
```

2. Откройте проект в Godot / Open project in Godot:
   - Откройте `godot/project.godot` / Open `godot/project.godot`

3. Запустите игру / Run the game:
   - Нажмите F5 или кнопку Play / Press F5 or Play button

## 📂 Структура проекта / Project Structure

```
├── godot/                      # Основной проект Godot / Main Godot project
│   ├── Casino/                 # Слот-машина "Три топора" / Slot machine
│   ├── Story/                  # Сценарии и сюжет / Scripts and story
│   │   ├── months/            # Месяцы миссии / Mission months
│   │   ├── minigames/         # Мини-игры / Mini-games
│   │   ├── interrogations/    # Допросы / Interrogations
│   │   └── endings/           # Концовки / Endings
│   ├── Characters/            # Персонажи / Characters
│   ├── Backgrounds/           # Фоны / Backgrounds
│   └── Theme/                 # UI темы / UI themes
└── start-project/             # Стартовый шаблон (архив) / Starter template (archive)
```

## 📖 Документация / Documentation

- 📘 `godot/Story/README_PROFESSIONAL.md` - Главное руководство / Main guide
- 📗 `godot/Story/DESIGN_DOCUMENT.md` - Дизайн-документ / Design document
- 📕 `godot/РУКОВОДСТВО.md` - Руководство на русском / Russian guide

## 🎮 Как играть / How to Play

### Каждый месяц / Each month:
1. 📨 Получение задания от центра / Receive mission from HQ
2. 🏃 Свободные действия (2-3 дня) / Free actions (2-3 days)
3. 🎯 Выполнение задания (мини-игра) / Complete mission (mini-game)
4. 🕵️ Допрос у майора / Interrogation by major
5. ➡️ Переход к следующему месяцу / Move to next month

### Советы / Tips:
- ✅ Изучайте русскую культуру / Study Russian culture
- ✅ Будьте осторожны с вопросами о заводе / Be careful asking about the factory
- ✅ Поддерживайте дружбу с местными / Maintain friendships with locals
- ✅ Запоминайте свою легенду / Remember your cover story
- ⚠️ Избегайте подозрительного поведения / Avoid suspicious behavior

## 🛠️ Статус разработки / Development Status

- ✅ Игровые механики / Game mechanics - **100%**
- ✅ Месяц 1 (Февраль) / Month 1 (February) - **100%**
- ✅ Месяц 2 (Март) / Month 2 (March) - **100%**
- 🔄 Месяцы 3-6 / Months 3-6 - **30%** (структура готова / structure ready)
- ✅ Допросы / Interrogations - **100%**
- ✅ Мини-игры / Mini-games - **2/6** готовы / ready
- ✅ Концовки / Endings - **100%**
- ⚠️ Графика / Graphics - **Нужны спрайты / Sprites needed**

**Общий прогресс / Overall progress: ~70%**

## 🎨 Требуются ассеты / Assets Needed

### Приоритет / Priority:
- [ ] Спрайты персонажей / Character sprites
- [ ] Фоны локаций / Location backgrounds
- [ ] Музыка / Music
- [ ] Звуковые эффекты / Sound effects

## 🤝 Вклад / Contributing

Проект открыт для вклада! / Project is open for contributions!

### Что можно сделать / What you can do:
- 🎨 Создать спрайты персонажей / Create character sprites
- 🖼️ Нарисовать фоны / Draw backgrounds
- 🎵 Добавить музыку / Add music
- 📝 Написать месяцы 3-6 / Write months 3-6
- 🐛 Найти и исправить баги / Find and fix bugs
- 🌍 Улучшить перевод / Improve translation

## 📄 Лицензия / License

MIT License - свободно используйте и модифицируйте / Free to use and modify

## 👨‍💻 Автор / Author

**canick338**

## 🌟 Особая благодарность / Special Thanks

- Godot Engine team
- Visual Novel framework contributors
- Beta testers

---

**Сделано с ❤️ на Godot Engine / Made with ❤️ in Godot Engine**

**⭐ Поставьте звезду, если понравилось! / Star if you like it!**
