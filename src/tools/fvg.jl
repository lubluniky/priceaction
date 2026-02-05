"""
Fair Value Gap (FVG) detection module.
"""
module FVG

using DataFrames
using Dates
using ..Types

export identify_fvgs

"""
    identify_fvgs(df::DataFrame) -> Vector{Types.FVG}

Identify Fair Value Gaps in price action.
- Bullish FVG: Current bar's low > high two bars ago
- Bearish FVG: Current bar's high < low two bars ago
Also tracks mitigation status.
"""
function identify_fvgs(df::DataFrame)::Vector{Types.FVG}
    fvgs = Types.FVG[]

    # Sort by Open Time
    df_sorted = sort(df, Symbol("Open Time"))
    n = nrow(df_sorted)

    for i in 3:n-2
        two_bars_ago = df_sorted[i-2, :]
        previous_row = df_sorted[i-1, :]
        current_row = df_sorted[i, :]

        # Bullish FVG: Current low > high two bars ago
        if current_row[:Low] > two_bars_ago[:High]
            width = current_row[:Low] - two_bars_ago[:High]
            mitigated = false
            days_to_mitigation = 0

            for j in (i+1):n
                days_to_mitigation += 1
                if df_sorted[j, :Low] <= two_bars_ago[:High]
                    mitigated = true
                    break
                end
            end

            push!(fvgs, Types.FVG(
                two_bars_ago[Symbol("Open Time")],
                current_row[Symbol("Open Time")],
                two_bars_ago[:High],
                current_row[:Low],
                :bullish,
                i > 1 ? df_sorted[i-1, :Volume] : 0.0,
                i < n ? df_sorted[i+1, :Volume] : 0.0,
                width,
                mitigated,
                mitigated ? days_to_mitigation : nothing
            ))

        # Bearish FVG: Current high < low two bars ago
        elseif current_row[:High] < two_bars_ago[:Low]
            width = two_bars_ago[:Low] - current_row[:High]
            mitigated = false
            days_to_mitigation = 0

            for j in (i+1):n
                days_to_mitigation += 1
                if df_sorted[j, :High] >= two_bars_ago[:Low]
                    mitigated = true
                    break
                end
            end

            push!(fvgs, Types.FVG(
                two_bars_ago[Symbol("Open Time")],
                current_row[Symbol("Open Time")],
                two_bars_ago[:Low],
                current_row[:High],
                :bearish,
                i > 1 ? df_sorted[i-1, :Volume] : 0.0,
                i < n ? df_sorted[i+1, :Volume] : 0.0,
                width,
                mitigated,
                mitigated ? days_to_mitigation : nothing
            ))
        end
    end

    return fvgs
end

end # module
