#!/usr/bin/env julia
"""
PriceAction.jl - Interactive Dashboard

Usage:
    julia dashboard.jl [symbol] [interval]

Example:
    julia dashboard.jl BTCUSDT 1h
    julia dashboard.jl ETHUSDT 4h

Tools available (click legend to toggle):
    - Swing Points (highs/lows)
    - FVG (Fair Value Gaps)
    - IFVG (Inverted FVGs)
    - Order Blocks
    - Breaker Blocks
    - Liquidity Raids
    - Liquidity Sweeps
    - Quasimodo Patterns
    - AMT (POC/VAH/VAL)
    - AMDX Signals
    - Volume Profile
"""

using Pkg
Pkg.activate(@__DIR__)

using PriceAction
using PriceAction.VP
using DataFrames
using Dates
using PlotlyJS

function run_dashboard()
    # Parse arguments
    symbol = length(ARGS) >= 1 ? ARGS[1] : "BTCUSDT"
    interval = length(ARGS) >= 2 ? ARGS[2] : "15m"

    println()
    println("╔══════════════════════════════════════════════════════════╗")
    println("║       PriceAction.jl - Interactive Dashboard             ║")
    println("╠══════════════════════════════════════════════════════════╣")
    println("║  Symbol: $(rpad(symbol, 10)) │  Interval: $(rpad(interval, 10))         ║")
    println("╚══════════════════════════════════════════════════════════╝")
    println()

    # Fetch data (latest 1000 candles)
    println("📊 Fetching data from Binance...")
    df = fetch_binance_data(symbol, interval; limit=1000)
    println("   ✓ Loaded $(nrow(df)) candles")
    println()

    # Run full analysis
    println("🔍 Running price action analysis...")
    results = analyze_price_action(df)

    # Add Volume Profile separately (not in default analyze_price_action)
    println("   Computing Volume Profile...")
    results[:vp] = VP.identify_volume_profile_single_prints(df)

    # Print summary
    println()
    println("┌─────────────────────────────────────────┐")
    println("│            Analysis Summary             │")
    println("├─────────────────────────────────────────┤")
    println("│  Swing Points:    $(lpad(length(results[:swings]), 5))                │")
    println("│  FVGs:            $(lpad(length(results[:fvg]), 5))                │")
    println("│  IFVGs:           $(lpad(length(results[:ifvg]), 5))                │")
    println("│  Order Blocks:    $(lpad(length(results[:ob]), 5))                │")
    println("│  Breaker Blocks:  $(lpad(length(results[:bb]), 5))                │")
    println("│  Liquidity Raids: $(lpad(length(results[:raids]), 5))                │")
    println("│  Liquidity Sweeps:$(lpad(length(results[:sweeps]), 5))                │")
    println("│  Quasimodo:       $(lpad(length(results[:qm]), 5))                │")
    println("│  AMDX Signals:    $(lpad(length(results[:amdx_signals]), 5))                │")
    println("├─────────────────────────────────────────┤")
    va = results[:amt]
    println("│  POC: $(lpad(round(va.poc, digits=2), 10))                    │")
    println("│  VAH: $(lpad(round(va.vah, digits=2), 10))                    │")
    println("│  VAL: $(lpad(round(va.val, digits=2), 10))                    │")
    println("└─────────────────────────────────────────┘")
    println()

    # Create full dashboard
    println("📈 Creating interactive chart with ALL tools...")

    chart = Dashboard.create_full_dashboard(
        df, results,
        title="$symbol ($interval) - Price Action Dashboard"
    )

    # Save to HTML
    html_path = joinpath(@__DIR__, "chart.html")
    println()
    println("💾 Saving to: $html_path")
    savefig(chart, html_path)

    # Open in browser
    println("🌐 Opening in browser...")
    if Sys.isapple()
        run(`open $html_path`)
    elseif Sys.islinux()
        run(`xdg-open $html_path`)
    elseif Sys.iswindows()
        run(`cmd /c start $html_path`)
    end

    println()
    println("╔══════════════════════════════════════════════════════════╗")
    println("║  ✅ Dashboard ready!                                     ║")
    println("╠══════════════════════════════════════════════════════════╣")
    println("║  Click on legend items to show/hide tools:               ║")
    println("║    • Swing High/Low  • FVG          • IFVG               ║")
    println("║    • OB bullish/bear • Breaker      • Raids/Sweeps       ║")
    println("║    • Quasimodo       • POC/VAH/VAL  • AMDX signals       ║")
    println("║    • Volume Profile  • Key Levels                        ║")
    println("╠══════════════════════════════════════════════════════════╣")
    println("║  Controls:                                               ║")
    println("║    • Zoom: scroll or drag-select                         ║")
    println("║    • Pan:  shift + drag                                  ║")
    println("║    • Reset: double-click                                 ║")
    println("╚══════════════════════════════════════════════════════════╝")
    println()

    return (df=df, results=results, chart=chart)
end

# Run
if abspath(PROGRAM_FILE) == @__FILE__
    run_dashboard()
end
