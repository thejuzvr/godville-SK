defmodule GodvilleSk.GameData do
  @moduledoc """
  Статические данные игры, перенесенные из TypeScript репозитория.
  """

  @monsters [
    # Обычные враги (25)
    %{
      id: "mudcrab",
      name: "Грязевой краб",
      hp: 10,
      max_hp: 10,
      damage: 1,
      xp: 5,
      level: 1,
      ac: 10
    },
    %{id: "skeever", name: "Злокрыс", hp: 15, max_hp: 15, damage: 2, xp: 8, level: 1, ac: 11},
    %{id: "wolf", name: "Волк", hp: 20, max_hp: 20, damage: 3, xp: 15, level: 1, ac: 11},
    %{id: "skeleton", name: "Скелет", hp: 25, max_hp: 25, damage: 4, xp: 20, level: 2, ac: 10},
    %{
      id: "frost_spider",
      name: "Морозный паук",
      hp: 30,
      max_hp: 30,
      damage: 4,
      xp: 25,
      level: 2,
      ac: 12
    },
    %{id: "scamp", name: "Скамп", hp: 35, max_hp: 35, damage: 5, xp: 30, level: 3, ac: 12},
    %{
      id: "wolf_leader",
      name: "Волк-вожак",
      hp: 40,
      max_hp: 40,
      damage: 5,
      xp: 35,
      level: 3,
      ac: 12
    },
    %{id: "bandit", name: "Бандит", hp: 45, max_hp: 45, damage: 6, xp: 40, level: 3, ac: 13},
    %{id: "forsworn", name: "Изгой", hp: 55, max_hp: 55, damage: 7, xp: 50, level: 4, ac: 13},
    %{id: "draugr", name: "Драугр", hp: 60, max_hp: 60, damage: 8, xp: 60, level: 4, ac: 14},
    %{
      id: "ice_wolf",
      name: "Ледяной волк",
      hp: 70,
      max_hp: 70,
      damage: 10,
      xp: 75,
      level: 5,
      ac: 13
    },
    %{id: "bear", name: "Медведь", hp: 80, max_hp: 80, damage: 12, xp: 90, level: 5, ac: 13},
    %{id: "vampire", name: "Вампир", hp: 90, max_hp: 90, damage: 13, xp: 100, level: 6, ac: 14},
    %{
      id: "spriggan",
      name: "Спригган",
      hp: 100,
      max_hp: 100,
      damage: 14,
      xp: 120,
      level: 6,
      ac: 13
    },
    %{
      id: "sabre_cat",
      name: "Саблезуб",
      hp: 110,
      max_hp: 110,
      damage: 16,
      xp: 135,
      level: 6,
      ac: 14
    },
    %{id: "troll", name: "Тролль", hp: 120, max_hp: 120, damage: 15, xp: 150, level: 7, ac: 14},
    %{
      id: "draugr_executioner",
      name: "Драугр-палач",
      hp: 130,
      max_hp: 130,
      damage: 17,
      xp: 165,
      level: 7,
      ac: 15
    },
    %{id: "falmer", name: "Фалмер", hp: 140, max_hp: 140, damage: 16, xp: 180, level: 7, ac: 14},
    %{
      id: "cave_bear",
      name: "Пещерный медведь",
      hp: 160,
      max_hp: 160,
      damage: 20,
      xp: 220,
      level: 8,
      ac: 15
    },
    %{
      id: "fire_atronach",
      name: "Огненный атронах",
      hp: 150,
      max_hp: 150,
      damage: 22,
      xp: 250,
      level: 8,
      ac: 13
    },
    %{
      id: "snow_troll",
      name: "Ледяной тролль",
      hp: 200,
      max_hp: 200,
      damage: 25,
      xp: 350,
      level: 10,
      ac: 15
    },
    %{
      id: "ice_atronach",
      name: "Ледяной атронах",
      hp: 250,
      max_hp: 250,
      damage: 28,
      xp: 450,
      level: 11,
      ac: 16
    },
    %{
      id: "draugr_warlord",
      name: "Драугр-военачальник",
      hp: 300,
      max_hp: 300,
      damage: 32,
      xp: 550,
      level: 12,
      ac: 17
    },
    %{
      id: "master_vampire",
      name: "Мастер-вампир",
      hp: 400,
      max_hp: 400,
      damage: 38,
      xp: 800,
      level: 14,
      ac: 16
    },
    %{
      id: "dragon",
      name: "Дракон",
      hp: 500,
      max_hp: 500,
      damage: 45,
      xp: 1000,
      level: 15,
      ac: 18
    },

    # Абсурдные/комичные враги (20)
    %{
      id: "absurd_sweetroll",
      name: "Агрессивный сладкий рулет",
      hp: 5,
      max_hp: 5,
      damage: 1,
      xp: 5,
      level: 1,
      ac: 5
    },
    %{
      id: "absurd_cabbage",
      name: "Очень злой кочан капусты",
      hp: 8,
      max_hp: 8,
      damage: 1,
      xp: 10,
      level: 1,
      ac: 8
    },
    %{
      id: "absurd_puddle",
      name: "Пьяная грязевая лужа",
      hp: 15,
      max_hp: 15,
      damage: 2,
      xp: 12,
      level: 1,
      ac: 10
    },
    %{
      id: "absurd_panic_wolf",
      name: "Волк-паникер",
      hp: 20,
      max_hp: 20,
      damage: 1,
      xp: 15,
      level: 2,
      ac: 12
    },
    %{
      id: "absurd_headless_skel",
      name: "Скелет, потерявший череп",
      hp: 25,
      max_hp: 25,
      damage: 3,
      xp: 22,
      level: 2,
      ac: 10
    },
    %{
      id: "absurd_wooden_bandit",
      name: "Бандит с деревянным мечом",
      hp: 40,
      max_hp: 40,
      damage: 2,
      xp: 30,
      level: 2,
      ac: 12
    },
    %{
      id: "absurd_crab_monocle",
      name: "Грязевой краб с моноклем",
      hp: 35,
      max_hp: 35,
      damage: 5,
      xp: 40,
      level: 3,
      ac: 15
    },
    %{
      id: "absurd_scamp_seller",
      name: "Скамп-коммивояжер",
      hp: 45,
      max_hp: 45,
      damage: 4,
      xp: 55,
      level: 3,
      ac: 12
    },
    %{
      id: "absurd_fat_skeever",
      name: "Злокрыс переросток",
      hp: 60,
      max_hp: 60,
      damage: 6,
      xp: 60,
      level: 3,
      ac: 11
    },
    %{
      id: "absurd_poet_orc",
      name: "Орк-поэт (очень плохой)",
      hp: 70,
      max_hp: 70,
      damage: 5,
      xp: 80,
      level: 4,
      ac: 14
    },
    %{
      id: "absurd_old_draugr",
      name: "Драугр с радикулитом",
      hp: 50,
      max_hp: 50,
      damage: 8,
      xp: 65,
      level: 4,
      ac: 12
    },
    %{
      id: "absurd_vegan_vampire",
      name: "Вампир-вегетарианец",
      hp: 80,
      max_hp: 80,
      damage: 7,
      xp: 90,
      level: 5,
      ac: 13
    },
    %{
      id: "absurd_bear_unicycle",
      name: "Медведь на моноцикле",
      hp: 100,
      max_hp: 100,
      damage: 12,
      xp: 150,
      level: 5,
      ac: 13
    },
    %{
      id: "absurd_sleepy_sabre",
      name: "Саблезуб с бессонницей",
      hp: 120,
      max_hp: 120,
      damage: 18,
      xp: 180,
      level: 6,
      ac: 11
    },
    %{
      id: "absurd_falmer_map",
      name: "Фалмер с картой",
      hp: 90,
      max_hp: 90,
      damage: 10,
      xp: 160,
      level: 7,
      ac: 14
    },
    %{
      id: "absurd_troll_hypo",
      name: "Тролль-ипохондрик",
      hp: 180,
      max_hp: 180,
      damage: 12,
      xp: 250,
      level: 8,
      ac: 12
    },
    %{
      id: "absurd_troll_sweater",
      name: "Снежный тролль в свитере",
      hp: 220,
      max_hp: 220,
      damage: 20,
      xp: 380,
      level: 9,
      ac: 16
    },
    %{
      id: "absurd_doom_chicken",
      name: "Курица судного дня",
      hp: 1,
      max_hp: 1,
      damage: 50,
      xp: 500,
      level: 10,
      ac: 20
    },
    %{
      id: "absurd_dwemer_teapot",
      name: "Двемерская чайница убийца",
      hp: 250,
      max_hp: 250,
      damage: 25,
      xp: 600,
      level: 11,
      ac: 18
    },
    %{
      id: "absurd_forgetful_dragon",
      name: "Дракон, забывший крик",
      hp: 450,
      max_hp: 450,
      damage: 15,
      xp: 850,
      level: 14,
      ac: 15
    }
  ]

  @items [
    %{
      id: "food_bread",
      name: "Хлеб",
      type: :food,
      rarity: :common,
      description: "Простая, но сытная еда. Восстанавливает немного здоровья.",
      weight: 1.0
    },
    %{
      id: "food_cheese",
      name: "Козий сыр",
      type: :food,
      rarity: :common,
      description:
        "Знаменитый скайримский сыр. Говорят, его можно съесть килограммами в пылу битвы.",
      weight: 0.8
    },
    %{
      id: "food_venison",
      name: "Жареная оленина",
      type: :food,
      rarity: :uncommon,
      description: "Вкусно приготовленное мясо. Дает силы для долгих путешествий.",
      weight: 1.5
    },
    %{
      id: "food_fish",
      name: "Соленая рыба",
      type: :food,
      rarity: :common,
      description: "Простая еда, которую можно взять в дорогу.",
      weight: 0.5
    },
    %{
      id: "food_apple",
      name: "Яблоко",
      type: :food,
      rarity: :common,
      description: "Сладкое яблоко из сада. Восстанавливает немного сил.",
      weight: 0.2
    },
    %{
      id: "potion_health_weak",
      name: "Слабое зелье лечения",
      type: :potion,
      rarity: :common,
      description: "Красная жидкость с привкусом можжевельника. Заживляет мелкие царапины.",
      weight: 0.4
    },
    %{
      id: "weapon_iron_sword",
      name: "Железный меч",
      type: :weapon,
      rarity: :common,
      damage: 5,
      description: "Тяжелый и не слишком острый, но зато надежный путь к победе.",
      weight: 4.5
    },
    %{
      id: "weapon_steel_sword",
      name: "Стальной меч",
      type: :weapon,
      rarity: :uncommon,
      damage: 8,
      description: "Хорошо сбалансированный клинок, достоин настоящего воина.",
      weight: 5.0
    },
    %{
      id: "armor_leather",
      name: "Кожаная броня",
      type: :armor,
      slot: :torso,
      armor: 5,
      description: "Легкая защита, не стесняющая движений. Пахнет дубленой кожей.",
      weight: 6.0
    },
    %{
      id: "gem_garnet",
      name: "Гранат",
      type: :gem,
      rarity: :uncommon,
      description: "Небольшой красный камень. Красивый, но бесполезный в бою.",
      weight: 0.3
    },
    %{
      id: "gem_diamond",
      name: "Бриллиант",
      type: :gem,
      rarity: :rare,
      description: "Редкий и очень дорогой драгоценный камень. Мечта любого вора.",
      weight: 0.2
    }
  ]

  def get_item_by_name(name) do
    Enum.find(@items, fn item -> item.name == name end)
  end

  @quests [
    %{
      id: "bounty_bandits_whiterun",
      name: "Награда за бандитов",
      type: :bounty,
      steps: 5,
      target_count: 5,
      reward: 150,
      level: 3
    },
    %{
      id: "side_spriggan_whiterun",
      name: "Сердце сприггана",
      type: :bounty,
      steps: 4,
      target_count: 4,
      reward: 113,
      level: 4
    },
    %{
      id: "main_dragon_rising",
      name: "Дракон в небе",
      type: :bounty,
      steps: 10,
      target_count: 10,
      reward: 500,
      level: 10
    },
    %{
      id: "delivery_wine",
      name: "Доставка вина в таверну",
      type: :delivery,
      steps: 3,
      reward: 80,
      level: 2
    },
    %{
      id: "delivery_letter",
      name: "Доставить письмо ярлу",
      type: :delivery,
      steps: 4,
      reward: 100,
      level: 3
    },
    %{
      id: "delivery_supplies",
      name: "Снабжение для стражи",
      type: :delivery,
      steps: 5,
      reward: 130,
      level: 4
    },
    %{
      id: "gather_herbs",
      name: "Сбор лечебных трав",
      type: :gathering,
      steps: 4,
      target_count: 6,
      reward: 60,
      level: 1
    },
    %{
      id: "gather_ores",
      name: "Добыча руды в шахте",
      type: :gathering,
      steps: 5,
      target_count: 8,
      reward: 90,
      level: 3
    },
    %{
      id: "gather_gems",
      name: "Поиск самоцветов",
      type: :gathering,
      steps: 6,
      target_count: 5,
      reward: 150,
      level: 5
    }
  ]

  @dungeon_room_events [
    %{type: :monster, weight: 30, msg: "Встретил монстра: ", effect: :combat},
    %{type: :treasure, weight: 15, msg: "Нашел сундук! Получено: ", effect: :loot},
    %{type: :trap, weight: 15, msg: "Попал в ловушку! -", effect: :damage},
    %{type: :rest, weight: 10, msg: "Нашел безопасное место. Отдохнул. +", effect: :heal},
    %{type: :empty, weight: 20, msg: "Пустая комната. Иду дальше...", effect: :none},
    %{type: :secret, weight: 10, msg: "Секретная комната! Нашел: ", effect: :bonus}
  ]

  @locations [
    "Солитьюд",
    "Виндхельм",
    "Вайтран",
    "Маркарт",
    "Рифтен",
    "Данстар",
    "Винтерхолд",
    "Морфал",
    "Фолкрит",
    "Ривервуд",
    "Айварстед",
    "Драконий Мост",
    "Рорикстед",
    "Шорс Стоун",
    "Картвастен",
    "Хелген",
    "Свифт Крик",
    "Камень Шора",
    "Ричвуд",
    "Деревня Скалов",
    "Воронья Скала",
    "Высокий Хротгар",
    "Черный Предел",
    "Лабиринтиан",
    "Глотка Мира",
    "Устенгрев",
    "Крипта Ночной Пустоты"
  ]

  @location_types %{
    "Солитьюд" => :city,
    "Виндхельм" => :city,
    "Вайтран" => :city,
    "Маркарт" => :city,
    "Рифтен" => :city,
    "Данстар" => :city,
    "Винтерхолд" => :city,
    "Морфал" => :city,
    "Фолкрит" => :city
  }

  @tavern_rumors [
    "Говорят, в пещере к северу появился странный свет...",
    "Бандиты снова грабят торговцев на дороге к Рифтену",
    "В подземелье к востоку видели древнее сокровище",
    "Стражник шепнул, что Изгои планируют нападение",
    "Кто-то видел редкого зверя в лесу неподалеку",
    "Торговец рассказал о заброшенной шахте с привидениями",
    "Ходят слухи о драконьем гнезде в горах",
    "В таверне появился подозрительный незнакомец в черном",
    "Говорят, норд из деревни видел привидение у старой могилы",
    "На болотах видели странные огни по ночам"
  ]

  @night_events [
    %{msg: "Ночью кто-то крадется в темноте...", effect: :ambush},
    %{msg: "Звезды яркие сегодня. Приятная ночь.", effect: :rest},
    %{msg: "Вдалеке воет волк. Холодно.", effect: :none},
    %{msg: "Луна освещает путь. Приятная ночь для отдыха.", effect: :rest},
    %{msg: "Слышал странные звуки в кустах...", effect: :ambush},
    %{msg: "Ночная тишина. Только ветер шелестит.", effect: :none}
  ]

  @dungeons [
    %{id: "dungeon_falmer_cave", name: "Пещера Фалмеров", steps: 5, difficulty: 3},
    %{id: "dungeon_draugr_tomb", name: "Гробница Драугров", steps: 6, difficulty: 4},
    %{id: "dungeon_dwemer_ruins", name: "Руины Двемеров", steps: 7, difficulty: 5},
    %{id: "dungeon_orphan_cave", name: "Сиротская пещера", steps: 4, difficulty: 2},
    %{id: "dungeon_ravine", name: "Ущелье Разбойников", steps: 5, difficulty: 3}
  ]

  @thoughts [
    # Обычные (25)
    "Может, податься в наемники?",
    "Стрела в колено - это больно.",
    "Кто-то украл мой сладкий рулет...",
    "Скайрим для нордов!",
    "Холодно тут.",
    "Нужно заточить меч, он затупился.",
    "Говорят, в Рифтене неспокойно.",
    "Где бы раздобыть зелье запаса сил?",
    "Слышал, Изгои опять нападают на караваны.",
    "Небо сегодня чистое. Как перед бурей.",
    "Надо бы проверить припасы.",
    "И зачем я только полез в эти руины...",
    "Шум ветра напоминает вой волков.",
    "Местные жители смотрят на меня с подозрением.",
    "Только бы не встретить тролля.",
    "Хорошая кружка эля сейчас бы не помешала.",
    "Кажется, у меня в сапоге камень.",
    "Этот доспех слишком тяжелый.",
    "Клянусь Талосом, я устал.",
    "Интересно, Седобородые когда-нибудь спускаются вниз?",
    "Нужно найти торговца с хорошим запасом септимов.",
    "Ночью в лесу слишком тихо.",
    "Как бы не подхватить каменную подагру.",
    "Драконы... сказки стали явью.",
    "Надеюсь, стража не обратит на меня внимания.",

    # Повествовательные (15)
    "Странное чувство. Будто за мной кто-то наблюдает из-за деревьев...",
    "Ветер доносит запах дыма из деревни. Надеюсь, там всё в порядке.",
    "Эти руины видели ещё первых нордов. Сколько они простоят после меня?",
    "Луна заглядывает сквозь ветки деревьев, освещая путь. Красиво, но неспокойно.",
    "Каждый шаг по этой земле - шаг в историю. Или в могилу.",
    "Звенит в ушах от тишины. Обычно это значит, что что-то рядом.",
    "Странно видеть, как природа здесь всё забирает обратно. Ржавчина, мох, пыль.",
    "Эхо шагов в гробнице пугает больше, чем любой монстр.",
    "Время здесь течёт инако. Небо меняется, а я всё ещё здесь.",
    "Помню, в детстве боялся темноты. Теперь сам становлюсь темнотой.",
    "Стальной блеск доспеха - моя гордость. Хоть и царапины уже повсюду.",
    "Говорят, драконы помнят всё. Интересно, что они думают о нас?",
    "Эти стены видели сотни таких как я. Большинство не вернулось.",
    "Ветер шепчет на древнем языке. Иногда кажется, что понимаю.",
    "Запах леса успокаивает. Но что-то внутри всё равно рвётся в бой.",

    # Абсурдные (20)
    "Почему стражники всегда говорят об одной и той же стреле? У них что, клуб такой?",
    "Интересно, если побрить каджита, он обидится?",
    "А что если Скайрим — это просто песочница какого-то великана?",
    "Почему торговцы покупают у меня окровавленные железные кинжалы пачками?",
    "Сварил зелье из пальца великана и крыла мотылька. Пахнет клубникой.",
    "Кажется, этот грязевой краб ругался матом.",
    "Кто зажигает свечи в древних гробницах, которым тысяча лет? Драугры-завхозы?",
    "Если я крикну 'Фус Ро Да' на курицу, меня объявят врагом государства...",
    "Интересно, у драконов бывает изжога?",
    "Мой компаньон опять застрял в дверном проеме. Классика.",
    "Попробовал прочесть Древний Свиток, но там только рецепт овсянки.",
    "Почему в каждом сундуке в гробницах лежат свежие яблоки?",
    "Слышал, один ярл случайно съел сыр из мамонта и завыл на луну.",
    "Что-то мне подсказывает, что я забыл выключить утюг. Стоп, что такое утюг?",
    "Этот медведь посмотрел на меня так, будто я должен ему денег.",
    "Кажется, моя лошадь умнее местного ярла.",
    "Почему никто никогда не ходит в туалет в этом мире?",
    "Я могу нести 50 мечей, но 51-й меня пригвоздит к земле. Магия!",
    "Съел 40 кочанов капусты в бою и ни капли не подавился.",
    "Интересно, мама гордилась бы тем, что я граблю урны в гробницах?"
  ]

  @thoughts_by_context [
    {:dungeon,
     [
       "Стены давят. Здесь не было живых уже тысячу лет.",
       "Эхо шагов пугает. Или это не эхо?",
       "Свеча в гробнице? Кто-то тут недавно был.",
       "Пахнет древностью и страхом.",
       "Только бы не нарваться на драугра.",
       "Эти надписи на стенах - предупреждение или проклятие?"
     ]},
    {:city,
     [
       "Народ шумит. Надо бы найти работу.",
       "Таверна манит. Но сначала дело.",
       "Стража смотрит в оба. Не выделяться бы.",
       "Торговцы глядят на кошелёк, не на товар.",
       "Город живёт своей жизнью. А я - чужак.",
       "Здесь легко затеряться. Или найти работу."
     ]},
    {:forest,
     [
       "Тишина обманчива. Здесь что-то есть.",
       "Деревья шепчутся. Старые secrets.",
       "Солнечный свет пробивается сквозь листву.",
       "Тропа ведёт куда-то. Надо идти осторожно.",
       "Лес дышит. Запах мха и жизни.",
       "Птицы замолкли. Опасность рядом."
     ]},
    {:low_level,
     [
       "Ещё немного - и буду настоящим воином.",
       "Опыт приходит с каждым боем.",
       "Меч кажется тяжелее, чем в первый раз.",
       "Учусь читать врага. Пока не очень получается.",
       "Каждый урок даётся нелегко.",
       "Нужно больше практики. И зелья."
     ]},
    {:high_level,
     [
       "Слабые монстры уже не проблема. А что тогда?",
       "Опыт - это хорошо. Но цена высока.",
       "Многое повидал. Многое забыл.",
       "Сила - не всё. Но без неё - ничего.",
       "Враги становятся сильнее. Приходится меняться.",
       "Уровень растёт. Вопрос - успею ли за сложностью?"
     ]}
  ]

  @random_events [
    # Обычные (25)
    %{msg: "Нашел старую монету на дороге.", effect: :none},
    %{msg: "Споткнулся о корень, но ничего не сломал.", effect: :none},
    %{msg: "Выпил воды из ручья и почувствовал себя лучше.", effect: :heal},
    %{msg: "Увидел в небе пролетающего дракона. Укрылся за камнем.", effect: :none},
    %{msg: "Нашел у дороги брошенную телегу. Ничего ценного.", effect: :none},
    %{msg: "Заметил вдалеке отряд стражи. Разминулись.", effect: :none},
    %{msg: "Насобирал немного горных цветов.", effect: :heal},
    %{msg: "Помог странствующему торговцу починить колесо.", effect: :heal},
    %{msg: "Посидел у костра охотников, немного отдохнул.", effect: :heal},
    %{msg: "Наткнулся на останки животного. Свежие следы.", effect: :none},
    %{msg: "Обнаружил спрятанный кошелек с парой септимов.", effect: :none},
    %{msg: "Заметил красивый закат. На душе статуло спокойно.", effect: :heal},
    %{msg: "Услышал вой волков. Шаг невольно ускорился.", effect: :none},
    %{msg: "Встретил каджита, который пытался продать мне лунный сахар.", effect: :none},
    %{msg: "Нашел старый ржавый кинжал. Выбросил.", effect: :none},
    %{msg: "Чуть не угодил в капкан браконьера.", effect: :none},
    %{msg: "Словил бабочку. Подумал и отпустил.", effect: :heal},
    %{msg: "Укрылся от холодного ветра в небольшой пещерке.", effect: :heal},
    %{msg: "Перешел реку по скользкому бревну. Вымок, но жив.", effect: :none},
    %{msg: "Насобирал вкусных ягод у дороги.", effect: :heal},
    %{msg: "Показалось, что за мной следят.", effect: :none},
    %{msg: "Встретил барда, поющего фальшивую песню.", effect: :none},
    %{msg: "Наткнулся на алтарь Кинарет. Помолился о безопасном пути.", effect: :heal},
    %{msg: "Запутался в густом тумане, но вскоре вышел на тракт.", effect: :none},
    %{msg: "Слушал пение птиц. Какая редкость на севере.", effect: :heal},

    # Абсурдные (20)
    %{msg: "С неба упал мамонт. Посмотрел по сторонам и побежал дальше.", effect: :none},
    %{msg: "Встретил краба в двемерском шлеме. Он отсалютовал клешней.", effect: :none},
    %{msg: "Случайно наступил на сладкий рулет. Трагедия.", effect: :none},
    %{msg: "Увидел, как два дракона спорят, кто из них красивее рычит.", effect: :none},
    %{
      msg: "Нашел письмо: 'Ждем тебя на праздник'. Письмо было адресовано медведю.",
      effect: :none
    },
    %{msg: "Попытался заговорить с курицей. Курица презрительно промолчала.", effect: :none},
    %{msg: "Дерево попыталось мне что-то продать, но я вовремя убежал.", effect: :none},
    %{msg: "Нашел лужу, которая отражала меня в виде орка-балерины.", effect: :none},
    %{
      msg: "Стражник подошел, сказал 'Ой, извини, перепутал' и убежал спиной вперед.",
      effect: :none
    },
    %{msg: "Моя тень споткнулась и упала. Пришлось ждать 5 минут.", effect: :none},
    %{msg: "Лошадь пролетела надо мной задом наперед, весело ржа.", effect: :none},
    %{msg: "Споткнулся о воздух. Серьезно, там ничего не было!", effect: :none},
    %{
      msg: "Нашел меч, который стонет каждый раз, когда я его достаю. Засунул обратно.",
      effect: :none
    },
    %{msg: "Встретил тролля, который сидел на камне и решал судоку.", effect: :none},
    %{msg: "С неба пошел дождь из сырных голов. Рай существует.", effect: :heal},
    %{msg: "Невидимый хор спел песню о моих грязных сапогах.", effect: :none},
    %{
      msg: "Из кустов выпрыгнул старик, прокричал 'ВАББАДЖЕК!' и превратился в бабочку.",
      effect: :none
    },
    %{msg: "Манекен в чужом доме повернул ко мне голову и подмигнул. Я ушел.", effect: :none},
    %{msg: "Сел отдохнуть на камень, а камень оказался овцой. Овца не возражала.", effect: :heal},
    %{msg: "Словил снежинку ртом. Оказалось, это был прах драугра. Тьфу.", effect: :none}
  ]

  @sovngarde_tasks [
    %{
      id: "sq_01",
      title: "Найти носок Торуга",
      description:
        "Древний норд Торуг потерял свой любимый носок где-то в Зале доблести. Он очень расстроен."
    },
    %{
      id: "sq_02",
      title: "Выслушать песню Олафа",
      description:
        "Бард Олаф Одноглазый хочет исполнить свою 18-часовую балладу о грязекрабе. Нужно просто... выслушать."
    },
    %{
      id: "sq_03",
      title: "Посчитать медовые бочки",
      description: "Исграмор хочет провести инвентаризацию меда. Он постоянно сбивается со счета."
    },
    %{
      id: "sq_04",
      title: "Помолиться Шору",
      description:
        "Жрец просит вас вознести молитву Шору, чтобы он смилостивился и отпустил вас пораньше."
    },
    %{
      id: "sq_05",
      title: "Поймать призрачную курицу",
      description:
        "Призрачная курица снова сбежала и доставляет всем неудобства. Ее нужно поймать."
    },
    %{
      id: "sq_06",
      title: "Организовать танцы у костра",
      description: "Норды хотят устроить танцы, но никто не помнит, как танцевать."
    },
    %{
      id: "sq_07",
      title: "Собрать подписи за Wi-Fi",
      description:
        "Молодой норд хочет подать петицию Шору: 'Дайте Совнгарду Wi-Fi и зарядку для амулетов'."
    },
    %{
      id: "sq_08",
      title: "Проверить, работает ли 'фус ро да' здесь",
      description: "Один из воинов утверждает, что крик дракона может открыть портал домой."
    },
    %{
      id: "sq_09",
      title: "Конкурс 'Кто громче рыгнет'",
      description: "Традиционное состязание нордов. Ты участвуешь по умолчанию."
    },
    %{
      id: "sq_10",
      title: "Найти пропавший тост Исграмора",
      description: "Исграмор начал тост 300 лет назад и забыл, как его закончить."
    },
    %{
      id: "sq_11",
      title: "Сфотографировать всех героев",
      description:
        "Призрачный Instagram-блогер просит сделать селфи со всеми легендами. #БессмертиеВКадре"
    },
    %{
      id: "sq_12",
      title: "Помочь норду с 'прокрастинацией'",
      description: "Один норд жалуется, что 'всё откладывает на потом', но потома здесь нет."
    },
    %{
      id: "sq_13",
      title: "Разделить кусок хлеба",
      description: "Два норда спорят, кому достанется последний кусок хлеба с мёдом. Ты — судья."
    },
    %{
      id: "sq_14",
      title: "Обучить Исграмора 'автосейвам'",
      description: "Исграмор не понимает, почему нельзя сохранить пир на потом."
    },
    %{
      id: "sq_15",
      title: "Организовать книжный клуб",
      description:
        "Норды хотят обсудить 'Песнь о Локире', но никто не читал дальше первой страницы."
    },
    %{
      id: "sq_16",
      title: "Найти источник 'странного запаха'",
      description: "Подозревают призрачную рыбу или носок Торуга №2."
    },
    %{
      id: "sq_17",
      title: "Соцопрос 'Перед смертью'",
      description: "Социолог собирает данные. Большинство говорят: 'Почему я без штанов?'"
    },
    %{
      id: "sq_18",
      title: "Вечер караоке",
      description: "Бард поет 'Реквием', но все просят 'что-нибудь повеселее'."
    },
    %{
      id: "sq_19",
      title: "Выход из образа",
      description:
        "Один воин до сих пор думает, что сражается с драконом. Верни его в реальность."
    },
    %{
      id: "sq_20",
      title: "Собрать отзывы о Совнгарде",
      description: "Оставь отзыв: '5 звёзд, но нет душа для бани'."
    }
  ]

  @sovngarde_thoughts [
    "Так вот он какой, Совнгард. Меда и правда много.",
    "Надеюсь, мое тело там внизу никто не обчистил.",
    "Интересно, а здесь есть драконы? Наверное, добрые.",
    "Кажется, я видел того парня в Хелгене. Неловко получилось.",
    "Вечная жизнь... немного скучновата, если честно.",
    "Нужно было все-таки выпить то зелье здоровья.",
    "Ветер здесь не дует... странно для места, где всегда пир.",
    "Может, Шор просто устал и ушёл на покой?",
    "Я сражался за славу, а теперь пересчитываю бочки с мёдом.",
    "Хотел бы я знать, помнит ли кто-то моё имя в Тамриэле...",
    "Если я умру в Совнгарде — куда попаду? В Совнгард Совнгарда?",
    "Здесь даже Wi-Fi бы не помог — все равно не отвечают в чате гильдии.",
    "Торуг всё ещё ищет носок? А второй-то где?",
    "Может, просто сказать 'фус ро да' и улететь домой?",
    "Бард снова поёт про грязекраба... а я-то думал, худшее — это 'Реквием'.",
    "Если я выпью весь мед, стану богом? Или просто диабетиком?",
    "Квест 'Поймать курицу' сложнее, чем убить Альдуина. Серьёзно."
  ]

  def monsters, do: @monsters
  def items, do: @items
  def quests, do: @quests
  def locations, do: @locations
  def thoughts, do: @thoughts
  def thoughts_by_context, do: @thoughts_by_context
  def random_events, do: @random_events
  def sovngarde_tasks, do: @sovngarde_tasks
  def sovngarde_thoughts, do: @sovngarde_thoughts

  def get_context_thought(location, level) when is_binary(location) do
    context = determine_context(location, level)
    context_thoughts = Keyword.get(@thoughts_by_context, context, [])
    random_thought(context_thoughts, @thoughts)
  end

  defp determine_context(location, level) do
    location_lower = String.downcase(location)

    cond do
      String.contains?(location_lower, ["пещера", "гробница", "руины", "подземелье", "замок"]) ->
        :dungeon

      String.contains?(location_lower, ["город", "деревня", "поселение"]) ->
        :city

      String.contains?(location_lower, ["лес", "роща"]) ->
        :forest

      level < 5 ->
        :low_level

      level >= 10 ->
        :high_level

      true ->
        nil
    end
  end

  defp random_thought(context_thoughts, default_thoughts) do
    if context_thoughts != [] && :rand.uniform() < 0.4 do
      Enum.random(context_thoughts)
    else
      Enum.random(default_thoughts)
    end
  end

  @doc """
  Возвращает случайного монстра, чей уровень примерно равен или чуть ниже уровня героя.
  """
  def get_random_monster(hero_level) do
    # Фильтруем монстров: уровень от hero_level - 2 до hero_level
    min_level = max(1, hero_level - 2)

    suitable_monsters =
      Enum.filter(@monsters, fn m -> m.level >= min_level and m.level <= hero_level end)

    # Если не нашли подходящих (например, уровень героя выше всех монстров), берем самых сильных
    monsters_to_choose =
      if Enum.empty?(suitable_monsters) do
        max_monster_level = @monsters |> Enum.map(& &1.level) |> Enum.max()
        Enum.filter(@monsters, fn m -> m.level == max_monster_level end)
      else
        suitable_monsters
      end

    Enum.random(monsters_to_choose)
  end

  @doc """
  Возвращает случайный предмет, ценность (редкость) которого зависит от уровня героя.
  """
  def get_random_loot(hero_level) do
    # Увеличиваем шанс выпадения редких предметов с уровнем
    rarity =
      cond do
        hero_level >= 10 -> Enum.random([:uncommon, :uncommon, :rare, :rare])
        hero_level >= 5 -> Enum.random([:common, :uncommon, :uncommon, :rare])
        true -> Enum.random([:common, :common, :uncommon])
      end

    suitable_items = Enum.filter(@items, fn item -> Map.get(item, :rarity) == rarity end)

    items_to_choose =
      if Enum.empty?(suitable_items) do
        @items
      else
        suitable_items
      end

    item = Enum.random(items_to_choose)
    item.name
  end

  @doc """
  Возвращает случайную локацию.
  """
  def get_location do
    Enum.random(@locations)
  end

  @doc """
  Возвращает тип локации (:city или :wilderness).
  """
  def location_type(location_name), do: Map.get(@location_types, location_name, :wilderness)

  @doc """
  Проверяет, является ли локация городом.
  """
  def is_city?(location_name), do: location_type(location_name) == :city

  def tavern_rumors, do: @tavern_rumors
  def night_events, do: @night_events
  def dungeons, do: @dungeons
  def dungeon_room_events, do: @dungeon_room_events

  @doc """
  Returns a random dungeon room event based on weights.
  """
  def get_random_dungeon_room_event do
    events_with_weights = Enum.map(@dungeon_room_events, fn event -> {event, event.weight} end)

    weighted_list =
      Enum.flat_map(events_with_weights, fn {event, weight} ->
        List.duplicate(event, weight)
      end)

    Enum.random(weighted_list)
  end

  @doc """
  Returns quests filtered by type.
  """
  def quests_by_type(type) do
    Enum.filter(@quests, fn quest -> quest.type == type end)
  end
end
