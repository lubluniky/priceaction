# Agent Guide: PriceAction.jl

Руководство для AI-агентов по работе с библиотекой PriceAction.jl.

---

## Архитектура

```
PriceAction.jl (главный модуль)
    ├── Types          → Структуры данных (types.jl)
    ├── DataLoader     → Загрузка данных (data_loader.jl)
    ├── Common         → Swing Points, утилиты (tools/common.jl)
    ├── Dashboard      → Визуализация (dashboard.jl)
    └── Tools          → Аналитические инструменты
        ├── FVG        → Fair Value Gaps
        ├── IFVG       → Inverted FVGs
        ├── OB         → Order Blocks
        ├── BB         → Breaker Blocks
        ├── BOS        → Break of Structure
        ├── QM         → Quasimodo
        ├── Liquidity  → Raids/Sweeps
        ├── AMT        → Value Area
        ├── VP         → Volume Profile
        ├── AMDX       → Phase Analysis
        └── KL         → Key Levels
```

---

## Ключевые файлы

| Файл | Назначение | Когда модифицировать |
|------|------------|---------------------|
| `src/types.jl` | Все структуры данных | При добавлении полей или новых типов |
| `src/tools/*.jl` | Логика детекции | При изменении алгоритмов |
| `src/PriceAction.jl` | Главный модуль, `analyze_price_action()` | При добавлении новых инструментов |
| `src/dashboard.jl` | Визуализация PlotlyJS | При изменении отображения на графике |
| `src/data_loader.jl` | Binance API | При изменении источника данных |
| `dashboard.jl` | Точка входа дашборда | При изменении CLI параметров |
| `start.jl` | Точка входа CLI | При изменении вывода в консоль |

---

## Паттерны модификации

### 1. Изменение параметров детекции

**Пример: Изменить лимит ожидания инвалидации IFVG**

Файл: `src/tools/ifvg.jl`

```julia
# Найти строку:
max_bars = min(i + 20, n)  # Wait max 20 bars

# Изменить число 20 на нужное значение
max_bars = min(i + 30, n)  # Wait max 30 bars
```

**Пример: Изменить время отображения IFVG после формирования**

```julia
# Найти строку:
display_end_idx = min(invalidate_idx + 5, n)

# Изменить число 5 на нужное
display_end_idx = min(invalidate_idx + 10, n)
```

---

### 2. Изменение условий детекции

**Пример: IFVG - с wick на close**

Было (wick-based):
```julia
if df_sorted[j, :Low] <= start_price   # Bearish IFVG
if df_sorted[j, :High] >= start_price  # Bullish IFVG
```

Стало (close-based):
```julia
if df_sorted[j, :Close] < start_price   # Bearish IFVG
if df_sorted[j, :Close] > start_price   # Bullish IFVG
```

**Важно:** Строгое сравнение (`<`, `>`) vs нестрогое (`<=`, `>=`) влияет на количество детекций.

---

### 3. Добавление нового поля в структуру

**Шаг 1:** Добавить поле в `src/types.jl`

```julia
struct IFVG
    # существующие поля...
    new_field::Float64  # новое поле
end
```

**Шаг 2:** Обновить конструктор в соответствующем `tools/*.jl`

```julia
push!(ifvgs, Types.IFVG(
    # существующие аргументы...
    calculated_new_value  # новый аргумент
))
```

**Шаг 3:** При необходимости обновить `src/dashboard.jl` для отображения

---

### 4. Добавление нового инструмента

**Шаг 1:** Создать `src/tools/newtool.jl`

```julia
module NewTool

using DataFrames
using Dates
using ..Types

export identify_new_patterns

function identify_new_patterns(df::DataFrame)::Vector{Types.NewType}
    results = Types.NewType[]
    # логика детекции
    return results
end

end # module
```

**Шаг 2:** Добавить структуру в `src/types.jl`

```julia
struct NewType
    # поля
end

# Добавить в export
export ..., NewType
```

**Шаг 3:** Подключить в `src/PriceAction.jl`

```julia
include("tools/newtool.jl")
@reexport using .NewTool

# В функции analyze_price_action():
if run_all || :newtool in tools
    results[:newtool] = NewTool.identify_new_patterns(df)
end
```

**Шаг 4:** Добавить визуализацию в `src/dashboard.jl`

---

## Конвенции кода

### Именование

```julia
# Модули: CamelCase
module OrderBlocks

# Функции: snake_case, глагол + существительное
identify_fvgs()
compute_value_area()
generate_signals()

# Типы: CamelCase
struct FairValueGap

# Поля структур: snake_case
start_price::Float64
open_time::DateTime
```

### Типы паттернов

```julia
type::Symbol  # Всегда :bullish или :bearish
```

### Работа с DataFrame

