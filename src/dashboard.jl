"""
Interactive Dashboard using PlotlyJS with tool switching.
"""
module Dashboard

using PlotlyJS
using DataFrames
using Dates

export create_full_dashboard, create_volume_profile_chart

# Color schemes
const COLORS = Dict(
    :bullish => "rgba(38, 166, 91, 0.3)",
    :bullish_border => "rgba(38, 166, 91, 0.8)",
    :bearish => "rgba(255, 71, 87, 0.3)",
    :bearish_border => "rgba(255, 71, 87, 0.8)",
    :ob_bull => "rgba(52, 152, 219, 0.3)",
    :ob_bull_border => "rgba(52, 152, 219, 0.9)",
    :ob_bear => "rgba(155, 89, 182, 0.3)",
    :ob_bear_border => "rgba(155, 89, 182, 0.9)",
    :bb_bull => "rgba(46, 204, 113, 0.25)",
    :bb_bear => "rgba(231, 76, 60, 0.25)",
    :ifvg_bull => "rgba(0, 255, 255, 0.25)",
    :ifvg_bear => "rgba(255, 0, 255, 0.25)",
    :qm => "rgba(255, 215, 0, 0.8)",
    :kl => "rgba(255, 255, 255, 0.6)",
    :poc => "yellow",
    :vah => "rgba(255, 255, 0, 0.5)",
    :val => "rgba(255, 255, 0, 0.5)",
    :amdx_a => "rgba(128, 128, 128, 0.1)",
    :amdx_m => "rgba(255, 165, 0, 0.15)",
    :amdx_d => "rgba(0, 128, 0, 0.15)",
    :amdx_x => "rgba(128, 0, 128, 0.1)"
)

"""
Create candlestick trace
"""
function create_candles(df)
    candlestick(
        x=df[!, Symbol("Open Time")],
        open=df[!, :Open],
        high=df[!, :High],
        low=df[!, :Low],
        close=df[!, :Close],
        name="OHLC",
        increasing_line_color="rgb(38, 166, 91)",
        decreasing_line_color="rgb(255, 71, 87)",
        visible=true,
        legendgroup="candles"
    )
end

"""
Create swing point traces
"""
function create_swing_traces(swings)
    traces = GenericTrace[]
    highs = filter(s -> s.type == :high, swings)
    lows = filter(s -> s.type == :low, swings)

    if !isempty(highs)
        push!(traces, scatter(
            x=[s.date for s in highs],
            y=[s.price for s in highs],
            mode="markers",
            marker=attr(symbol="triangle-down", size=8, color="red"),
            name="Swing High",
            legendgroup="swings",
            visible="legendonly"
        ))
    end

    if !isempty(lows)
        push!(traces, scatter(
            x=[s.date for s in lows],
            y=[s.price for s in lows],
            mode="markers",
            marker=attr(symbol="triangle-up", size=8, color="lime"),
            name="Swing Low",
            legendgroup="swings",
            visible="legendonly"
        ))
    end
    return traces
end

"""
Create FVG traces (as scatter with fill)
"""
function create_fvg_traces(fvgs)
    traces = GenericTrace[]
    for (i, fvg) in enumerate(fvgs)
        color = fvg.type == :bullish ? COLORS[:bullish] : COLORS[:bearish]
        name = i == 1 ? "FVG $(fvg.type)" : ""

        push!(traces, scatter(
            x=[fvg.start_time, fvg.end_time, fvg.end_time, fvg.start_time, fvg.start_time],
            y=[fvg.start_price, fvg.start_price, fvg.end_price, fvg.end_price, fvg.start_price],
            fill="toself",
            fillcolor=color,
            line=attr(color=fvg.type == :bullish ? COLORS[:bullish_border] : COLORS[:bearish_border], width=1),
            mode="lines",
            name=name,
            legendgroup="fvg",
            showlegend=(i <= 2),
            visible="legendonly",
            hoverinfo="text",
            text="FVG $(fvg.type)<br>$(round(fvg.width, digits=2))"
        ))
    end
    return traces
end

