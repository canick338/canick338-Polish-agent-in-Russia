import json

path = "c:/Users/rushe/OneDrive/Desktop/Code/godot-2d-visual-novel-main/godot/Story/00_Warsaw/02_factory_shift.json"

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

# The root is a list of commands.
# Index 0: fade_out
# Index 1: background factory_exterior
# Index 2: the massive if block (factory_visit_count >= 3)

root_if = data[2]

# --- MODIFY STAGE 1 (else block of root_if) ---
stage_1 = root_if["else"]
# Stage 1 currently has cooking minigame. We want a choice for catching the jar, and factory_jam as the minigame.
# Find where the jar drops.
drop_idx = 0
for i, cmd in enumerate(stage_1):
    if cmd.get("text", "").startswith("Огромная стеклянная колба"):
        drop_idx = i
        break

# The choice comes after: "Время замедляется. Колба стремительно приближается к бетону. Если она разобьётся, едкие испарения выжгут лёгкие всем в радиусе десяти метров. Смерть неминуема."
choice_idx = drop_idx + 2

# We'll replace everything after choice_idx with the choice, then minigame.
# Let's rebuild the rest of Stage 1.
end_shift_commands = [
    {
        "character": "worker",
        "side": "right",
        "expression": "happy",
        "text": "Смена подошла к концу. Томаш жмёт Даниле руку.",
        "type": "dialogue"
    },
    {"args": ["energy", "-30"], "name": "set", "type": "command"},
    {"args": ["factory_visit_count", 1], "name": "set", "type": "command"},
    {"args": ["fade_out"], "name": "transition", "type": "command"},
    {"args": ["WorldMap"], "name": "scene", "type": "command"}
]

factory_jam_minigame = [
    {"character": "boss_of_factory", "expression": "neutral", "text": "А теперь живо на ленту! Банки сами себя не расфасуют!", "type": "dialogue"},
    {"args": ["factory_jam"], "name": "minigame", "type": "command"},
    {
        "type": "if",
        "condition": "factory_jam_final_score>=20",
        "then": [
            {"character": "boss_of_factory", "expression": "happy", "text": "Отличная скорость на конвейере! Получи премию.", "type": "dialogue"},
            {"args": ["money", "+80"], "name": "set", "type": "command"}
        ],
        "elif": [
            {
                "condition": "factory_jam_final_score>=8",
                "then": [
                    {"character": "boss_of_factory", "expression": "neutral", "text": "Норма выполнена. Держи зарплату.", "type": "dialogue"},
                    {"args": ["money", "+50"], "name": "set", "type": "command"}
                ]
            }
        ],
        "else": [
            {"character": "boss_of_factory", "expression": "angry", "text": "Ты разбил половину банок! Вычту из твоей ничтожной зарплаты!", "type": "dialogue"},
            {"args": ["money", "+15"], "name": "set", "type": "command"}
        ]
    }
]

choice_node = {
    "type": "choice",
    "options": [
        {
            "text": "Рискнуть и поймать колбу в полёте",
            "children": [
                {"character": "danila", "expression": "angry", "text": "Курва мать...", "type": "dialogue"},
                {"character": "", "text": "Данила делает резкий рывок вперёд. Скользя на ободранных коленях по разлитому машинному маслу, он вытягивает руки и ловит стеклянную колбу.", "type": "dialogue"},
                {"character": "", "text": "С тяжелым вздохом он перехватывает колбу ровно в миллиметре от грязного бетона, пачкая всю куртку в мазуте.", "type": "dialogue"},
                {"character": "worker", "side": "right", "expression": "shocked", "text": "М-матерь Божья... Ченстоховская Дева Мария... Ты... ты спас меня! И весь цех!", "type": "dialogue"}
            ] + factory_jam_minigame
        },
        {
            "text": "Отпрыгнуть в сторону",
            "children": [
                {"args": ["shake"], "name": "camera", "type": "command"},
                {"character": "", "text": "Колба со звоном разбивается о бетон. Едкое зелёное облако моментально заполняет цех.", "type": "dialogue"},
                {"character": "boss_of_factory", "expression": "angry", "text": "ОСЛЫ! КРЕТИНЫ! ВЫЧТУ У ОБОИХ ИЗ ЗАРПЛАТЫ! ЖИВО НАДЕЛИ РЕСПИРАТОРЫ И УБРАЛИ ЗА СОБОЙ!", "type": "dialogue"},
                {"character": "danila", "expression": "sad", "text": "(Мысли) Лёгкие горят огнём. Нужно было ловить эту проклятую колбу.", "type": "dialogue"},
                {"args": ["energy", "-5"], "name": "set", "type": "command"}
            ] + factory_jam_minigame
        }
    ]
}

stage_1 = stage_1[:choice_idx+1] + [choice_node] + end_shift_commands
root_if["else"] = stage_1

# --- MODIFY STAGE 2 (elif[1]) ---
# Keep cooking minigame, just a narrative choice with Bronislav and the rat.
stage_2 = root_if["elif"][1]["then"]
rat_idx = 0
for i, cmd in enumerate(stage_2):
    if cmd.get("text", "").startswith("Пока этот сумасшедший гоняется за грызуном"):
        rat_idx = i
        break