```julia
# Доступ к колонкам
df_sorted[j, :Close]
df_sorted[j, :High]
df_sorted[j, Symbol("Open Time")]  # для имён с пробелами

# Сортировка
df_sorted = sort(df, Symbol("Open Time"))

# Количество строк
n = nrow(df_sorted)
```

---

## Таймфреймы

**Поддерживаемые Binance интервалы:**

```
1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M
```

**Изменение дефолтного таймфрейма:**

```julia
# В dashboard.jl и start.jl:
interval = length(ARGS) >= 2 ? ARGS[2] : "15m"
```

---

## Загрузка данных

### Binance API

```julia
# Последние N свечей (рекомендуется)
df = fetch_binance_data("BTCUSDT", "15m"; limit=1000)

# С определённой даты
df = fetch_binance_data("BTCUSDT", "15m", DateTime(2024, 1, 1); limit=1000)
```

### Pickle файлы

```julia
df = load_pickle("path/to/data.pkl")
```

---

## Валидация изменений

### Быстрая проверка

```bash
julia start.jl
```

Должен вывести статистику без ошибок.

### Полная проверка с визуализацией

```bash
julia dashboard.jl
```

Должен открыть график в браузере.

### Проверка конкретного инструмента

```julia
using Pkg; Pkg.activate(".")
using PriceAction

df = fetch_binance_data("BTCUSDT", "15m")
results = IFVG.identify_ifvgs(df)
println("Found: ", length(results))
println("First: ", results[1])
```

---

## Частые задачи

### Изменить количество загружаемых свечей

```julia
# В data_loader.jl, dashboard.jl, start.jl:
limit=1000  # изменить на нужное
```

### Изменить символ по умолчанию

```julia
# В dashboard.jl и start.jl:
symbol = length(ARGS) >= 1 ? ARGS[1] : "BTCUSDT"
```

### Добавить статистику в вывод консоли

Файл: `start.jl`

```julia
println("\nNew Tool: $(length(results[:newtool]))")
if length(results[:newtool]) > 0
    bullish = count(x -> x.type == :bullish, results[:newtool])
    bearish = count(x -> x.type == :bearish, results[:newtool])
    println("  - Bullish: $bullish")
    println("  - Bearish: $bearish")
end
```

### Изменить цвет на графике

Файл: `src/dashboard.jl`

```julia
# Найти соответствующий trace и изменить:
fillcolor="rgba(255, 0, 0, 0.3)"  # RGBA формат
line_color="red"
marker_color="green"
```

---

## Структура данных свечей

DataFrame должен содержать колонки:

| Колонка | Тип | Описание |
|---------|-----|----------|
| `Open Time` | DateTime | Время открытия |
| `Open` | Float64 | Цена открытия |
| `High` | Float64 | Максимум |
| `Low` | Float64 | Минимум |
| `Close` | Float64 | Цена закрытия |
| `Volume` | Float64 | Объём |

---

## Debugging

### Проверить загрузку данных

```julia
df = fetch_binance_data("BTCUSDT", "15m")
println(first(df, 5))
println(names(df))
```

### Проверить промежуточные значения

```julia
# Добавить в функцию:
@show variable_name
println("Debug: ", some_value)
```

### Прекомпиляция после изменений

После изменения кода Julia автоматически прекомпилирует модуль при следующем запуске. Если возникают проблемы:

```julia
using Pkg
Pkg.activate(".")
Pkg.precompile()
```

---

## Критические замечания

1. **Порядок аргументов в конструкторе** должен точно соответствовать порядку полей в `struct`

2. **Изменение struct требует перезапуска Julia** - горячая перезагрузка не работает для изменённых типов

3. **DataFrame колонки чувствительны к регистру** - `df[:Close]` ≠ `df[:close]`

4. **Symbol("Open Time")** - для имён колонок с пробелами

5. **Binance лимит** - максимум 1000 свечей за запрос

---

## Примеры запросов пользователя → Действия

| Запрос | Файл | Действие |
|--------|------|----------|
| "Измени таймфрейм на 1h" | `dashboard.jl`, `start.jl` | Изменить дефолтный interval |
| "Пусть ждёт 30 баров" | `src/tools/ifvg.jl` | Изменить `max_bars = min(i + 30, n)` |
| "Добавь поле X в IFVG" | `src/types.jl`, `src/tools/ifvg.jl` | Добавить поле + обновить конструктор |
| "Покажи IFVG 10 баров" | `src/tools/ifvg.jl` | Изменить `display_end_idx = min(invalidate_idx + 10, n)` |
| "Смени символ на ETH" | `dashboard.jl`, `start.jl` | Изменить дефолтный symbol |
| "Инвалидация по wick" | `src/tools/ifvg.jl` | Изменить `Close` на `Low`/`High` |
