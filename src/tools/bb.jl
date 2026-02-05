"""
Breaker Block detection module.
"""
module BB

using DataFrames
using Dates
using ..Types
using ..OB

export identify_breaker_blocks

"""
    identify_breaker_blocks(df::DataFrame) -> Vector{Types.BreakerBlock}

Identify Breaker Blocks: order blocks that have been pierced by price structure breaks.
- Bullish OB becomes Bearish Breaker when price closes below OB low
- Bearish OB becomes Bullish Breaker when price closes above OB high
"""
function identify_breaker_blocks(df::DataFrame)::Vector{Types.BreakerBlock}
    breaker_blocks = Types.BreakerBlock[]

    df_sorted = sort(df, Symbol("Open Time"))
    order_blocks = OB.identify_order_blocks(df_sorted)

    for ob in order_blocks
        ob_time = ob.date
        ob_high = ob.high
        ob_low = ob.low
        ob_type = ob.type

        # Get future candles after OB formation
        future_idx = findfirst(r -> df_sorted[r, Symbol("Open Time")] > ob_time, 1:nrow(df_sorted))

        if isnothing(future_idx)
            continue
        end

        if ob_type == :bullish
            # Bullish OB becomes Bearish Breaker if price closes below OB low
            for j in future_idx:nrow(df_sorted)
                if df_sorted[j, :Close] < ob_low
                    push!(breaker_blocks, Types.BreakerBlock(
                        ob_time,
                        df_sorted[j, Symbol("Open Time")],
                        ob_high,
                        ob_low,
                        df_sorted[j, :Close],
                        :bearish_breaker
                    ))
                    break
                end
            end
        else
            # Bearish OB becomes Bullish Breaker if price closes above OB high
            for j in future_idx:nrow(df_sorted)
                if df_sorted[j, :Close] > ob_high
                    push!(breaker_blocks, Types.BreakerBlock(
                        ob_time,
                        df_sorted[j, Symbol("Open Time")],
                        ob_high,
                        ob_low,
                        df_sorted[j, :Close],
                        :bullish_breaker
                    ))
                    break
                end
            end
        end
    end

    return breaker_blocks
end

end # module