"""
Create IFVG traces
"""
function create_ifvg_traces(ifvgs)
    traces = GenericTrace[]
    for (i, ifvg) in enumerate(ifvgs)
        color = ifvg.type == :bullish ? COLORS[:ifvg_bull] : COLORS[:ifvg_bear]

        push!(traces, scatter(
            x=[ifvg.fvg_start_time, ifvg.ifvg_time, ifvg.ifvg_time, ifvg.fvg_start_time, ifvg.fvg_start_time],
            y=[ifvg.start_price, ifvg.start_price, ifvg.end_price, ifvg.end_price, ifvg.start_price],
            fill="toself",
            fillcolor=color,
            line=attr(color="rgba(255,255,255,0.5)", width=1, dash="dot"),
            mode="lines",
            name=i == 1 ? "IFVG" : "",
            legendgroup="ifvg",
            showlegend=(i == 1),
            visible="legendonly"
        ))
    end
    return traces
end

"""
Create Order Block traces
"""
function create_ob_traces(obs)
    traces = GenericTrace[]
    for (i, ob) in enumerate(obs)
        color = ob.type == :bullish ? COLORS[:ob_bull] : COLORS[:ob_bear]
        border = ob.type == :bullish ? COLORS[:ob_bull_border] : COLORS[:ob_bear_border]

        x1 = ob.date + Hour(6)

        push!(traces, scatter(
            x=[ob.date, x1, x1, ob.date, ob.date],
            y=[ob.low, ob.low, ob.high, ob.high, ob.low],
            fill="toself",
            fillcolor=color,
            line=attr(color=border, width=2),
            mode="lines",
            name=i <= 2 ? "OB $(ob.type)" : "",
            legendgroup="ob",
            showlegend=(i <= 2),
            visible="legendonly"
        ))
    end
    return traces
end

"""
Create Breaker Block traces
"""
function create_bb_traces(bbs)
    traces = GenericTrace[]
    for (i, bb) in enumerate(bbs)
        color = bb.type == :bullish_breaker ? COLORS[:bb_bull] : COLORS[:bb_bear]

        push!(traces, scatter(
            x=[bb.ob_time, bb.breaker_time, bb.breaker_time, bb.ob_time, bb.ob_time],
            y=[bb.ob_low, bb.ob_low, bb.ob_high, bb.ob_high, bb.ob_low],
            fill="toself",
            fillcolor=color,
            line=attr(color="rgba(255,255,255,0.4)", width=1, dash="dash"),
            mode="lines",
            name=i == 1 ? "Breaker Block" : "",
            legendgroup="bb",
            showlegend=(i == 1),
            visible="legendonly"
        ))
    end
    return traces
end

"""
Create Liquidity Raid traces
"""
function create_raid_traces(raids)
    if isempty(raids)
        return GenericTrace[]
    end
    [scatter(
        x=[r.sweep_datetime for r in raids],
        y=[r.sweep_price for r in raids],
        mode="markers",
        marker=attr(symbol="star", size=12, color="orange", line=attr(width=1, color="white")),
        name="Liquidity Raid",
        legendgroup="raids",
        visible="legendonly"
    )]
end

"""
Create Liquidity Sweep traces
"""
function create_sweep_traces(sweeps)
    if isempty(sweeps)
        return GenericTrace[]
    end
    [scatter(
        x=[s.sweep_datetime for s in sweeps],
        y=[s.sweep_price for s in sweeps],
        mode="markers",
        marker=attr(symbol="x", size=10, color="magenta", line=attr(width=2)),
        name="Liquidity Sweep",
        legendgroup="sweeps",
        visible="legendonly"
    )]
end

"""
Create Quasimodo pattern traces
"""
function create_qm_traces(patterns)
    traces = GenericTrace[]
    for (i, qm) in enumerate(patterns)
        # Draw the pattern as connected lines
        push!(traces, scatter(
            x=[qm.h1_date, qm.l1_date, qm.h2_date, qm.l2_date],
            y=[qm.h1_price, qm.l1_price, qm.h2_price, qm.l2_price],
            mode="lines+markers",
            line=attr(color=COLORS[:qm], width=2),
            marker=attr(size=8, symbol="diamond"),
            name=i == 1 ? "Quasimodo $(qm.pattern)" : "",
            legendgroup="qm",
            showlegend=(i == 1),
            visible="legendonly"
        ))
    end
    return traces
