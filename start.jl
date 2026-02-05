#!/usr/bin/env julia
"""
PriceAction.jl - Start Script

Usage:
    julia start.jl [symbol] [interval]

Example:
    julia start.jl BTCUSDT 1h
"""

# Activate project environment
using Pkg
Pkg.activate(@__DIR__)

using PriceAction
using Dates
using DataFrames

function main()
    # Parse command line arguments
    symbol = length(ARGS) >= 1 ? ARGS[1] : "BTCUSDT"
    interval = length(ARGS) >= 2 ? ARGS[2] : "15m"

    println("PriceAction.jl - Price Action Analysis Toolkit")
    println("=" ^ 50)
    println("Symbol: $symbol")
    println("Interval: $interval")
    println()

    # Fetch data (latest 1000 candles)
    println("Fetching data from Binance...")
    df = fetch_binance_data(symbol, interval; limit=1000)
    println("Loaded $(nrow(df)) candles")
    println()

    # Run analysis
    println("Running price action analysis...")
    results = analyze_price_action(df)

    # Print summary
    println("\n" * "=" ^ 50)
    println("ANALYSIS RESULTS")
    println("=" ^ 50)

    println("\nSwing Points: $(length(results[:swings]))")
    println("  - Highs: $(count(s -> s.type == :high, results[:swings]))")
    println("  - Lows: $(count(s -> s.type == :low, results[:swings]))")

    println("\nFair Value Gaps: $(length(results[:fvg]))")
    if length(results[:fvg]) > 0
        bullish = count(f -> f.type == :bullish, results[:fvg])
        bearish = count(f -> f.type == :bearish, results[:fvg])
        println("  - Bullish: $bullish")
        println("  - Bearish: $bearish")
    end

    println("\nInverted FVGs: $(length(results[:ifvg]))")
    if length(results[:ifvg]) > 0
        bullish = count(f -> f.type == :bullish, results[:ifvg])
        bearish = count(f -> f.type == :bearish, results[:ifvg])
        println("  - Bullish: $bullish")
        println("  - Bearish: $bearish")
    end

    println("\nOrder Blocks: $(length(results[:ob]))")
    if length(results[:ob]) > 0
        bullish = count(o -> o.type == :bullish, results[:ob])
        bearish = count(o -> o.type == :bearish, results[:ob])
        println("  - Bullish: $bullish")
        println("  - Bearish: $bearish")
    end

    println("\nBreaker Blocks: $(length(results[:bb]))")

    println("\nQuasimodo Patterns: $(length(results[:qm]))")

    println("\nLiquidity Events:")
    println("  - Raids: $(length(results[:raids]))")
    println("  - Sweeps: $(length(results[:sweeps]))")

    println("\nValue Area (AMT):")
    va = results[:amt]
    println("  - POC: $(round(va.poc, digits=2))")
    println("  - VAH: $(round(va.vah, digits=2))")
    println("  - VAL: $(round(va.val, digits=2))")

    println("\nAMDX Signals: $(length(results[:amdx_signals]))")

    println("\n" * "=" ^ 50)
    println("Analysis complete!")

    return results
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
