import json

# ==========================================
# REBUILDING 02_factory_shift.json
# ==========================================

fade_in = [{"args": ["fade_out"], "name": "transition", "type": "command"}]
bg = [{"args": ["factory_exterior", ""], "name": "background", "type": "command"}]

# --- COMMONS ---
end_shift_v1 = [
    {"args": ["energy", "-30"], "name": "set", "type": "command"},
    {"args": ["factory_visit_count", 1], "name": "set", "type": "command"},
    {"args": ["fade_out"], "name": "transition", "type": "command"},
    {"args": ["WorldMap"], "name": "scene", "type": "command"}
]

end_shift_v2 = [
    {"args": ["energy", "-30"], "name": "set", "type": "command"},
    {"args": ["factory_visit_count", 2], "name": "set", "type": "command"},
    {"args": ["fade_out"], "name": "transition", "type": "command"},
    {"args": ["WorldMap"], "name": "scene", "type": "command"}
]

end_shift_v3 = [
    {"args": ["energy", "-30"], "name": "set", "type": "command"},
    {"args": ["factory_visit_count", 3], "name": "set", "type": "command"},
    {"args": ["fade_out"], "name": "transition", "type": "command"},
    {"args": ["WorldMap"], "name": "scene", "type": "command"}
]

end_shift_v4 = [
    {"character": "worker", "side": "right", "expression": "happy", "text": "Смена окончена. Фатум благосклонен к нам сегодня.", "type": "dialogue"},
    {"args": ["energy", "-30"], "name": "set", "type": "command"},
    {"args": ["fade_out"], "name": "transition", "type": "command"},
    {"args": ["WorldMap"], "name": "scene", "type": "command"}
]

# Mini-game blocks (Scores evaluation done post-minigame)
factory_jam_eval = {
    "type": "if",
    "condition": "factory_jam_final_score>=20",
    "then": [
        {"character": "boss_of_factory", "expression": "happy", "text": "Твои руки движутся в такт с шестерёнками вселенной. Идеальная синхронизация. Возьми премию.", "type": "dialogue"},
        {"args": ["money", "+80"], "name": "set", "type": "command"}
    ],
    "elif": [
        {
            "condition": "factory_jam_final_score>=8",
            "then": [
                {"character": "boss_of_factory", "expression": "neutral", "text": "Баланс хаоса и порядка соблюдён. Твоя зарплата.", "type": "dialogue"},
                {"args": ["money", "+50"], "name": "set", "type": "command"}
            ]
        }
    ],
    "else": [
        {"character": "boss_of_factory", "expression": "angry", "text": "Ты нарушил гармонию производственной линии! Стекло и металл отвергают тебя. Только минимальный оклад.", "type": "dialogue"},
        {"args": ["money", "+15"], "name": "set", "type": "command"}
    ]
}

cooking_eval = {
    "type": "if",
    "condition": "cooking_score>=20",
    "then": [
        {"character": "boss_of_factory", "expression": "happy", "text": "Химическая трансмутация завершена безупречно. Ты понял саму суть материи, Данила. Прими эту награду.", "type": "dialogue"},
        {"args": ["money", "+80"], "name": "set", "type": "command"}
    ],
    "elif": [
        {
            "condition": "cooking_score>=8",
            "then": [
                {"character": "boss_of_factory", "expression": "neutral", "text": "Реакция стабильна. Энтропия не поглотила нас. Стандартная оплата.", "type": "dialogue"},
                {"args": ["money", "+50"], "name": "set", "type": "command"}
            ]
        }
    ],
    "else": [
        {"character": "boss_of_factory", "expression": "angry", "text": "Раствор осквернён! Твоя душа так же мутна, как эта жижа в котле! Штраф!", "type": "dialogue"},
        {"args": ["money", "+15"], "name": "set", "type": "command"}
    ]
}