end

"""
Create Value Area (AMT) traces - POC, VAH, VAL lines
"""
function create_amt_traces(va, df)
    x_min = minimum(df[!, Symbol("Open Time")])
    x_max = maximum(df[!, Symbol("Open Time")])

    traces = [
        scatter(
            x=[x_min, x_max],
            y=[va.poc, va.poc],
            mode="lines",
            line=attr(color=COLORS[:poc], width=2, dash="dash"),
            name="POC $(round(va.poc, digits=0))",
            legendgroup="amt",
            visible="legendonly"
        ),
        scatter(
            x=[x_min, x_max],
            y=[va.vah, va.vah],
            mode="lines",
            line=attr(color=COLORS[:vah], width=1, dash="dot"),
            name="VAH $(round(va.vah, digits=0))",
            legendgroup="amt",
            visible="legendonly"
        ),
        scatter(
            x=[x_min, x_max],
            y=[va.val, va.val],
            mode="lines",
            line=attr(color=COLORS[:val], width=1, dash="dot"),
            name="VAL $(round(va.val, digits=0))",
            legendgroup="amt",
            visible="legendonly"
        )
    ]
    return traces
end

"""
Create Key Levels traces
"""
function create_kl_traces(kls, df)
    if isempty(kls)
        return GenericTrace[]
    end

    x_min = minimum(df[!, Symbol("Open Time")])
    x_max = maximum(df[!, Symbol("Open Time")])

    traces = GenericTrace[]
    for (i, kl) in enumerate(kls)
        opacity = min(0.3 + kl.count * 0.1, 0.9)
        push!(traces, scatter(
            x=[x_min, x_max],
            y=[kl.price, kl.price],
            mode="lines",
            line=attr(color="rgba(255,255,255,$opacity)", width=1 + kl.count * 0.3),
            name=i == 1 ? "Key Level" : "",
            legendgroup="kl",
            showlegend=(i == 1),
            visible="legendonly",
            hoverinfo="text",
            text="KL: $(round(kl.price, digits=2)) (touches: $(kl.count))"
        ))
    end
    return traces
end

"""
Create AMDX signal markers
"""
function create_amdx_traces(signals)
    if isempty(signals)
        return GenericTrace[]
    end

    longs = filter(s -> s.signal == :long, signals)
    shorts = filter(s -> s.signal == :short, signals)

    traces = GenericTrace[]

    if !isempty(longs)
        push!(traces, scatter(
            x=[s.time for s in longs],
            y=[s.entry for s in longs],
            mode="markers",
            marker=attr(symbol="triangle-up", size=14, color="lime", line=attr(width=2, color="white")),
            name="AMDX Long",
            legendgroup="amdx",
            visible="legendonly"
        ))
    end

    if !isempty(shorts)
        push!(traces, scatter(
            x=[s.time for s in shorts],
            y=[s.entry for s in shorts],
            mode="markers",
            marker=attr(symbol="triangle-down", size=14, color="red", line=attr(width=2, color="white")),
            name="AMDX Short",
            legendgroup="amdx",
            visible="legendonly"
        ))
    end

    return traces
end

"""
Create Volume Profile as side histogram
"""
function create_vp_trace(vp_result, df)
    profile = vp_result.profile
    if isempty(profile)
        return GenericTrace[]
    end

    prices = [p[1] for p in profile]
    volumes = [p[2] for p in profile]

    # Normalize volumes for display
    max_vol = maximum(volumes)
    x_max = maximum(df[!, Symbol("Open Time")])

    # Scale to fit on chart (about 10% of time range)
    time_range = maximum(df[!, Symbol("Open Time")]) - minimum(df[!, Symbol("Open Time")])
    scale = Dates.value(time_range) * 0.1 / max_vol

    traces = GenericTrace[]
    for (i, (price, vol)) in enumerate(zip(prices, volumes))
        is_single = vp_result.single_print_bins !== nothing && price in vp_result.single_print_bins
        color = is_single ? "rgba(255, 0, 0, 0.5)" : "rgba(100, 149, 237, 0.4)"

        push!(traces, scatter(
            x=[x_max, x_max + Millisecond(round(Int, vol * scale))],
            y=[price, price],
            mode="lines",
            line=attr(color=color, width=4),
            name=i == 1 ? "Volume Profile" : "",
            legendgroup="vp",
            showlegend=(i == 1),
            visible="legendonly",
            hoverinfo="text",
            text="Vol: $(round(vol, sigdigits=3))"
        ))
    end

    return traces
