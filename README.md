# PriceAction.jl

**High-performance Price Action Analysis Toolkit for Julia**

A comprehensive library for technical analysis of financial markets using ICT (Inner Circle Trader) concepts and Smart Money methodology.

---

## Features

| Tool | Description |
|------|-------------|
| **FVG** | Fair Value Gaps - imbalances in price action |
| **IFVG** | Inverted FVGs - invalidated gaps that become support/resistance |
| **Order Blocks** | Institutional supply/demand zones |
| **Breaker Blocks** | Failed order blocks that flip polarity |
| **BOS/CHOCH** | Break of Structure / Change of Character |
| **Quasimodo** | QM/IQM reversal patterns |
| **Liquidity** | Raids and Sweeps detection |
| **AMT** | Auction Market Theory (POC, VAH, VAL) |
| **Volume Profile** | Price-volume distribution analysis |
| **AMDX** | Accumulation-Manipulation-Distribution-Expansion phases |
| **Key Levels** | Clustered support/resistance levels |

---

## Installation

```julia
using Pkg
Pkg.activate("path/to/julia")
Pkg.instantiate()
```

### Requirements
- Julia 1.9+
- Internet connection (for Binance API)

---

## Quick Start

### Interactive Dashboard

```bash
julia dashboard.jl
```

Opens an interactive chart in your browser with all tools visualized.

### Command Line Analysis

```bash
julia start.jl
```

Prints analysis summary to terminal.

### Custom Symbol/Timeframe

```bash
julia dashboard.jl ETHUSDT 1h
julia start.jl SOLUSDT 4h
```

**Supported timeframes:** `1m`, `5m`, `15m`, `1h`, `4h`, `1d`, `1w`

---

## Usage in Code

```julia
using PriceAction

# Fetch latest 1000 candles
df = fetch_binance_data("BTCUSDT", "15m")

# Run full analysis
results = analyze_price_action(df)

# Access results
println("FVGs found: ", length(results[:fvg]))
println("Order Blocks: ", length(results[:ob]))
println("POC: ", results[:amt].poc)

# Or run specific tools
results = analyze_price_action(df, tools=[:fvg, :ob, :amt])
```

### Individual Tools

```julia
using PriceAction

df = fetch_binance_data("BTCUSDT", "15m")

# Fair Value Gaps
fvgs = FVG.identify_fvgs(df)

# Inverted FVGs (close-based invalidation, 20 bar limit)
ifvgs = IFVG.identify_ifvgs(df)

# Order Blocks
obs = OB.identify_order_blocks(df)

# Swing Points
swings = Common.identify_swing_points(df)

# Liquidity Events
raids = Liquidity.identify_liquidity_raids(df, swings)
sweeps = Liquidity.identify_liquidity_sweeps(df, swings)

# Value Area (AMT)
va = AMT.compute_value_area(df)
println("POC: $(va.poc), VAH: $(va.vah), VAL: $(va.val)")
```

---

## Dashboard Controls

| Action | Control |
|--------|---------|
| Zoom | Scroll or drag-select |
| Pan | Shift + drag |
| Reset view | Double-click |
| Toggle tools | Click legend items |

---

## Project Structure

```
julia/
├── dashboard.jl          # Interactive chart launcher
├── start.jl              # CLI analysis script
├── src/
│   ├── PriceAction.jl    # Main module
│   ├── types.jl          # Data structures
│   ├── data_loader.jl    # Binance API & pickle loader
│   ├── dashboard.jl      # PlotlyJS visualization
│   └── tools/
│       ├── fvg.jl        # Fair Value Gaps
│       ├── ifvg.jl       # Inverted FVGs
│       ├── ob.jl         # Order Blocks
│       ├── bb.jl         # Breaker Blocks
│       ├── bos.jl        # Break of Structure
│       ├── qm.jl         # Quasimodo Patterns
│       ├── liquidity.jl  # Raids & Sweeps
│       ├── amt.jl        # Auction Market Theory
│       ├── vp.jl         # Volume Profile
│       ├── amdx.jl       # AMDX Phases
│       ├── kl.jl         # Key Levels
│       └── common.jl     # Swing Points & utilities
└── Project.toml
```

---

## Configuration

Default settings:
- **Symbol:** BTCUSDT
- **Timeframe:** 15m
- **Candles:** 1000 (latest)
- **IFVG invalidation:** Close-based (not wick)
- **IFVG max wait:** 20 bars
- **IFVG display:** 5 bars after formation

---

## Data Types

```julia
struct FVG
    start_time::DateTime
    end_time::DateTime
    start_price::Float64
    end_price::Float64
    type::Symbol           # :bullish or :bearish
    volume_before::Float64
    volume_after::Float64
    width::Float64
    mitigated::Bool
    days_to_mitigation::Union{Int, Nothing}
end

struct IFVG
    fvg_start_time::DateTime
    fvg_end_time::DateTime
    ifvg_time::DateTime
    display_end_time::DateTime
    start_price::Float64
    end_price::Float64
    type::Symbol           # :bullish or :bearish
    volume_before::Float64
    volume_after::Float64
    bars_to_invalidation::Int
end

struct OrderBlock
    date::DateTime
    high::Float64
    low::Float64
    width::Float64
    volume::Float64
    type::Symbol           # :bullish or :bearish
end

struct ValueArea
    poc::Float64           # Point of Control
    val::Float64           # Value Area Low
    vah::Float64           # Value Area High
    profile::Vector{Tuple{Float64, Float64}}
end
```

---

## Dependencies

- **DataFrames.jl** - Data manipulation
- **HTTP.jl** - API requests
- **JSON3.jl** - JSON parsing
- **PlotlyJS.jl** - Interactive charts
- **PythonCall.jl** - Pickle file support
- **Clustering.jl** - Key levels clustering
- **StatsBase.jl** - Statistical functions

---

## License

MIT

---

## Author

Price Action Toolkit