# ==========================================
# STAGE 1 (factory_visit_count == 0)
# ==========================================
stage_1 = [
    # Intro
    {"character": "danila", "side": "left", "animation": "enter", "expression": "serious", "text": "(Мысли) Говорят, судьба — это река. Но этот завод... этот завод — гигантская бетономешалка, перемалывающая человеческие надежды в радиоактивный шлак.", "type": "dialogue"},
    {"character": "danila", "expression": "neutral", "text": "(Мысли) Я пришёл сюда не за деньгами. Я — скальпель Академии, занесённый над гнилой опухолью синдиката Карла Обломова. Нити фатума сплелись у этих ржавых ворот.", "type": "dialogue"},
    {"args": ["factory_inside", ""], "name": "background", "type": "command"},
    {"character": "boss_of_factory", "side": "right", "animation": "enter", "expression": "neutral", "text": "Время. Оно не прощает слабости. А ты опоздал на четырнадцать секунд. За это время три партии могли бы сойти с конвейера.", "type": "dialogue"},
    {"character": "danila", "side": "left", "expression": "serious", "text": "Считайте, что я позволил времени сделать небольшую передышку. Я новый фасовщик.", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "serious", "text": "Варшава гниёт, парень. Люди на улицах пожирают друг друга, как оголодавшие псы. А здесь — оазис порядка в пустыне хаоса. Я Бронислав. Последний бастион логики.", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "neutral", "text": "Я даю вам работу, чистый цех и пайку. Вы отдаёте мне свой пот и беспрекословное подчинение. Вставай за конвейер. Покажи, чего стоит твоя карма.", "type": "dialogue"},
    # Flask Incident
    {"args": ["shake"], "name": "camera", "type": "command"},
    {"character": "worker", "side": "left", "animation": "enter", "expression": "shocked", "text": "О нет! Колба... она выскользнула! Фатум отвернулся от меня!", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "angry", "text": "ЕСЛИ ЭТА ТВЕРДЫНЯ СТЕКЛА РАЗОБЬЁТСЯ, КИСЛОТНЫЙ ТУМАН ОБНАЖИТ НАШИ КОСТИ ЗА ДЕСЯТЬ СЕКУНД!", "type": "dialogue"},
    # Choice for catching
    {
        "type": "choice",
        "options": [
            {
                "text": "Отдаться инстинктам и броситься за колбой",
                "children": [
                    {"character": "danila", "expression": "serious", "text": "Не сегодня, старуха с косой.", "type": "dialogue"},
                    {"character": "", "text": "Данила бросается вперёд. Время вязнет, как смола. Он преклоняет колени в лужу машинного масла, скользит по грязному бетону и перехватывает колбу.", "type": "dialogue"},
                    {"character": "worker", "expression": "happy", "text": "Невероятно... Твои движения... они совершенны!", "type": "dialogue"},
                    {"character": "boss_of_factory", "expression": "neutral", "text": "Безумный риск. Но результат приемлем. Ты спас смену от мучительной кончины. А теперь — за конвейер, гармония не ждёт.", "type": "dialogue"}
                ]
            },
            {
                "text": "Сохранить хладнокровие и отступить",
                "children": [
                    {"character": "danila", "expression": "neutral", "text": "(Мысли) Законы физики неумолимы. Гравитация возьмёт своё.", "type": "dialogue"},
                    {"args": ["shake"], "name": "camera", "type": "command"},
                    {"character": "", "text": "Звон разбитого стекла эхом разносится по цеху. Едкий дым обжигает лёгкие.", "type": "dialogue"},
                    {"character": "boss_of_factory", "expression": "angry", "text": "НЕУКЛЮЖЕЕ СОЗДАНИЕ! НЕМЕДЛЕННО АКТИВИРОВАТЬ ВЕНТИЛЯЦИЮ! ВЫЧТУ УТЕЧКУ ИЗ ВАШИХ ЖАЛКИХ ЖИЗНЕЙ!", "type": "dialogue"},
                    {"args": ["energy", "-5"], "name": "set", "type": "command"}
                ]
            }
        ]
    },
    {"args": ["factory_jam"], "name": "minigame", "type": "command"},
    factory_jam_eval,
    # Card Game Intro on Day 1
    {"character": "worker", "side": "left", "expression": "excited", "text": "Послушай, Данила. Твоя аура сегодня невероятна. Закончилась эта ядовитая рутина. Мы с парнями идём в подсобку — бросать вызов судьбе в карты.", "type": "dialogue"},
    {
        "type": "choice",
        "options": [
            {
                "text": "Принять вызов судьбы (Сыграть в карты)",
                "children": [
                    {"character": "danila", "expression": "neutral", "text": "Бросить кости грядущему? Почему бы и нет.", "type": "dialogue"},
                    {"args": ["card_game"], "name": "minigame", "type": "command"},
                    {
                        "type": "if",
                        "condition": "card_game_won>=1",
                        "then": [
                            {"character": "worker", "expression": "sad", "text": "Ты раздел нас до нитки. Твоё чутьё пугает.", "type": "dialogue"},
                            {"args": ["money", "+100"], "name": "set", "type": "command"}
                        ],
                        "else": [
                            {"character": "worker", "expression": "happy", "text": "Фортуна слепа, Данила. Не в этот раз.", "type": "dialogue"}
                        ]
                    },
                    {"character": "worker", "expression": "neutral", "text": "Но ты теперь один из нас. Подсобка твоя, казино открыто для тебя всегда.", "type": "dialogue"},
                    {"args": ["casino_unlocked", 1], "name": "set", "type": "command"}
                ]
            },
            {
                "text": "Отклонить, сославшись на усталость",
                "children": [
                    {"character": "danila", "expression": "tired", "text": "Завтра новый бой. Мой сосуд энергии требует отдыха.", "type": "dialogue"},
                    {"character": "worker", "expression": "neutral", "text": "Понимаю. Но знай, дверь казино теперь для тебя не заперта.", "type": "dialogue"},
                    {"args": ["casino_unlocked", 1], "name": "set", "type": "command"}
                ]
            }
        ]
    }
] + end_shift_v1

