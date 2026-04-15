# GodvilleSk — Исправления и Новые Функции

Дата: 2026-04-15

## Обзор

Добавлена поддержка системы повреждений конечностей (Kenshi-style), новая система вмешательств Бога, арены для PvP и торговля душами героев.

---

## Система Частей Тела (Body Parts)

### Концепция

Каждый герой имеет 5 частей тела: `left_arm`, `right_arm`, `left_leg`, `right_leg`, `head`. Каждая часть может находиться в состоянии:
- `:healthy` — здорова
- `:injured` — ранена (снижена функциональность)
- `:lost` — потеряна навсегда

### Файлы

| Файл | Описание |
|------|----------|
| `priv/repo/migrations/20260415070000_add_body_parts_system.exs` | Миграция: колонки `body_parts` (JSONB) и `permanent_injuries` (счётчик) |
| `lib/godville_sk/hero/body_parts.ex` | Модуль управления конечностями |

### Влияние на AI (Utility Curves)

| Часть тела | Потеря/Травма | Эффект |
|------------|---------------|--------|
| Нога | Травма | `flee` +30-50% |
| Нога | Потеря | `flee` +60%, невозможно убежать с двумя потерянными |
| Рука | Травма | `fight` -15% |
| Рука | Потеря | `fight` -30%, нельзя использовать двуручное оружие |
| Голова | Травма | `explore` -20%, `max_hp` -20% |
| Голова | Потеря | Смерть (мгновенная) |

### Функции модуля `BodyParts`

```elixir
BodyParts.flee_modifier(body_parts)      # Множитель для побега
BodyParts.fight_modifier(body_parts)      # Множитель для боя
BodyParts.explore_modifier(body_parts)     # Множитель для исследования
BodyParts.can_use_two_handed?(body_parts) # Проверка двуручного оружия
BodyParts.can_flee?(body_parts)           # Проверка возможности бежать
BodyParts.movement_modifier(body_parts)   # Скорость передвижения
BodyParts.damage_modifier(body_parts)     # Модификатор урона
```

### Травмы в бою

При получении урона от врага:
- 5% базовый шанс травмы (+0.5% за каждый уровень героя)
- При HP < 15% и сильном ударе (20+ урона) — шанс потери конечности
- Потерянные конечности не восстанавливаются естественно

---

## Система Вмешательств Бога (God Interventions)

### Стоимость в Пране

| Действие | Прана | Описание |
|----------|-------|----------|
| `heal` | 10 | Лечит героя на 15-35 HP |
| `bless` | 20 | Случайный позитивный эффект (HP, золото, лут, бафф силы) |
| `send_loot` | 15 | Отправляет предмет герою в инвентарь |
| `lightning` | 5 | Молния по врагу или герою |
| `fear` | 8 | Вселяет страх, герой бежит из боя |
| `punish` | 12 | Наказание с уроном |
| `whisper` | 5 | Божественный шёпот с задержкой |
| `divine_intervention` | 100 | Воскрешение из Совнгарда |

### API Героя

```elixir
GodvilleSk.Hero.heal(hero_name, amount)        # Лечение
GodvilleSk.Hero.bless(hero_name)                # Благословение
GodvilleSk.Hero.send_loot(hero_name)             # Отправить лут
GodvilleSk.Hero.lightning(hero_name)             # Молния
GodvilleSk.Hero.fear(hero_name)                 # Страх
GodvilleSk.Hero.punish(hero_name)               # Наказание
GodvilleSk.Hero.heal_injury(hero_name, :left_arm) # Лечить травму
GodvilleSk.Hero.divine_intervention(hero_name)   # Воскрешение
```

---

## Арены (PvP)

### Типы

- **Duel (1v1)** — дуэль двух героев
- **Team 3v3** — команды по 3 героя
- **Team 5v5** — команды по 5 героев

### Файлы

| Файл | Описание |
|------|----------|
| `priv/repo/migrations/20260415080000_create_arenas.exs` | Таблицы `arenas` и `arena_participants` |
| `lib/godville_sk/arena.ex` | Контекст (Arenas) |
| `lib/godville_sk/arena/arena.ex` | Схема арены |
| `lib/godville_sk/arena/arena_participant.ex` | Схема участника |
| `lib/godville_sk/arena/server.ex` | GenServer управления боем |
| `lib/godville_sk/arena/matchmaking.ex` | Система поиска матчей |

### Архитектура Процессов

```
ArenaSupervisor (DynamicSupervisor)
├── Arena.Matchmaking (GenServer) — очередь игроков
└── Arena.Server (GenServer) — один на матч
```

### Механика Боя

- 50 раундов максимум
- 500ms между раундами
- Победа: уничтожение всех членов команды или больше HP на конец
- Награды: золото и XP для победителей, половина — для проигравших

---

## Торговля (Marketplace)

### Возможности

- Продажа предметов за золото
- Продажа душ (героев) другим игрокам

### Файлы

| Файл | Описание |
|------|----------|
| `priv/repo/migrations/20260415090000_create_trades.exs` | Таблица `trades` |
| `lib/godville_sk/marketplace.ex` | Контекст с Ecto.Multi |
| `lib/godville_sk/marketplace/trade.ex` | Схема торговой записи |

### Ecto.Multi для Транзакций

```elixir
# Продажа души (атомарная транзакция)
Ecto.Multi.new()
|> Ecto.Multi.update(:deduct_gold, ...)
|> Ecto.Multi.update(:add_gold, ...)
|> Ecto.Multi.update(:transfer_character, ...)
|> Repo.transaction()
```

### Валидации

- Герой не в бою (`status != :combat`)
- Герой не на арене
- Достаточно золота у покупателя

---

## seeds.exs

Добавлены демо-данные:
- Пользователь `god@demo.dev` с паролем `demo_password_123`
- Герой `Торик Девятизвон` (Норд, Воин, Уровень 1)
- Предметы: железный меч, стальной меч, кожаная броня, зелье лечения, отмычка, драконий меч
- Локации: Балмора, Солитьютд, Винтерхолд, Ривервуд, Имперский город и др.
- Монстры: грязевой краб, злокрыс, волк, скелет, бандит

---

## Запуск

```bash
# Миграции
mix ecto.migrate

# Сиды
mix run priv/repo/seeds.exs

# Запуск
mix phx.server
```
