"""
Quasimodo (QM) and Inverted Quasimodo (iQM) pattern detection module.
"""
module QM

using DataFrames
using Dates
using ..Types
using ..Common

export identify_quasimodo_patterns

"""
    identify_quasimodo_patterns(df::DataFrame) -> Vector{Types.QuasimodoPattern}

Identify QM and iQM patterns from swing points.

QM (bearish):
  - Swing High H1 -> Swing Low L1 -> Swing High H2 > H1 -> Swing Low L2 < L1

iQM (bullish):
  - Swing Low L1 -> Swing High H1 -> Swing Low L2 < L1 -> Swing High H2 > H1
"""
function identify_quasimodo_patterns(df::DataFrame)::Vector{Types.QuasimodoPattern}
    patterns = Types.QuasimodoPattern[]

    # Get swing points
    swings = Common.identify_swing_points(df)
    n = length(swings)

    for i in 1:n-3
        p1, p2, p3, p4 = swings[i], swings[i+1], swings[i+2], swings[i+3]

        # Bearish Quasimodo: High -> Low -> Higher High -> Lower Low
        if p1.type == :high && p2.type == :low && p3.type == :high && p4.type == :low &&
           p3.price > p1.price && p4.price < p2.price
            push!(patterns, Types.QuasimodoPattern(
                :qm_bearish,
                p1.date, p1.price,  # H1
                p2.date, p2.price,  # L1
                p3.date, p3.price,  # H2
                p4.date, p4.price   # L2
            ))
        end

        # Bullish Inverted Quasimodo: Low -> High -> Lower Low -> Higher High
        if p1.type == :low && p2.type == :high && p3.type == :low && p4.type == :high &&
           p3.price < p1.price && p4.price > p2.price
            push!(patterns, Types.QuasimodoPattern(
                :iqm_bullish,
                p2.date, p2.price,  # H1
                p1.date, p1.price,  # L1
                p4.date, p4.price,  # H2
                p3.date, p3.price   # L2
            ))
        end
    end

    return patterns
end

end # module