# ==========================================
# STAGE 2 (factory_visit_count == 1)
# ==========================================
stage_2_rat_choice = {
    "type": "choice",
    "options": [
        {
            "text": "Молча впитывать информацию",
            "children": [
                {"character": "danila", "expression": "neutral", "text": "(Мысли) Хаос этого момента работает на меня. Истерика вскрывает замки тайн, которые Карл Обломов прячет во тьме.", "type": "dialogue"}
            ]
        },
        {
            "text": "Предложить уничтожить грызуна",
            "children": [
                {"character": "danila", "expression": "serious", "text": "Позвольте мне прервать нить её жалкого существования.", "type": "dialogue"},
                {"character": "boss_of_factory", "expression": "angry", "text": "НАЗАД! Это мой крест! Я должен нести очищение этому цеху самолично!", "type": "dialogue"}
            ]
        }
    ]
}

stage_2 = [
    {"character": "danila", "side": "left", "animation": "enter", "expression": "serious", "text": "(Мысли) Второй визит. Воздух гуще, а тени длиннее. Я приближаюсь к ядру синдиката.", "type": "dialogue"},
    {"args": ["factory_inside", ""], "name": "background", "type": "command"},
    {"character": "boss_of_factory", "side": "right", "animation": "enter", "expression": "angry", "text": "ИЗЫДИ, СЛУГА ХАОСА! ОСТАВЬ В ПОКОЕ МОЕГО СТАЛЬНОГО ИСПОЛИНА!", "type": "dialogue"},
    {"character": "", "text": "Бронислав, тяжело дыша, неистово обрушивает древнюю металлическую швабру на промышленный блендер. Грохот перекрывает шум турбин.", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "angry", "text": "(Удар!) Карл Обломов алчет совершенства логистики! (Удар!) Контракты с Обоянью зиждутся на идеальном весе компонентов!", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "serious", "text": "А эта мерзкая тварь... она грызёт провода умиротворения! Если отгрузки сорвутся, цепные псы Карла смешают нас всех с цементом! Я должен защитить этих болванов-рабочих от гнева преисподней! СДОХНИ!", "type": "dialogue"},
    stage_2_rat_choice,
    {"character": "boss_of_factory", "expression": "neutral", "text": "Враг отступил в вентиляционные лабиринты. Оборудование спасено. Занимай место у котла, Данила. Пришло время алхимии.", "type": "dialogue"},
    {"args": ["cooking"], "name": "minigame", "type": "command"},
    cooking_eval
] + end_shift_v2

