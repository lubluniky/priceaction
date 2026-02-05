module Types

using Dates

export Candle, FVG, IFVG, OrderBlock, BreakerBlock, SwingPoint, MarketStructure
export LiquidityEvent, QuasimodoPattern, ValueArea, KeyLevel, AMDXPhase, Signal

struct Candle
    open_time::DateTime
    open::Float64
    high::Float64
    low::Float64
    close::Float64
    volume::Float64
end

struct SwingPoint
    date::DateTime
    price::Float64
    type::Symbol  # :high or :low
end

struct FVG
    start_time::DateTime
    end_time::DateTime
    start_price::Float64
    end_price::Float64
    type::Symbol  # :bullish or :bearish
    volume_before::Float64
    volume_after::Float64
    width::Float64
    mitigated::Bool
    days_to_mitigation::Union{Int, Nothing}
end

struct IFVG
    fvg_start_time::DateTime
    fvg_end_time::DateTime
    ifvg_time::DateTime
    display_end_time::DateTime
    start_price::Float64
    end_price::Float64
    type::Symbol  # :bullish or :bearish
    volume_before::Float64
    volume_after::Float64
    bars_to_invalidation::Int
end

struct OrderBlock
    date::DateTime
    high::Float64
    low::Float64
    width::Float64
    volume::Float64
    type::Symbol  # :bullish or :bearish
end

struct BreakerBlock
    ob_time::DateTime
    breaker_time::DateTime
    ob_high::Float64
    ob_low::Float64
    break_price::Float64
    type::Symbol  # :bullish_breaker or :bearish_breaker
end

struct MarketStructure
    date::DateTime
    price::Float64
    type::Symbol  # :bos_bull, :bos_bear, :choch_bull, :choch_bear
end

struct LiquidityEvent
    swept_datetime::DateTime
    swept_price::Float64
    swept_type::Symbol
    sweep_datetime::DateTime
    sweep_price::Float64
    sweep_type::Symbol  # :raid_high, :raid_low, :sweep_high, :sweep_low
end

struct QuasimodoPattern
    pattern::Symbol  # :qm_bearish or :iqm_bullish
    h1_date::DateTime
    h1_price::Float64
    l1_date::DateTime
    l1_price::Float64
    h2_date::DateTime
    h2_price::Float64
    l2_date::DateTime
    l2_price::Float64
end

struct ValueArea
    poc::Float64
    val::Float64
    vah::Float64
    profile::Vector{Tuple{Float64, Float64}}  # (price_bin, volume)
end

struct KeyLevel
    price::Float64
    cluster::Int
    count::Int
end

struct AMDXPhase
    phase::Symbol  # :A, :M, :D, :X
    start_time::DateTime
    end_time::DateTime
    high::Float64
    low::Float64
    avg_volume::Float64
    bullish_pct::Float64
end

struct Signal
    date::Date
    time::DateTime
    phase::Symbol
    signal::Symbol  # :long or :short
    entry::Float64
    stop_loss::Float64
    take_profit::Float64
    acc_high::Float64
    acc_low::Float64
    acc_range::Float64
end

end # module