end

"""
    create_full_dashboard(df, results; title="Price Action") -> Plot

Create complete interactive dashboard with ALL tools and legend-based switching.
"""
function create_full_dashboard(df, results; title::String="Price Action Analysis")
    traces = GenericTrace[]

    # 1. Candlesticks (always visible)
    push!(traces, create_candles(df))

    # 2. Swing Points
    if haskey(results, :swings) && !isempty(results[:swings])
        append!(traces, create_swing_traces(results[:swings]))
    end

    # 3. FVG
    if haskey(results, :fvg) && !isempty(results[:fvg])
        append!(traces, create_fvg_traces(results[:fvg]))
    end

    # 4. IFVG
    if haskey(results, :ifvg) && !isempty(results[:ifvg])
        append!(traces, create_ifvg_traces(results[:ifvg]))
    end

    # 5. Order Blocks
    if haskey(results, :ob) && !isempty(results[:ob])
        append!(traces, create_ob_traces(results[:ob]))
    end

    # 6. Breaker Blocks
    if haskey(results, :bb) && !isempty(results[:bb])
        append!(traces, create_bb_traces(results[:bb]))
    end

    # 7. Liquidity Raids
    if haskey(results, :raids) && !isempty(results[:raids])
        append!(traces, create_raid_traces(results[:raids]))
    end

    # 8. Liquidity Sweeps
    if haskey(results, :sweeps) && !isempty(results[:sweeps])
        append!(traces, create_sweep_traces(results[:sweeps]))
    end

    # 9. Quasimodo
    if haskey(results, :qm) && !isempty(results[:qm])
        append!(traces, create_qm_traces(results[:qm]))
    end

    # 10. AMT (Value Area)
    if haskey(results, :amt)
        append!(traces, create_amt_traces(results[:amt], df))
    end

    # 11. Key Levels
    if haskey(results, :kl) && !isempty(results[:kl])
        append!(traces, create_kl_traces(results[:kl], df))
    end

    # 12. AMDX Signals
    if haskey(results, :amdx_signals) && !isempty(results[:amdx_signals])
        append!(traces, create_amdx_traces(results[:amdx_signals]))
    end

    # 13. Volume Profile
    if haskey(results, :vp)
        append!(traces, create_vp_trace(results[:vp], df))
    end

    layout = Layout(
        xaxis=attr(
            title="Time",
            rangeslider=attr(visible=false),
            type="date",
            gridcolor="rgba(128,128,128,0.2)"
        ),
        yaxis=attr(
            title="Price",
            gridcolor="rgba(128,128,128,0.2)"
        ),
        template="plotly_dark",
        paper_bgcolor="rgb(17, 17, 17)",
        plot_bgcolor="rgb(17, 17, 17)",
        legend=attr(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="left",
            x=0,
            bgcolor="rgba(0,0,0,0.5)",
            font=attr(size=10)
        ),
        height=900,
        hovermode="x unified",
        margin=attr(t=80, b=50, l=60, r=40)
    )

    return Plot(traces, layout)
end

"""
Create volume profile as separate chart
"""
function create_volume_profile_chart(profile::Vector{Tuple{Float64, Float64}})
    prices = [p[1] for p in profile]
    volumes = [p[2] for p in profile]

    trace = bar(
        x=volumes,
        y=prices,
        orientation="h",
        marker=attr(color="rgba(255, 193, 7, 0.7)"),
        name="Volume Profile"
    )

    layout = Layout(
        title="Volume Profile",
        xaxis_title="Volume",
        yaxis_title="Price",
        template="plotly_dark",
        height=600
    )

    return Plot(trace, layout)
end

end # module
