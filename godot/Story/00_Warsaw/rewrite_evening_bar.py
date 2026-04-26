[
    {
        "type": "command",
        "name": "background",
        "args": [
            "bar_inside",
            ""
        ]
    },
    {
        "type": "if",
        "condition": "bar_visited>=3",
        "then": [
            {
                "type": "dialogue",
                "character": "",
                "text": "Данила заходит в бар. Знакомый запах дешёвого пива и пережаренного арахиса."
            },
            {
                "type": "if",
                "condition": "erika_kissed==1",
                "then": [
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "А?! О-опять ты?! Т-ты снова припёрся!",
                        "expression": "shocked",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Эрика краснеет до корней волос и начинает судорожно протирать один и тот же участок стойки, буквально прожигая тряпкой дерево."
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Я же просила... то есть... зачем ты пришёл?! Я на работе вообще-то!",
                        "expression": "shy",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "danila",
                        "text": "Решил зайти выпить. И посмотреть на лучшего бармена в Восточной Варшаве.",
                        "expression": "smile",
                        "side": "left"
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "З-замолчи! Кто-нибудь услышит! И вообще, то, что было ночью... это была просто слабость! Стресс! Да, точно, стресс!",
                        "expression": "cute",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "danila",
                        "text": "Как скажешь. Слабость так слабость. Налей мне чего-нибудь, стресс.",
                        "expression": "neutral",
                        "side": "left"
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Эй! Я не говорила, что мне не понравилось! То есть... Аргх! Ты невыносим!",
                        "expression": "shocked",
                        "side": "right",
                        "event": {
                            "name": "shake_camera",
                            "args": [
                                0.5
                            ]
                        }
                    },
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Она отворачивается к полкам с бутылками, пытаясь скрыть пылающее лицо. Затем глубоко вдыхает и поворачивается обратно."
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Ч-что тебе налить? Т-только не думай, что между нами что-то есть! Я просто делаю свою работу! И... и вообще... я рада тебя видеть...",
                        "expression": "shy",
                        "side": "right"
                    }
                ],
                "else": [
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Опять ты? Зачастил ты к нам. Ну садись, рассказывай, что нового.",
                        "expression": "happy",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "danila",
                        "text": "Мне как обычно.",
                        "expression": "neutral",
                        "side": "left"
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Как скажешь. Только без фокусов сегодня.",
                        "expression": "neutral",
                        "side": "right"
                    }
                ]
            },
            {
                "type": "choice",
                "options": [
                    {
                        "text": "Заказать пиво (10 zl)",
                        "children": [
                            {
                                "type": "if",
                                "condition": "money>=10",
                                "then": [
                                    {
                                        "type": "command",
                                        "name": "set",
                                        "args": [
                                            "money",
                                            "-10"
                                        ]
                                    },
                                    {
                                        "type": "command",
                                        "name": "set",
                                        "args": [
                                            "energy",
                                            "+15"
                                        ]
                                    },
                                    {
                                        "type": "command",
                                        "name": "set",
                                        "args": [
                                            "drinks",
                                            "+1"
                                        ]
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "Пиво. Обычное.",
                                        "expression": "neutral",
                                        "side": "left"
                                    },
                                    {
                                        "type": "if",
                                        "condition": "erika_kissed==1",
                                        "then": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Д-держи! И не думай, что я старалась для тебя!",
                                                "expression": "shy",
                                                "side": "right"
                                            }
                                        ],
                                        "else": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Держи, бродяга.",
                                                "expression": "neutral",
                                                "side": "right"
                                            }
                                        ]
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "",
                                        "text": "Данила делает глоток. Знакомый отвратительный вкус. Как дома."
                                    },
                                    {
                                        "type": "if",
                                        "condition": "drinks>=3",
                                        "then": [
                                            {
                                                "type": "dialogue",
                                                "character": "",
                                                "text": "Перед глазами всё начинает плыть. Данила покачивается на стуле."
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "danila",
                                                "text": "(Мысли) Кажется, я перебрал... Третья кружка была лишней...",
                                                "expression": "tired",
                                                "side": "left"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Эй! Хватит! Ты уже еле сидишь!",
                                                "expression": "shocked",
                                                "side": "right"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "danila",
                                                "text": "Всё нормально... просто комната немного вращается...",
                                                "expression": "tired",
                                                "side": "left"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Так, всё! Бар для тебя закрыт на сегодня!",
                                                "expression": "angry",
                                                "side": "right"
                                            },
                                            {
                                                "type": "if",
                                                "condition": "erika_kissed==1",
                                                "then": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "",
                                                        "text": "Эрика выбегает из-за стойки, перекидывает его руку через своё плечо и тащит к выходу."
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Боже мой, какой же ты тяжёлый! И зачем я вообще с тобой связалась?! Пьяница!",
                                                        "expression": "cute",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "(Бормочет) Ты хорошо пахнешь...",
                                                        "expression": "tired",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "З-ЗАТКНИСЬ! Ты пьяный! Ты не соображаешь, что несёшь! Б-бака!",
                                                        "expression": "shocked",
                                                        "side": "right",
                                                        "event": {
                                                            "name": "shake_camera",
                                                            "args": [
                                                                0.5
                                                            ]
                                                        }
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "",
                                                        "text": "Эрика выводит его на свежий воздух и усаживает на скамейку у входа."
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "(Тихо) Сиди тут и протрезвей. Я принесу воды. И не смей никуда уходить, слышишь?",
                                                        "expression": "shy",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "(Мысли) Штирлиц был пьян. Но Штирлицу было тепло.",
                                                        "expression": "tired",
                                                        "side": "left"
                                                    }
                                                ],
                                                "else": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Вставай. Иди домой. Такси вызвать?",
                                                        "expression": "sad",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Не надо. Свежий воздух поможет.",
                                                        "expression": "tired",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Пьяницы... Одни пьяницы вокруг...",
                                                        "expression": "angry",
                                                        "side": "right"
                                                    }
                                                ]
                                            },
                                            {
                                                "type": "command",
                                                "name": "set",
                                                "args": [
                                                    "drinks",
                                                    0
                                                ]
                                            }
                                        ],
                                        "else": []
                                    }
                                ],
                                "else": [
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "Денег нет.",
                                        "expression": "sad",
                                        "side": "left"
                                    },
                                    {
                                        "type": "if",
                                        "condition": "erika_kissed==1",
                                        "then": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Опять без денег? Ох... Держи воду. Б-бесплатно. Только в этот раз!",
                                                "expression": "shy",
                                                "side": "right"
                                            }
                                        ],
                                        "else": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Без денег — без пива. Закон.",
                                                "expression": "angry",
                                                "side": "right"
                                            }
                                        ]
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        "text": "Заказать водку (50 zl) - Свежие слухи",
                        "children": [
                            {
                                "type": "if",
                                "condition": "money>=50",
                                "then": [
                                    {
                                        "type": "command",
                                        "name": "set",
                                        "args": [
                                            "money",
                                            "-50"
                                        ]
                                    },
                                    {
                                        "type": "command",
                                        "name": "set",
                                        "args": [
                                            "drinks",
                                            "+2"
                                        ]
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "Водку. И информацию.",
                                        "expression": "serious",
                                        "side": "left"
                                    },
                                    {
                                        "type": "if",
                                        "condition": "erika_kissed==1",
                                        "then": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "(Наливает, краснея) В-вот. И не смотри на меня так!",
                                                "expression": "shy",
                                                "side": "right"
                                            }
                                        ],
                                        "else": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Ладно. Слушай.",
                                                "expression": "neutral",
                                                "side": "right"
                                            }
                                        ]
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "erika",
                                        "text": "На заводе Обломова новая партия. Говорят, охрану утроили. Работяги шепчутся, что Обломов лично приедет проверять груз на этой неделе.",
                                        "expression": "sad",
                                        "side": "right"
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "(Мысли) Обломов лично? Это шанс, который нельзя упустить.",
                                        "expression": "thinking",
                                        "side": "left"
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "Спасибо. Это ценная информация.",
                                        "expression": "serious",
                                        "side": "left"
                                    },
                                    {
                                        "type": "if",
                                        "condition": "erika_kissed==1",
                                        "then": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Только будь осторожен, ладно? Я... мне не всё равно, что с тобой будет. Т-то есть, мне просто нужен постоянный клиент!",
                                                "expression": "cute",
                                                "side": "right"
                                            }
                                        ],
                                        "else": [
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Только не говори никому, что слышал это здесь.",
                                                "expression": "sad",
                                                "side": "right"
                                            }
                                        ]
                                    },
                                    {
                                        "type": "if",
                                        "condition": "drinks>=3",
                                        "then": [
                                            {
                                                "type": "dialogue",
                                                "character": "",
                                                "text": "Водка ударяет в голову. Комната начинает вращаться."
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Эй, ты побледнел! Хватит пить!",
                                                "expression": "shocked",
                                                "side": "right"
                                            },
                                            {
                                                "type": "if",
                                                "condition": "erika_kissed==1",
                                                "then": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "",
                                                        "text": "Эрика хватает его за руку и выводит из бара."
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Идиот! Зачем столько пить?! Сиди тут! Я принесу воды и... и НЕТ, я НЕ волнуюсь за тебя!",
                                                        "expression": "cute",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "(Мысли) Определённо волнуется.",
                                                        "expression": "tired",
                                                        "side": "left"
                                                    }
                                                ],
                                                "else": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Иди проветрись, бродяга.",
                                                        "expression": "angry",
                                                        "side": "right"
                                                    }
                                                ]
                                            },
                                            {
                                                "type": "command",
                                                "name": "set",
                                                "args": [
                                                    "drinks",
                                                    0
                                                ]
                                            }
                                        ],
                                        "else": []
                                    }
                                ],
                                "else": [
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "Кошелёк пуст.",
                                        "expression": "sad",
                                        "side": "left"
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "erika",
                                        "text": "Нет денег — нет слухов. Приходи, когда разбогатеешь.",
                                        "expression": "neutral",
                                        "side": "right"
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        "text": "Просто посидеть (Бесплатно)",
                        "children": [
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "Просто посижу.",
                                "expression": "neutral",
                                "side": "left"
                            },
                            {
                                "type": "if",
                                "condition": "erika_kissed==1",
                                "then": [
                                    {
                                        "type": "dialogue",
                                        "character": "erika",
                                        "text": "Опять пришёл просто так? Ладно... сиди. Только не пялься на меня!",
                                        "expression": "shy",
                                        "side": "right"
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "(Мысли) Забавно. Она делает вид, что ей всё равно, но каждые полминуты украдкой бросает на меня взгляд.",
                                        "expression": "smile",
                                        "side": "left"
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "",
                                        "text": "Эрика ставит перед ним стакан воды и тарелку с печеньем. Молча. Не глядя в глаза."
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "Я не просил печенье.",
                                        "expression": "neutral",
                                        "side": "left"
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "erika",
                                        "text": "Оно ПРОСРОЧЕННОЕ! Я его ВЫБРАСЫВАЛА! Ешь и молчи!",
                                        "expression": "cute",
                                        "side": "right"
                                    }
                                ],
                                "else": [
                                    {
                                        "type": "dialogue",
                                        "character": "erika",
                                        "text": "Места для платных клиентов. Но ладно, сиди.",
                                        "expression": "neutral",
                                        "side": "right"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                "type": "dialogue",
                "character": "danila",
                "text": "(Мысли) Пора идти. Дела не ждут.",
                "expression": "tired",
                "side": "left"
            }
        ],
        "else": [
            {
                "type": "if",
                "condition": "bar_visited==2",
                "then": [
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Данила заходит в бар очень поздно. Улица уже пуста. Внутри никого нет, только тускло горят несколько ламп над стойкой."
                    },
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Эрика протирает столы, готовясь к закрытию. Услышав скрип двери, она вздрагивает."
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Мы уже закрыва... А, это ты.",
                        "expression": "shocked",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Она откладывает тряпку и нервно поправляет хвостики. В пустом баре удивительно тихо."
                    },
                    {
                        "type": "dialogue",
                        "character": "danila",
                        "text": "Не помешал?",
                        "expression": "neutral",
                        "side": "left"
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "П-помешал вообще-то. Но... раз уж пришёл... садись. Я заварю чай. Чай заварю! Безалкогольный! Нечего тут напиваться на ночь глядя!",
                        "expression": "cute",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Они сидят в полумраке. Горячий пар поднимается от кружек. Атмосфера совершенно иная, чем обычно. Никакого дыма, никаких криков."
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Слушай... насчёт того раза. Откуда ты вообще это умеешь? Ну... ломать людям кости, не вставая со стула.",
                        "expression": "neutral",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "danila",
                        "text": "Я много где бывал. И много чего делал. Вещи, которыми не гордятся.",
                        "expression": "tired",
                        "side": "left"
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "Ты всегда такой... закрытый. Холодный. Но при этом... ты спас меня.",
                        "expression": "sad",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Эрика вдруг протягивает руку. Данила напрягается по привычке, но её пальцы мягко касаются воротника его плаща."
                    },
                    {
                        "type": "dialogue",
                        "character": "erika",
                        "text": "У тебя тут... пылинка. Да. Пылинка.",
                        "expression": "shy",
                        "side": "right"
                    },
                    {
                        "type": "dialogue",
                        "character": "",
                        "text": "Она замирает. Их лица находятся в нескольких сантиметрах друг от друга. Тишина давит на уши. Слышно только их дыхание."
                    },
                    {
                        "type": "if",
                        "condition": "erika_affinity>=2",
                        "then": [
                            {
                                "type": "choice",
                                "options": [
                                    {
                                        "text": "Поцеловать её",
                                        "children": [
                                            {
                                                "type": "dialogue",
                                                "character": "",
                                                "text": "Данила больше ничего не говорит. Он мягко обхватывает её лицо руками и целует."
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "",
                                                "text": "В этот раз никто не кричит. Никто не пугается. Поцелуй медленный, нежный, со вкусом дешёвого чёрного чая."
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "",
                                                "text": "Эрика сначала замирает от шока, а затем медленно прикрывает глаза, робко отвечая на поцелуй. Её руки сжимают ткань его плаща."
                                            },
                                            {
                                                "type": "command",
                                                "name": "set",
                                                "args": [
                                                    "achievement_first_kiss",
                                                    1
                                                ]
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "",
                                                "text": "Они медленно отстраняются друг от друга."
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "(Шёпотом, красная до ушей) Т-ты... ты просто невыносим...",
                                                "expression": "shy",
                                                "side": "right"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "(Прячет лицо в ладонях) Боже мой... я поцеловала клиента... Что я наделала...",
                                                "expression": "cute",
                                                "side": "right"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "danila",
                                                "text": "Я никому не скажу. Это будет нашей коммерческой тайной.",
                                                "expression": "smile",
                                                "side": "left"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "danila",
                                                "text": "(Мысли) Привязываться к гражданским — фатальная ошибка для агента. Но ради этого момента стоило нарушить все уставы КГБ.",
                                                "expression": "thinking",
                                                "side": "left"
                                            },
                                            {
                                                "type": "command",
                                                "name": "set",
                                                "args": [
                                                    "erika_kissed",
                                                    1
                                                ]
                                            }
                                        ]
                                    },
                                    {
                                        "text": "Сделать шаг назад",
                                        "children": [
                                            {
                                                "type": "dialogue",
                                                "character": "danila",
                                                "text": "Спасибо. Я сам справлюсь.",
                                                "expression": "neutral",
                                                "side": "left"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "",
                                                "text": "Данила слегка отодвигается. Эрика опускает глаза, чувствуя неловкость."
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Д-да... конечно. Допивай чай и уходи. Мне нужно закрываться.",
                                                "expression": "sad",
                                                "side": "right"
                                            }
                                        ]
                                    }
                                ]
                            }
                        ],
                        "else": [
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "Спасибо. Я сам.",
                                "expression": "neutral",
                                "side": "left"
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Ой, да больно надо! Допивай и проваливай, мне домой пора!",
                                "expression": "angry",
                                "side": "right"
                            }
                        ]
                    },
                    {
                        "type": "dialogue",
                        "character": "danila",
                        "text": "(Мысли) Пора. Варшава не спит, и мне тоже нельзя расслабляться.",
                        "expression": "serious",
                        "side": "left"
                    },
                    {
                        "type": "command",
                        "name": "set",
                        "args": [
                            "bar_visited",
                            3
                        ]
                    }
                ],
                "else": [
                    {
                        "type": "if",
                        "condition": "bar_visited==1",
                        "then": [
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Данила снова открывает скрипучую дверь бара «Упавший Орёл». Внутри подозрительно шумно."
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Опять ты припёрся?! Я же говорила... (Осекается) Ой. То есть... я собиралась выкидывать это печенье, так что садись.",
                                "expression": "shocked",
                                "side": "right"
                            },
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Эрика с грохотом ставит перед ним тарелку с домашним печеньем. Но внезапно к стойке подваливает огромный пьяный рабочий с завода."
                            },
                            {
                                "type": "dialogue",
                                "character": "worker_1",
                                "text": "Эй, куколка! Харэ болтать с этим хлыщом! Налей-ка мне ещё пинту, да поживее! И сдачу можешь отдать натурой!",
                                "expression": "angry",
                                "side": "right"
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Я... я вам больше не налью! Вы уже едва на ногах стоите! Уходите, иначе я вызову полицию!",
                                "expression": "sad",
                                "side": "right"
                            },
                            {
                                "type": "dialogue",
                                "character": "worker_1",
                                "text": "Полицию?! Да я этот бар по кирпичам разнесу, слышишь, дрянь?!",
                                "expression": "angry",
                                "side": "right",
                                "event": {
                                    "name": "shake_camera",
                                    "args": [
                                        1.0
                                    ]
                                }
                            },
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Рабочий замахивается огромным кулаком, чтобы ударить по стойке. Эрика вскрикивает и зажмуривается. Но удар не достигает цели."
                            },
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Данила, не вставая со стула, молниеносно перехватывает руку рабочего и сдавливает его запястье с нечеловеческой силой. Хруст костей слышен на весь бар."
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "Ты оглох, мусор? Дама сказала, что ты больше не пьёшь.",
                                "expression": "serious_factory",
                                "side": "left"
                            },
                            {
                                "type": "dialogue",
                                "character": "worker_1",
                                "text": "ААА! Пусти! Моя рука! Ты сумасшедший!",
                                "expression": "fear",
                                "side": "right"
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "Пшёл вон. Пока я не сделал из тебя инвалида.",
                                "expression": "angry",
                                "side": "left"
                            },
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Рабочий, скуля, выбегает из бара. В помещении повисает гробовая тишина. Данила спокойно берёт печенье с тарелки и откусывает."
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "(Мысли) Вкусно. И правда домашнее. Но шпиону нельзя привлекать внимание... Чёрт, инстинкты сработали быстрее разума.",
                                "expression": "thinking",
                                "side": "left"
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Т-ты... зачем ты это сделал?! Я бы и сама справилась! У меня... у меня шокер под стойкой есть!",
                                "expression": "shocked",
                                "side": "right"
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "Ага. И пока ты бы его доставала, он бы снёс тебе пол-лица.",
                                "expression": "serious",
                                "side": "left"
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Не делай из меня слабую дуру! Я живу в Восточной Варшаве с рождения! Я... я...",
                                "expression": "sad",
                                "side": "right"
                            },
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Голос Эрики внезапно дрожит. Она опускает голову, и на стойку падают несколько слёз. Адреналин отпускает её, оставляя только страх пережитого момента."
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "С-спасибо... Спасибо тебе, придурок.",
                                "expression": "sad",
                                "side": "right"
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "(Мысли) Она плачет. Я видел смерти товарищей, я пытал врагов, я выживал в тайге... Но женские слёзы — это то, к чему академия КГБ меня не готовила.",
                                "expression": "tired",
                                "side": "left"
                            },
                            {
                                "type": "if",
                                "condition": "erika_affinity>=1",
                                "then": [
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "(Мысли) Она пыталась быть сильной ради меня... Но она просто напуганная девушка.",
                                        "expression": "thinking",
                                        "side": "left"
                                    },
                                    {
                                        "type": "choice",
                                        "options": [
                                            {
                                                "text": "Успокоить её (Погладить по голове)",
                                                "children": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "",
                                                        "text": "Данила тяжело вздыхает. Он протягивает руку и мягко гладит Эрику по макушке, слегка ероша её волосы."
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Ч-что... ЧТО ТЫ ДЕЛАЕШЬ?!",
                                                        "expression": "shocked",
                                                        "side": "right",
                                                        "event": {
                                                            "name": "shake_camera",
                                                            "args": [
                                                                0.5
                                                            ]
                                                        }
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Успокаиваю тебя. Говорят, это помогает.",
                                                        "expression": "smile",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Я ТЕБЕ ЧТО, СОБАКА?! УБРАЛ РУКУ! БЫСТРО!",
                                                        "expression": "cute",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "",
                                                        "text": "Она кричит, но Данила чувствует, как она слегка подаётся навстречу его руке. Её лицо горит от смущения."
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Всё закончилось. Ты в безопасности.",
                                                        "expression": "neutral",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "(Тихо) Я... я знаю. Просто... не смотри на меня сейчас, ладно? Идиот...",
                                                        "expression": "shy",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "command",
                                                        "name": "set",
                                                        "args": [
                                                            "erika_affinity",
                                                            "+1"
                                                        ]
                                                    }
                                                ]
                                            },
                                            {
                                                "text": "Хлопнуть по плечу",
                                                "children": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Ты молодец. Главное, что всё обошлось. Будь сильнее.",
                                                        "expression": "smile",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "(Вытирает слёзы) Да... Ты прав. Я сильная. Спасибо.",
                                                        "expression": "cute",
                                                        "side": "right"
                                                    }
                                                ]
                                            }
                                        ]
                                    }
                                ],
                                "else": [
                                    {
                                        "type": "dialogue",
                                        "character": "danila",
                                        "text": "Не реви. Главное, что всё обошлось.",
                                        "expression": "neutral",
                                        "side": "left"
                                    },
                                    {
                                        "type": "dialogue",
                                        "character": "erika",
                                        "text": "(Вытирает слёзы) Я и не реву! В глаз что-то попало...",
                                        "expression": "cute",
                                        "side": "right"
                                    }
                                ]
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Так... ладно. Давай сделаем вид, что этого не было! Твоё печенье... в общем, оно за счёт заведения на этот раз.",
                                "expression": "shy",
                                "side": "right"
                            },
                            {
                                "type": "command",
                                "name": "set",
                                "args": [
                                    "bar_visited",
                                    2
                                ]
                            }
                        ],
                        "else": [
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Бар «Упавший Орёл». Самое паршивое место в Восточной Варшаве. Сюда приходят не праздновать, а забывать: тяжелую смену на заводе, злую жену и отсутствие перспектив. Дверь скрипит так, словно скулит от боли."
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "(Мысли) Воздух здесь настолько густой от сигаретного дыма и перегара, что его можно резать ножом и мазать на хлеб. Идеальное место для сбора агентурных данных.",
                                "expression": "tired",
                                "side": "left"
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "(Мысли) Пьяные языки не умеют держать секреты. Если Синдикат Обломова где-то и наследил, то местные работяги точно об этом болтают за кружкой тёплого нефильтрованного.",
                                "expression": "thinking",
                                "side": "left"
                            },
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Данила садится за липкий барный стул. Вместо ожидаемого сурового мужика за стойкой стоит миниатюрная девушка с забавными хвостиками. Она так усердно протирает стакан, что тот скрипит."
                            },
                            {
                                "type": "dialogue",
                                "character": "",
                                "text": "Внезапно стакан выскальзывает из её рук и с громким звоном разбивается вдребезги о стойку."
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Ай! Т-то есть... Так и было задумано!",
                                "expression": "shocked",
                                "side": "right"
                            },
                            {
                                "type": "choice",
                                "options": [
                                    {
                                        "text": "Помочь собрать осколки",
                                        "children": [
                                            {
                                                "type": "command",
                                                "name": "set",
                                                "args": [
                                                    "erika_affinity",
                                                    "+1"
                                                ]
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "danila",
                                                "text": "Давай помогу. Тактическая задумка, говоришь?",
                                                "expression": "smile",
                                                "side": "left"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Осторожнее, дурак, порежешься! Я сама могу убрать свою... тактическую ловушку для мышей! С-спасибо...",
                                                "expression": "shy",
                                                "side": "right"
                                            }
                                        ]
                                    },
                                    {
                                        "text": "Молча наблюдать",
                                        "children": [
                                            {
                                                "type": "dialogue",
                                                "character": "danila",
                                                "text": "(Молча скрещивает руки и ждёт)",
                                                "expression": "serious",
                                                "side": "left"
                                            },
                                            {
                                                "type": "dialogue",
                                                "character": "erika",
                                                "text": "Мог бы и помочь бедной девушке! Л-ладно, не очень-то и хотелось!",
                                                "expression": "cute",
                                                "side": "right"
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                "type": "dialogue",
                                "character": "erika",
                                "text": "Ну так что? Вот меню. Что будешь заказывать?",
                                "expression": "neutral",
                                "side": "right"
                            },
                            {
                                "type": "choice",
                                "options": [
                                    {
                                        "text": "Купить дешёвое пиво (10 zl) - Восстановить энергию",
                                        "children": [
                                            {
                                                "type": "if",
                                                "condition": "money>=10",
                                                "then": [
                                                    {
                                                        "type": "command",
                                                        "name": "set",
                                                        "args": [
                                                            "money",
                                                            "-10"
                                                        ]
                                                    },
                                                    {
                                                        "type": "command",
                                                        "name": "set",
                                                        "args": [
                                                            "energy",
                                                            "+20"
                                                        ]
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Налей кружку своего знаменитого разливного.",
                                                        "expression": "neutral",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Держи. И не думай, что я налила тебе меньше пены, потому что ты мне понравился! Просто... кран сломался! Пей!",
                                                        "expression": "happy",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "(Мысли) Отличная дрянь. Отбивает все вкусовые рецепторы на неделю вперёд.",
                                                        "expression": "thinking_factory",
                                                        "side": "left"
                                                    }
                                                ],
                                                "else": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Чёрт... У меня даже десятки нет.",
                                                        "expression": "sad",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Денег нет? Ох... Ладно, на улице холодно. Держи воду.",
                                                        "expression": "sad",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "А в следующий раз я принесу тебе печенье... Т-то есть, просроченное магазинное печенье! Которое я собиралась выкинуть! Б-бака!",
                                                        "expression": "shy",
                                                        "side": "right"
                                                    }
                                                ]
                                            }
                                        ]
                                    },
                                    {
                                        "text": "Купить шот элитной польской водки (50 zl) - Максимум слухов!",
                                        "children": [
                                            {
                                                "type": "if",
                                                "condition": "money>=50",
                                                "then": [
                                                    {
                                                        "type": "command",
                                                        "name": "set",
                                                        "args": [
                                                            "money",
                                                            "-50"
                                                        ]
                                                    },
                                                    {
                                                        "type": "command",
                                                        "name": "set",
                                                        "args": [
                                                            "erika_affinity",
                                                            "+1"
                                                        ]
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Пятьдесят злотых. Налей мне самой чистой 'Слёзы Зубра', Эрика. И скажи... что вообще в городе происходит?",
                                                        "expression": "serious",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Эй! Откуда ты знаешь моё имя?! А... бейдж. (Краснеет) А ты, я погляжу, при деньгах.",
                                                        "expression": "shy",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "КХА! Ядрёная... Так что насчёт слухов?",
                                                        "expression": "panting",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Слушай внимательно. Приютские сироты вдруг начали пропадать с улиц. Говорят, их пакуют в чёрные фургоны.",
                                                        "expression": "neutral",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "(Наклоняется очень близко, переходя на шёпот) А кто пакует? Правительство! Отвозят их в какую-то 'Академию Разведки', откармливают кебабами и заставляют избивать манекены.",
                                                        "expression": "cute",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Ты слишком близко. Я чувствую запах твоего шампуня.",
                                                        "expression": "surprised",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "ААА! И-извини! Я просто... увлеклась! (Отпрыгивает назад, краснея)",
                                                        "expression": "shocked",
                                                        "side": "right",
                                                        "event": {
                                                            "name": "shake_camera",
                                                            "args": [
                                                                1.0
                                                            ]
                                                        }
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Н-но это ещё цветочки. Главная беда пришла с Востока. Русский по имени Карл Обломов. Он купил фасовочный завод на окраине.",
                                                        "expression": "sad",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Мои постоянные клиенты, работяги с завода, клянутся матерью, что в паллетах с красным скотчем нет никакого джема. Они отгружают их на товарняки до Обояни каждую неделю.",
                                                        "expression": "neutral",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Товарняки до Обояни? Интересно... Спасибо за водку, Эрика. И за болтливость.",
                                                        "expression": "thinking",
                                                        "side": "left"
                                                    }
                                                ],
                                                "else": [
                                                    {
                                                        "type": "dialogue",
                                                        "character": "danila",
                                                        "text": "Ой. Кошелёк-то пуст.",
                                                        "expression": "sad",
                                                        "side": "left"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "Денег нет? Ох... Ладно, на улице холодно. Держи воду.",
                                                        "expression": "sad",
                                                        "side": "right"
                                                    },
                                                    {
                                                        "type": "dialogue",
                                                        "character": "erika",
                                                        "text": "А в следующий раз я принесу тебе печенье... Т-то есть, просроченное магазинное печенье! Которое я собиралась выкинуть! Б-бака!",
                                                        "expression": "shy",
                                                        "side": "right"
                                                    }
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                "type": "dialogue",
                                "character": "danila",
                                "text": "(Мысли) Пора уходить. От местной атмосферы начинает болеть голова.",
                                "expression": "tired",
                                "side": "left"
                            },
                            {
                                "type": "command",
                                "name": "set",
                                "args": [
                                    "bar_visited",
                                    1
                                ]
                            }
                        ]
                    }
                ]
            }
        ]
    },
    {
        "type": "command",
        "name": "transition",
        "args": [
            "fade_out"
        ]
    },
    {
        "type": "command",
        "name": "scene",
        "args": [
            "WorldMap"
        ]
    }
]