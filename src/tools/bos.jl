"""
Break of Structure (BOS) and Change of Character (CHOCH) detection module.
"""
module BOS

using DataFrames
using Dates
using ..Types

export identify_market_structures

"""
    identify_market_structures(df::DataFrame) -> Vector{Types.MarketStructure}

Identify market structure events based on pivot highs/lows.
- BOS Bullish: Price breaks above previous pivot high (HH)
- BOS Bearish: Price breaks below previous pivot low (LL)
- CHOCH Bullish: Price breaks below previous pivot low (HL)
- CHOCH Bearish: Price breaks above previous pivot high (LH)

Expects DataFrame with: Open Time, High, Low, PivotHighValue, PivotLowValue, HH, HL, LL, LH columns.
"""
function identify_market_structures(df::DataFrame)::Vector{Types.MarketStructure}
    structures = Types.MarketStructure[]

    last_hh = nothing
    last_hl = nothing
    last_ll = nothing
    last_lh = nothing

    bos_bull_identified = false
    choch_bull_identified = false
    bos_bear_identified = false
    choch_bear_identified = false

    for i in 1:nrow(df)
        row = df[i, :]
        open_time = row[Symbol("Open Time")]
        high = row[:High]
        low = row[:Low]

        # Bullish BOS: price breaks above last pivot high
        if !isnothing(last_hh) && high > last_hh && !bos_bull_identified
            push!(structures, Types.MarketStructure(open_time, last_hh, :bos_bull))
            bos_bull_identified = true
        end

        # Bullish CHOCH: price breaks below last pivot low
        if !isnothing(last_hl) && low < last_hl && !choch_bull_identified
            push!(structures, Types.MarketStructure(open_time, last_hl, :choch_bull))
            choch_bull_identified = true
        end

        # Bearish BOS: price breaks below last pivot low
        if !isnothing(last_ll) && low < last_ll && !bos_bear_identified
            push!(structures, Types.MarketStructure(open_time, last_ll, :bos_bear))
            bos_bear_identified = true
        end

        # Bearish CHOCH: price breaks above last pivot high
        if !isnothing(last_lh) && high > last_lh && !choch_bear_identified
            push!(structures, Types.MarketStructure(open_time, last_lh, :choch_bear))
            choch_bear_identified = true
        end

        # Update pivots and reset flags
        if hasproperty(row, :HH) && !ismissing(row[:HH]) && row[:HH]
            last_hh = row[:PivotHighValue]
            bos_bull_identified = false
        end
        if hasproperty(row, :HL) && !ismissing(row[:HL]) && row[:HL]
            last_hl = row[:PivotLowValue]
            choch_bull_identified = false
        end
        if hasproperty(row, :LL) && !ismissing(row[:LL]) && row[:LL]
            last_ll = row[:PivotLowValue]
            bos_bear_identified = false
        end
        if hasproperty(row, :LH) && !ismissing(row[:LH]) && row[:LH]
            last_lh = row[:PivotHighValue]
            choch_bear_identified = false
        end
    end

    return structures
end

end # module
