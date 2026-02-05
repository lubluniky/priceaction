"""
AMDX (Accumulation, Manipulation, Distribution, Extension) Phase analysis module.
"""
module AMDX

using DataFrames
using Dates
using ..Types

export assign_amdx_phases, analyze_amdx_phases, generate_amdx_signals

# Default AMDX time windows (in hours, UTC)
const PHASE_TIMES = Dict(
    :A => (0, 4),    # Accumulation: 00:00-04:00
    :M => (4, 10),   # Manipulation: 04:00-10:00
    :D => (10, 16),  # Distribution: 10:00-16:00
    :X => (16, 24)   # Extension: 16:00-24:00
)

"""
    get_phase(hour::Int) -> Symbol

Get AMDX phase for a given hour (0-23).
"""
function get_phase(hour::Int)::Symbol
    if 0 <= hour < 4
        return :A
    elseif 4 <= hour < 10
        return :M
    elseif 10 <= hour < 16
        return :D
    else
        return :X
    end
end

"""
    assign_amdx_phases(df::DataFrame) -> DataFrame

Add AMDX_Phase column to DataFrame based on Open Time hour.
"""
function assign_amdx_phases(df::DataFrame)::DataFrame
    df_copy = copy(df)
    df_copy[!, :AMDX_Phase] = [get_phase(hour(t)) for t in df_copy[!, Symbol("Open Time")]]
    return df_copy
end

"""
    analyze_amdx_phases(df::DataFrame) -> Dict{Symbol, Types.AMDXPhase}

Analyze characteristics of each AMDX phase.
Returns a Dict with phase analysis including volatility, volume, and price range.
"""
function analyze_amdx_phases(df::DataFrame)::Dict{Symbol, Types.AMDXPhase}
    df_amdx = assign_amdx_phases(df)
    phase_analysis = Dict{Symbol, Types.AMDXPhase}()

    for phase in [:A, :M, :D, :X]
        phase_data = filter(row -> row[:AMDX_Phase] == phase, df_amdx)

        if nrow(phase_data) > 0
            # Basic metrics
            avg_volatility = mean((phase_data[!, :High] .- phase_data[!, :Low]) ./ phase_data[!, :Close])
            avg_volume = mean(phase_data[!, :Volume])

            # Directionality
            bullish_bars = count(row -> row[:Close] > row[:Open], eachrow(phase_data))
            total_bars = nrow(phase_data)
            bullish_pct = bullish_bars / total_bars * 100

            # Price range
            phase_high = maximum(phase_data[!, :High])
            phase_low = minimum(phase_data[!, :Low])

            # Get time range
            start_time = minimum(phase_data[!, Symbol("Open Time")])
            end_time = maximum(phase_data[!, Symbol("Open Time")])

            phase_analysis[phase] = Types.AMDXPhase(
                phase,
                start_time,
                end_time,
                phase_high,
                phase_low,
                avg_volume,
                bullish_pct
            )
        end
    end

    return phase_analysis
end

"""
    generate_amdx_signals(df::DataFrame) -> Vector{Types.Signal}

Generate trading signals based on AMDX phases.
Looks for breakouts of Accumulation range during Manipulation phase.
"""
function generate_amdx_signals(df::DataFrame)::Vector{Types.Signal}
    df_amdx = assign_amdx_phases(df)
    signals = Types.Signal[]

    # Add date column
    df_amdx[!, :Date] = [Date(t) for t in df_amdx[!, Symbol("Open Time")]]

    for date in unique(df_amdx[!, :Date])
        daily_data = sort(filter(row -> row[:Date] == date, df_amdx), Symbol("Open Time"))

        if nrow(daily_data) == 0
            continue
        end

        # Get data by phases
        acc_data = filter(row -> row[:AMDX_Phase] == :A, daily_data)
        man_data = filter(row -> row[:AMDX_Phase] == :M, daily_data)

        if nrow(acc_data) == 0 || nrow(man_data) == 0
            continue
        end

        # Determine accumulation range
        acc_high = maximum(acc_data[!, :High])
        acc_low = minimum(acc_data[!, :Low])
        acc_mid = (acc_high + acc_low) / 2

        # Look for breakout in Manipulation phase
        for row in eachrow(man_data)
            signal_type = nothing
            entry_price = 0.0
            stop_loss = 0.0
            take_profit = 0.0

            # Bullish breakout (above accumulation)
            if row[:High] > acc_high && row[:Close] > acc_mid
                signal_type = :long
                entry_price = acc_high
                stop_loss = acc_low
                take_profit = entry_price + (entry_price - stop_loss) * 2  # RR 1:2

            # Bearish breakout (below accumulation)
            elseif row[:Low] < acc_low && row[:Close] < acc_mid
                signal_type = :short
                entry_price = acc_low
                stop_loss = acc_high
                take_profit = entry_price - (stop_loss - entry_price) * 2  # RR 1:2
            end

            if !isnothing(signal_type)
                push!(signals, Types.Signal(
                    date,
                    row[Symbol("Open Time")],
                    row[:AMDX_Phase],
                    signal_type,
                    entry_price,
                    stop_loss,
                    take_profit,
                    acc_high,
                    acc_low,
                    acc_high - acc_low
                ))
                break  # One signal per day
            end
        end
    end

    return signals
end

# Helper function
function mean(x)
    sum(x) / length(x)
end

end # module
