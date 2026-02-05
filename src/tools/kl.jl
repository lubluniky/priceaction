"""
Key Levels detection using pivot clustering.
"""
module KL

using DataFrames
using Clustering
using Statistics
using ..Types

export find_key_levels

"""
    find_key_levels(df::DataFrame; n_clusters::Int=3) -> Vector{Types.KeyLevel}

Identify key price levels using pivot highs/lows and KMeans clustering.

Steps:
1. Collect all pivot highs and lows
2. Group pivots into clusters based on price proximity
3. Apply KMeans clustering to group similar key levels
4. Return significant key levels with their clusters
"""
function find_key_levels(df::DataFrame; n_clusters::Int=3)::Vector{Types.KeyLevel}
    key_levels = Types.KeyLevel[]

    # Collect pivot points
    pivot_highs = Float64[]
    pivot_lows = Float64[]

    if hasproperty(df, :PivotHighValue)
        for val in df[!, :PivotHighValue]
            if !ismissing(val) && !isnan(val)
                push!(pivot_highs, val)
            end
        end
    end

    if hasproperty(df, :PivotLowValue)
        for val in df[!, :PivotLowValue]
            if !ismissing(val) && !isnan(val)
                push!(pivot_lows, val)
            end
        end
    end

    # Combine all pivots
    all_pivots = vcat(pivot_highs, pivot_lows)

    if length(all_pivots) < n_clusters
        return key_levels
    end

    # Sort pivots
    sort!(all_pivots)

    # Calculate dynamic threshold based on price variability
    price_diffs = diff(all_pivots)
    threshold = length(price_diffs) > 0 ? median(abs.(price_diffs)) * 1.5 : 0.0

    # Group pivots by proximity
    groups = Vector{Float64}[]
    current_group = [all_pivots[1]]

    for i in 2:length(all_pivots)
        if all_pivots[i] - all_pivots[i-1] > threshold
            push!(groups, current_group)
            current_group = [all_pivots[i]]
        else
            push!(current_group, all_pivots[i])
        end
    end
    push!(groups, current_group)

    # Filter groups with at least 2 points and calculate mean
    significant_levels = Float64[]
    level_counts = Int[]

    for group in groups
        if length(group) >= 2
            push!(significant_levels, mean(group))
            push!(level_counts, length(group))
        end
    end

    if length(significant_levels) < n_clusters
        # Return what we have without clustering
        for (price, count) in zip(significant_levels, level_counts)
            push!(key_levels, Types.KeyLevel(price, 1, count))
        end
        return key_levels
    end

    # Apply KMeans clustering
    data_matrix = reshape(significant_levels, 1, length(significant_levels))
    result = kmeans(data_matrix, n_clusters)

    # Build key levels with cluster assignments
    for i in 1:length(significant_levels)
        cluster = result.assignments[i]
        push!(key_levels, Types.KeyLevel(
            significant_levels[i],
            cluster,
            level_counts[i]
        ))
    end

    # Sort by cluster then price
    sort!(key_levels, by=kl -> (kl.cluster, kl.price))

    return key_levels
end

end # module