rat_choice = {
    "type": "choice",
    "options": [
        {
            "text": "Молча стоять и запоминать информацию",
            "children": [
                {"character": "danila", "expression": "neutral", "text": "(Мысли) Пока этот сумасшедший гоняется за грызуном, он на эмоциях выбалтывает все коммерческие тайны. Отлично. Надо просто стоять и запоминать.", "type": "dialogue"}
            ]
        },
        {
            "text": "Предложить помощь с крысой",
            "children": [
                {"character": "danila", "expression": "neutral", "text": "Шеф Бронислав, давайте я её прихлопну?", "type": "dialogue"},
                {"character": "boss_of_factory", "expression": "angry", "text": "НЕ ЛЕЗЬ! ЭТО МОЯ ДОБЫЧА! Я ИЗ НЕЁ ШАПКУ СДЕЛАЮ!", "type": "dialogue"}
            ]
        }
    ]
}
# Replace the thought with the choice
stage_2[rat_idx] = rat_choice

# --- MODIFY STAGE 3 (elif[0]) ---
# End of stage 3: Tomasz invites to cards.
stage_3 = root_if["elif"][0]["then"]
invite_idx = 0
for i, cmd in enumerate(stage_3):
    if cmd.get("text", "").startswith("Вот и круто! Подсобка твоя, брат!"):
        invite_idx = i
        break

casino_choice = {
    "type": "choice",
    "options": [
        {
            "text": "Пойти в подсобку сыграть в карты",
            "children": [
                {"character": "danila", "expression": "neutral", "text": "Знаешь, Томаш. А давай. Партеечку на пару злотых.", "type": "dialogue"},
                {"character": "worker", "expression": "excited", "text": "Отличный настрой! Погнали!", "type": "dialogue"},
                {"args": ["card_game"], "name": "minigame", "type": "command"},
                {
                    "type": "if",
                    "condition": "card_game_won>=1",
                    "then": [
                        {"character": "worker", "expression": "sad", "text": "Ну ты даёшь, обчистил нас до нитки! Новичкам везёт...", "type": "dialogue"},
                        {"args": ["money", "+100"], "name": "set", "type": "command"}
                    ],
                    "else": [
                        {"character": "worker", "expression": "happy", "text": "Ха-ха! Плохо ты блефуешь, Данила. Денежки наши!", "type": "dialogue"}
                    ]
                },
                {"character": "worker", "expression": "neutral", "text": "Ладно, подсобка теперь всегда для тебя открыта. Заходи рубиться в любое время.", "type": "dialogue"},
                {"args": ["casino_unlocked", 1], "name": "set", "type": "command"}
            ]
        },
        {
            "text": "Отказаться, сославшись на усталость",
            "children": [
                {"character": "danila", "expression": "tired", "text": "В другой раз, Томаш. Смена была тяжёлой, глаза слипаются.", "type": "dialogue"},
                {"character": "worker", "expression": "neutral", "text": "Жаль. Но если надумаешь — подсобка открыта, мы там почти каждый вечер.", "type": "dialogue"},
                {"args": ["casino_unlocked", 1], "name": "set", "type": "command"}
            ]
        }
    ]
}
end_stage_3 = [
    {"args": ["energy", "-30"], "name": "set", "type": "command"},
    {"args": ["factory_visit_count", 3], "name": "set", "type": "command"},
    {"args": ["fade_out"], "name": "transition", "type": "command"},
    {"args": ["WorldMap"], "name": "scene", "type": "command"}
]
stage_3 = stage_3[:invite_idx] + [casino_choice] + end_stage_3
root_if["elif"][0]["then"] = stage_3

# --- MODIFY STAGE 4 (then block) ---
# Give choice of station:
stage_4 = root_if["then"]
cook_minigame_idx = 0
for i, cmd in enumerate(stage_4):
    if cmd.get("name") == "minigame" and cmd.get("args") == ["cooking"]:
        cook_minigame_idx = i
        break

# We will cut out the cooking minigame and the if check underneath it, and replace it with a choice.
cooking_path = stage_4[cook_minigame_idx:cook_minigame_idx+2]
station_choice = {
    "type": "choice",
    "options": [
        {
            "text": "Работать на фасовке банок (Ловкость)",
            "children": [
                {"character": "danila", "expression": "neutral", "text": "Пойду на конвейер. Банки сами себя в коробки не сложат.", "type": "dialogue"}
            ] + factory_jam_minigame
        },
        {
            "text": "Работать у химических котлов (Химия)",
            "children": [
                {"character": "danila", "expression": "neutral", "text": "Пойду к котлам. Пора смешать пару химикатов.", "type": "dialogue"}
            ] + cooking_path
        }
    ]
}
stage_4 = stage_4[:cook_minigame_idx] + [station_choice] + end_shift_commands
root_if["then"] = stage_4

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print("Rewrite successful.")

