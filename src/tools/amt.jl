"""
Auction Market Theory (AMT) module - Value Area calculation.
"""
module AMT

using DataFrames
using StatsBase
using ..Types

export compute_value_area

"""
    compute_value_area(df::DataFrame; price_col::Symbol=:Close, volume_col::Symbol=:Volume,
                       bin_size::Union{Float64, Nothing}=nothing, va_percent::Float64=0.7) -> Types.ValueArea

Compute Value Area High (VAH), Value Area Low (VAL), and Point of Control (POC).

Parameters:
- df: DataFrame with price and volume columns
- price_col: Column to use for price (default :Close)
- volume_col: Column for volume (default :Volume)
- bin_size: Width of each price bin; if nothing, uses (max-min)/50
- va_percent: Fraction of total volume defining the value area (default 0.70)

Returns:
- ValueArea struct with POC, VAL, VAH, and full profile
"""
function compute_value_area(df::DataFrame;
                            price_col::Symbol=:Close,
                            volume_col::Symbol=:Volume,
                            bin_size::Union{Float64, Nothing}=nothing,
                            va_percent::Float64=0.7)::Types.ValueArea

    prices = Float64.(df[!, price_col])
    volumes = Float64.(df[!, volume_col])

    min_price = minimum(prices)
    max_price = maximum(prices)

    # Determine bin size
    if isnothing(bin_size)
        bin_size = (max_price - min_price) / 50
    end

    # Create bins
    bins = collect(min_price:bin_size:(max_price + bin_size))
    n_bins = length(bins) - 1

    # Calculate bin midpoints
    midpoints = [bins[i] + bin_size/2 for i in 1:n_bins]

    # Aggregate volume by bin
    bin_volumes = zeros(n_bins)
    for (p, v) in zip(prices, volumes)
        # Find which bin this price belongs to
        bin_idx = clamp(Int(floor((p - min_price) / bin_size)) + 1, 1, n_bins)
        bin_volumes[bin_idx] += v
    end

    # Build profile as vector of tuples
    profile = [(midpoints[i], bin_volumes[i]) for i in 1:n_bins if bin_volumes[i] > 0]

    # Sort by volume descending to find POC and value area
    sorted_profile = sort(profile, by=x -> x[2], rev=true)

    total_vol = sum(bin_volumes)

    # Point of Control: bin with maximum volume
    poc = sorted_profile[1][1]

    # Find Value Area bins (accumulate top volume bins until va_percent is reached)
    cum_vol = 0.0
    va_bins = Float64[]

    for (price_bin, vol) in sorted_profile
        cum_vol += vol
        push!(va_bins, price_bin)
        if cum_vol >= va_percent * total_vol
            break
        end
    end

    # VAL and VAH are min and max of value area bins
    val = minimum(va_bins)
    vah = maximum(va_bins)

    return Types.ValueArea(poc, val, vah, profile)
end

end # module
