"""
Data loading utilities: Binance API and Pickle file support.
"""
module DataLoader

using HTTP
using JSON3
using DataFrames
using Dates
using PythonCall

export fetch_binance_data, load_pickle

"""
    fetch_binance_data(symbol::String, interval::String; limit::Int=1000) -> DataFrame
    fetch_binance_data(symbol::String, interval::String, start_date::DateTime; limit::Int=1000) -> DataFrame

Fetch OHLCV data from Binance API.

Parameters:
- symbol: Trading pair (e.g., "BTCUSDT")
- interval: Timeframe (e.g., "1h", "4h", "1d")
- start_date: Optional start datetime (if omitted, fetches latest candles)
- limit: Maximum number of candles (default 1000)

Returns:
- DataFrame with columns: Open Time, Open, High, Low, Close, Volume
"""
function fetch_binance_data(symbol::String, interval::String, start_date::Union{DateTime, Nothing}=nothing;
                           limit::Int=1000)::DataFrame

    base_url = "https://api.binance.com/api/v3/klines"

    params = Dict(
        "symbol" => symbol,
        "interval" => interval,
        "limit" => string(limit)
    )

    # Only add startTime if provided
    if !isnothing(start_date)
        start_ms = Int64(datetime2unix(start_date) * 1000)
        params["startTime"] = string(start_ms)
    end

    query = join(["$k=$v" for (k, v) in params], "&")
    url = "$base_url?$query"

    response = HTTP.get(url)
    data = JSON3.read(String(response.body))

    # Parse klines data
    rows = []
    for kline in data
        push!(rows, (
            open_time = unix2datetime(kline[1] / 1000),
            open = parse(Float64, kline[2]),
            high = parse(Float64, kline[3]),
            low = parse(Float64, kline[4]),
            close = parse(Float64, kline[5]),
            volume = parse(Float64, kline[6])
        ))
    end

    df = DataFrame(rows)
    rename!(df, :open_time => Symbol("Open Time"),
                :open => :Open, :high => :High,
                :low => :Low, :close => :Close, :volume => :Volume)

    return df
end

"""
    load_pickle(filepath::String) -> DataFrame

Load a DataFrame from a Python pickle file using PythonCall.
"""
function load_pickle(filepath::String)::DataFrame
    pd = pyimport("pandas")
    py_df = pd.read_pickle(filepath)

    # Convert to Julia DataFrame
    columns = pyconvert(Vector{String}, py_df.columns.tolist())

    data = Dict{String, Vector}()
    for col in columns
        py_col = py_df[col].values
        # Try to convert to appropriate Julia type
        try
            data[col] = pyconvert(Vector{Float64}, py_col)
        catch
            try
                data[col] = pyconvert(Vector{String}, py_col)
            catch
                # Handle datetime columns
                try
                    data[col] = [pyconvert(DateTime, t) for t in py_col]
                catch
                    data[col] = pyconvert(Vector{Any}, py_col)
                end
            end
        end
    end

    return DataFrame(data)
end

end # module
