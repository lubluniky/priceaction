"""
Inverted Fair Value Gap (IFVG) detection module.
"""
module IFVG

using DataFrames
using Dates
using ..Types

export identify_ifvgs

"""
    identify_ifvgs(df::DataFrame) -> Vector{Types.IFVG}

Identify Inverted Fair Value Gaps in price action.
- Bearish IFVG: A bullish FVG that gets invalidated (price returns below)
- Bullish IFVG: A bearish FVG that gets invalidated (price returns above)
"""
function identify_ifvgs(df::DataFrame)::Vector{Types.IFVG}
    ifvgs = Types.IFVG[]

    df_sorted = sort(df, Symbol("Open Time"))
    n = nrow(df_sorted)

    for i in 3:n-2
        two_bars_ago = df_sorted[i-2, :]
        previous_row = df_sorted[i-1, :]
        current_row = df_sorted[i, :]

        # Bullish FVG invalidation -> Bearish IFVG
        if current_row[:Low] > two_bars_ago[:High]
            start_price = two_bars_ago[:High]
            end_price = current_row[:Low]
            bars_to_invalidate = 0
            invalidated = false
            invalidate_time = nothing
            invalidate_idx = 0

            max_bars = min(i + 20, n)  # Wait max 20 bars for invalidation
            for j in (i+1):max_bars
                bars_to_invalidate += 1
                if df_sorted[j, :Close] < start_price
                    invalidated = true
                    invalidate_time = df_sorted[j, Symbol("Open Time")]
                    invalidate_idx = j
                    break
                end
            end

            if invalidated
                # Display for 5 bars after formation
                display_end_idx = min(invalidate_idx + 5, n)
                display_end_time = df_sorted[display_end_idx, Symbol("Open Time")]

                push!(ifvgs, Types.IFVG(
                    two_bars_ago[Symbol("Open Time")],
                    current_row[Symbol("Open Time")],
                    invalidate_time,
                    display_end_time,
                    start_price,
                    end_price,
                    :bearish,
                    i > 1 ? df_sorted[i-1, :Volume] : 0.0,
                    previous_row[:Volume],
                    bars_to_invalidate
                ))
            end

        # Bearish FVG invalidation -> Bullish IFVG
        elseif current_row[:High] < two_bars_ago[:Low]
            start_price = two_bars_ago[:Low]
            end_price = current_row[:High]
            bars_to_invalidate = 0
            invalidated = false
            invalidate_time = nothing
            invalidate_idx = 0

            max_bars = min(i + 20, n)  # Wait max 20 bars for invalidation
            for j in (i+1):max_bars
                bars_to_invalidate += 1
                if df_sorted[j, :Close] > start_price
                    invalidated = true
                    invalidate_time = df_sorted[j, Symbol("Open Time")]
                    invalidate_idx = j
                    break
                end
            end

            if invalidated
                # Display for 5 bars after formation
                display_end_idx = min(invalidate_idx + 5, n)
                display_end_time = df_sorted[display_end_idx, Symbol("Open Time")]

                push!(ifvgs, Types.IFVG(
                    two_bars_ago[Symbol("Open Time")],
                    current_row[Symbol("Open Time")],
                    invalidate_time,
                    display_end_time,
                    start_price,
                    end_price,
                    :bullish,
                    i > 1 ? df_sorted[i-1, :Volume] : 0.0,
                    previous_row[:Volume],
                    bars_to_invalidate
                ))
            end
        end
    end

    return ifvgs
end

end # module
