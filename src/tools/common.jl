"""
Common utilities: Swing High/Low detection and swing point identification.
"""
module Common

using DataFrames
using ..Types

export is_swing_low, is_swing_high, identify_swing_points

"""
    is_swing_low(df::DataFrame, index::Int) -> Bool

Determine if the bar at `index` is a swing low.
A swing low is a low that is lower than the two bars before and after.
"""
function is_swing_low(df::DataFrame, index::Int)::Bool
    n = nrow(df)
    if index < 3 || index > n - 2
        return false
    end
    current_low = df[index, :Low]
    # Check 2 bars before and 2 bars after
    return current_low < minimum(df[index-2:index-1, :Low]) &&
           current_low < minimum(df[index+1:index+2, :Low])
end

"""
    is_swing_high(df::DataFrame, index::Int) -> Bool

Determine if the bar at `index` is a swing high.
A swing high is a high that is higher than the two bars before and after.
"""
function is_swing_high(df::DataFrame, index::Int)::Bool
    n = nrow(df)
    if index < 3 || index > n - 2
        return false
    end
    current_high = df[index, :High]
    return current_high > maximum(df[index-2:index-1, :High]) &&
           current_high > maximum(df[index+1:index+2, :High])
end

"""
    identify_swing_points(df::DataFrame) -> Vector{SwingPoint}

Identify all swing highs and lows in the DataFrame.
Returns a vector of SwingPoint structs sorted by date.
"""
function identify_swing_points(df::DataFrame)::Vector{SwingPoint}
    swings = SwingPoint[]
    n = nrow(df)

    for i in 3:n-2
        if is_swing_high(df, i)
            push!(swings, SwingPoint(df[i, Symbol("Open Time")], df[i, :High], :high))
        end
        if is_swing_low(df, i)
            push!(swings, SwingPoint(df[i, Symbol("Open Time")], df[i, :Low], :low))
        end
    end

    sort!(swings, by = s -> s.date)
    return swings
end

end # module
