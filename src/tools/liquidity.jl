"""
Liquidity events detection: Raids and Sweeps.
"""
module Liquidity

using DataFrames
using Dates
using ..Types

export identify_liquidity_raids, identify_liquidity_sweeps

"""
    identify_liquidity_raids(df::DataFrame, swing_points::Vector{Types.SwingPoint}) -> Vector{Types.LiquidityEvent}

Identify liquidity raid events: price sweeps above/below swing points AND closes through them.
- Raid High: Price sweeps above swing high and closes above it
- Raid Low: Price sweeps below swing low and closes below it
"""
function identify_liquidity_raids(df::DataFrame, swing_points::Vector{Types.SwingPoint})::Vector{Types.LiquidityEvent}
    raids = Types.LiquidityEvent[]

    for swing in swing_points
        # Get candles after the swing point
        future_mask = df[!, Symbol("Open Time")] .> swing.date
        subsequent = df[future_mask, :]

        if nrow(subsequent) == 0
            continue
        end

        if swing.type == :high
            # Find first candle where High > swing price AND Close > swing price
            for i in 1:nrow(subsequent)
                row = subsequent[i, :]
                if row[:High] > swing.price && row[:Close] > swing.price
                    # Check if this is the first breach
                    prev_max = i > 1 ? maximum(subsequent[1:i-1, :High]) : 0.0
                    if prev_max <= swing.price
                        push!(raids, Types.LiquidityEvent(
                            swing.date,
                            swing.price,
                            swing.type,
                            row[Symbol("Open Time")],
                            row[:High],
                            :raid_high
                        ))
                        break
                    end
                end
            end
        elseif swing.type == :low
            # Find first candle where Low < swing price AND Close < swing price
            for i in 1:nrow(subsequent)
                row = subsequent[i, :]
                if row[:Low] < swing.price && row[:Close] < swing.price
                    # Check if this is the first breach
                    prev_min = i > 1 ? minimum(subsequent[1:i-1, :Low]) : Inf
                    if prev_min >= swing.price
                        push!(raids, Types.LiquidityEvent(
                            swing.date,
                            swing.price,
                            swing.type,
                            row[Symbol("Open Time")],
                            row[:Low],
                            :raid_low
                        ))
                        break
                    end
                end
            end
        end
    end

    return raids
end

"""
    identify_liquidity_sweeps(df::DataFrame, swing_points::Vector{Types.SwingPoint}) -> Vector{Types.LiquidityEvent}

Identify liquidity sweep events: price sweeps above/below swing points BUT closes back through (stop run).
- Sweep High: Price sweeps above swing high but closes BELOW it
- Sweep Low: Price sweeps below swing low but closes ABOVE it
"""
function identify_liquidity_sweeps(df::DataFrame, swing_points::Vector{Types.SwingPoint})::Vector{Types.LiquidityEvent}
    sweeps = Types.LiquidityEvent[]

    for swing in swing_points
        future_mask = df[!, Symbol("Open Time")] .> swing.date
        subsequent = df[future_mask, :]

        if nrow(subsequent) == 0
            continue
        end

        if swing.type == :high
            # Find first candle where High > swing price BUT Close < swing price
            for i in 1:nrow(subsequent)
                row = subsequent[i, :]
                # Check if all previous highs were <= swing price
                prev_max = i > 1 ? maximum(subsequent[1:i-1, :High]) : 0.0
                if prev_max <= swing.price && row[:High] > swing.price && row[:Close] < swing.price
                    push!(sweeps, Types.LiquidityEvent(
                        swing.date,
                        swing.price,
                        swing.type,
                        row[Symbol("Open Time")],
                        row[:High],
                        :sweep_high
                    ))
                    break
                end
            end
        elseif swing.type == :low
            # Find first candle where Low < swing price BUT Close > swing price
            for i in 1:nrow(subsequent)
                row = subsequent[i, :]
                prev_min = i > 1 ? minimum(subsequent[1:i-1, :Low]) : Inf
                if prev_min >= swing.price && row[:Low] < swing.price && row[:Close] > swing.price
                    push!(sweeps, Types.LiquidityEvent(
                        swing.date,
                        swing.price,
                        swing.type,
                        row[Symbol("Open Time")],
                        row[:Low],
                        :sweep_low
                    ))
                    break
                end
            end
        end
    end

    return sweeps
end

end # module
