"""
PriceAction.jl - High-performance Price Action Analysis Toolkit

A comprehensive Julia package for technical analysis including:
- Fair Value Gaps (FVG/IFVG)
- Order Blocks and Breaker Blocks
- Market Structure (BOS/CHOCH)
- Quasimodo Patterns
- Liquidity Events (Raids/Sweeps)
- Auction Market Theory (Value Area)
- AMDX Phase Analysis
- Key Levels Clustering
"""
module PriceAction

using Reexport

# Include types first (no dependencies)
include("types.jl")
@reexport using .Types

# Include data loader
include("data_loader.jl")
@reexport using .DataLoader

# Include common utilities (depends on Types)
include("tools/common.jl")
@reexport using .Common

# Include analysis tools (depend on Types and Common)
include("tools/fvg.jl")
@reexport using .FVG

include("tools/ifvg.jl")
@reexport using .IFVG

include("tools/bos.jl")
@reexport using .BOS

include("tools/ob.jl")
@reexport using .OB

include("tools/bb.jl")
@reexport using .BB

include("tools/qm.jl")
@reexport using .QM

include("tools/liquidity.jl")
@reexport using .Liquidity

include("tools/amt.jl")
@reexport using .AMT

include("tools/vp.jl")
@reexport using .VP

include("tools/amdx.jl")
@reexport using .AMDX

include("tools/kl.jl")
@reexport using .KL

# Include dashboard
include("dashboard.jl")
@reexport using .Dashboard

# Convenience functions
export analyze_price_action

"""
    analyze_price_action(df::DataFrame; tools::Vector{Symbol}=[:all]) -> Dict

Run multiple price action analyses on the DataFrame.

Parameters:
- df: DataFrame with OHLCV data
- tools: Vector of tool symbols to run, or [:all] for everything

Available tools: :fvg, :ifvg, :bos, :ob, :bb, :qm, :raids, :sweeps, :amt, :amdx, :kl
"""
function analyze_price_action(df; tools::Vector{Symbol}=[:all])
    results = Dict{Symbol, Any}()

    run_all = :all in tools

    # Get swing points (needed for several tools)
    swings = Common.identify_swing_points(df)
    results[:swings] = swings

    if run_all || :fvg in tools
        results[:fvg] = FVG.identify_fvgs(df)
    end

    if run_all || :ifvg in tools
        results[:ifvg] = IFVG.identify_ifvgs(df)
    end

    if run_all || :ob in tools
        results[:ob] = OB.identify_order_blocks(df)
    end

    if run_all || :bb in tools
        results[:bb] = BB.identify_breaker_blocks(df)
    end

    if run_all || :qm in tools
        results[:qm] = QM.identify_quasimodo_patterns(df)
    end

    if run_all || :raids in tools
        results[:raids] = Liquidity.identify_liquidity_raids(df, swings)
    end

    if run_all || :sweeps in tools
        results[:sweeps] = Liquidity.identify_liquidity_sweeps(df, swings)
    end

    if run_all || :amt in tools
        results[:amt] = AMT.compute_value_area(df)
    end

    if run_all || :amdx in tools
        results[:amdx_phases] = AMDX.analyze_amdx_phases(df)
        results[:amdx_signals] = AMDX.generate_amdx_signals(df)
    end

    if run_all || :kl in tools
        if hasproperty(df, :PivotHighValue)
            results[:kl] = KL.find_key_levels(df)
        end
    end

    return results
end

end # module
