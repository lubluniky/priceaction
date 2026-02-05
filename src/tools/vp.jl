"""
Volume Profile module - Single Print detection.
"""
module VP

using DataFrames
using ..Types

export identify_volume_profile_single_prints

"""
    identify_volume_profile_single_prints(df::DataFrame; price_col::Symbol=:Close,
                                          volume_col::Symbol=:Volume,
                                          bin_size::Union{Float64, Nothing}=nothing) -> NamedTuple

Identify Volume Profile Single Prints (price bins with only one bar traded).

Returns:
- NamedTuple with:
  - profile: Vector of (price_bin, volume, tpo_count) tuples
  - single_print_bins: Vector of bin midpoints where TPO_Count == 1
"""
function identify_volume_profile_single_prints(df::DataFrame;
                                               price_col::Symbol=:Close,
                                               volume_col::Symbol=:Volume,
                                               bin_size::Union{Float64, Nothing}=nothing)

    prices = Float64.(df[!, price_col])
    volumes = Float64.(df[!, volume_col])

    min_price = minimum(prices)
    max_price = maximum(prices)

    if isnothing(bin_size)
        bin_size = (max_price - min_price) / 50
    end

    bins = collect(min_price:bin_size:(max_price + bin_size))
    n_bins = length(bins) - 1
    midpoints = [bins[i] + bin_size/2 for i in 1:n_bins]

    # Track volume and TPO count per bin
    bin_volumes = zeros(n_bins)
    tpo_counts = zeros(Int, n_bins)

    for (p, v) in zip(prices, volumes)
        bin_idx = clamp(Int(floor((p - min_price) / bin_size)) + 1, 1, n_bins)
        bin_volumes[bin_idx] += v
        tpo_counts[bin_idx] += 1
    end

    # Build profile
    profile = [(midpoints[i], bin_volumes[i], tpo_counts[i]) for i in 1:n_bins if bin_volumes[i] > 0]

    # Identify single-print bins (TPO count == 1)
    single_print_bins = [p[1] for p in profile if p[3] == 1]

    return (profile=profile, single_print_bins=single_print_bins)
end

end # module
