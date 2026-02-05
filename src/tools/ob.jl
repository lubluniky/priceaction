"""
Order Block detection module.
"""
module OB

using DataFrames
using Dates
using ..Types

export identify_order_blocks

"""
    identify_order_blocks(df::DataFrame) -> Vector{Types.OrderBlock}

Identify bullish and bearish order blocks based on candle structure.
- Bullish OB: Down candle followed by up candle that closes above previous high
- Bearish OB: Up candle followed by down candle that closes below previous low
"""
function identify_order_blocks(df::DataFrame)::Vector{Types.OrderBlock}
    order_blocks = Types.OrderBlock[]

    is_up(row) = row[:Close] > row[:Open]
    is_down(row) = row[:Close] < row[:Open]

    function is_ob_up(current, previous)
        is_down(previous) && is_up(current) && current[:Close] > previous[:High]
    end

    function is_ob_down(current, previous)
        is_up(previous) && is_down(current) && current[:Close] < previous[:Low]
    end

    for i in 2:nrow(df)
        previous_candle = df[i-1, :]
        current_candle = df[i, :]

        if is_ob_up(current_candle, previous_candle)
            push!(order_blocks, Types.OrderBlock(
                df[i-1, Symbol("Open Time")],
                current_candle[:High],
                current_candle[:Low],
                current_candle[:High] - current_candle[:Low],
                current_candle[:Volume],
                :bullish
            ))
        end

        if is_ob_down(current_candle, previous_candle)
            push!(order_blocks, Types.OrderBlock(
                df[i-1, Symbol("Open Time")],
                current_candle[:High],
                current_candle[:Low],
                current_candle[:High] - current_candle[:Low],
                current_candle[:Volume],
                :bearish
            ))
        end
    end

    return order_blocks
end

end # module