# ==========================================
# STAGE 3 (factory_visit_count == 2) - CLIMAX
# ==========================================
# Assuming the player has HQ mission to steal the ledger
stage_3 = [
    {"character": "danila", "side": "left", "animation": "enter", "expression": "serious", "text": "(Мысли) Час настал. Смена почти окончена. Бронислав совершает обход восточного крыла. Кабинет пуст. Судьба сама открывает мне двери.", "type": "dialogue"},
    {"args": ["factory_inside", ""], "name": "background", "type": "command"},
    {"character": "", "text": "Данила скользит в тенях, как призрак правосудия. Он вскрывает сейф шпилькой и извлекает чёрный гроссбух Карла Обломова. Сердцебиение ровное.", "type": "dialogue"},
    {"character": "boss_of_factory", "side": "right", "animation": "enter", "expression": "serious", "text": "Я так и знал. Никто не ловит стеклянные колбы с таким хладнокровием, если он не тренировался у лучших.", "type": "dialogue"},
    {"character": "", "text": "Бронислав стоит на пороге. ТТ в его руке опущен, но взгляд тяжёл, как свинцовое небо.", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "serious", "text": "Я знаю выучку варшавской Академии. Вы, рыцари света, приходите в чужие храмы, не понимая, на чём держится этот мир.", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "sad", "text": "Я даю этим подонкам на заводе смысл жизни. Еду. Спасаю от ножа в подворотне. Если ты заберёшь книгу, Карл Обломов сотрёт их в порошок. Завод исчезнет.", "type": "dialogue"},
    {"character": "boss_of_factory", "expression": "neutral", "text": "У меня нет выбора. Высшее благо требует малых жертв. Брось книгу, сынок.", "type": "dialogue"},
    {
        "type": "choice",
        "options": [
            {
                "text": "Моральный выбор: Оставить гроссбух и скрыть тайну Бронислава",
                "children": [
                    {"character": "danila", "expression": "serious", "text": "Ваша правда, Бронислав. Мир не делится на чёрное и белое. Академия не увидит эту книгу.", "type": "dialogue"},
                    {"character": "boss_of_factory", "expression": "happy", "text": "Ты мудрее своих покровителей, парень. Я дам тебе копию. Она ударит по Карлу, но отведет след от моих рабочих. Уходи.", "type": "dialogue"},
                    {"character": "danila", "expression": "neutral", "text": "(Мысли) Фатум свернул в незнакомое русло. Я спас людей, но нарушил прямой приказ.", "type": "dialogue"}
                ]
            },
            {
                "text": "Миссия важнее всего: Забрать оригинал (Дезориентировать его)",
                "children": [
                    {"character": "danila", "expression": "angry", "text": "Орден превыше всего! Моя цель — Карл, а вы лишь сопутствующий урон в мясорубке судьбы!", "type": "dialogue"},
                    {"character": "boss_of_factory", "expression": "serious", "text": "Тогда да простит меня Бог.", "type": "dialogue"},
                    {"character": "", "text": "Бронислав поднимает пистолет. Время замирает. Но внезапно...", "type": "dialogue"},
                    {"args": ["shake"], "name": "camera", "type": "command"},
                    {"character": "", "text": "БАБАХ! Древний советский огнетушитель ОВП-10М на стене, не выдержав перепада давления, детонирует, заливая кабинет белой пеной!", "type": "dialogue"},
                    {"character": "boss_of_factory", "expression": "angry", "text": "КХЕ! МОИ ГЛАЗА! ПРОКЛЯТАЯ ЖЕЛЕЗЯКА!", "type": "dialogue"},
                    {"character": "danila", "expression": "serious", "text": "(Мысли) Ирония судьбы. Сама ткань пространства вмешалась, чтобы спасти меня. Прощай, Бронислав.", "type": "dialogue"}
                ]
            }
        ]
    }
] + end_shift_v3

# ==========================================
# STAGE 4 (factory_visit_count >= 3) - LOOP
# ==========================================
stage_4 = [
    {"character": "danila", "side": "left", "animation": "enter", "expression": "neutral", "text": "(Мысли) Рутина. Вечный цикл возвращения на конвейер Сансары.", "type": "dialogue"},
    {"args": ["factory_inside", ""], "name": "background", "type": "command"},
    {"character": "boss_of_factory", "side": "right", "animation": "enter", "expression": "neutral", "text": "Механизм завода требует усилий, Данила. Что ты выберешь сегодня? Скорость или точность?", "type": "dialogue"},
    {
        "type": "choice",
        "options": [
            {
                "text": "Танец на конвейере (Фасовка банок)",
                "children": [
                    {"character": "danila", "expression": "neutral", "text": "Железо и гравитация. Я иду на сортировку.", "type": "dialogue"},
                    {"args": ["factory_jam"], "name": "minigame", "type": "command"},
                    factory_jam_eval
                ]
            },
            {
                "text": "Алхимическое варево (Котлы)",
                "children": [
                    {"character": "danila", "expression": "neutral", "text": "Жар реакций и яды. Мое место у котлов.", "type": "dialogue"},
                    {"args": ["cooking"], "name": "minigame", "type": "command"},
                    cooking_eval
                ]
            }
        ]
    }
] + end_shift_v4

# Construct the massive IF tree
root_if = {
    "type": "if",
    "condition": "factory_visit_count>=3",
    "then": stage_4,
    "elif": [
        {"condition": "factory_visit_count==2", "then": stage_3},
        {"condition": "factory_visit_count==1", "then": stage_2}
    ],
    "else": stage_1
}

final_structure = fade_in + bg + [root_if]

with open("c:/Users/rushe/OneDrive/Desktop/Code/godot-2d-visual-novel-main/godot/Story/00_Warsaw/02_factory_shift.json", "w", encoding="utf-8") as f:
    json.dump(final_structure, f, indent=4, ensure_ascii=False)

print("Masterpiece rewrite complete.")

