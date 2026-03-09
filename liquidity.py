"""
Liquidity events detection: Raids and Sweeps.

Python port of `src/tools/liquidity.jl`.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from math import inf
from typing import Any, Mapping, Sequence

import pandas as pd


@dataclass(frozen=True)
class SwingPoint:
    date: datetime
    price: float
    type: str  # "high" or "low"


@dataclass(frozen=True)
class LiquidityEvent:
    swept_datetime: datetime
    swept_price: float
    swept_type: str
    sweep_datetime: datetime
    sweep_price: float
    sweep_type: str  # "raid_high", "raid_low", "sweep_high", "sweep_low"


def _get_value(obj: SwingPoint | Mapping[str, Any], name: str) -> Any:
    if isinstance(obj, Mapping):
        return obj[name]
    return getattr(obj, name)


def identify_liquidity_raids(
    df: pd.DataFrame,
    swing_points: Sequence[SwingPoint | Mapping[str, Any]],
) -> list[LiquidityEvent]:
    """
    Identify liquidity raid events: price sweeps above/below swing points and closes through them.

    - Raid High: High > swing price and Close > swing price
    - Raid Low: Low < swing price and Close < swing price
    """
    raids: list[LiquidityEvent] = []
    required = ["Open Time", "High", "Low", "Close"]
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise KeyError(f"Missing columns in DataFrame: {missing}")

    for swing in swing_points:
        swing_date = _get_value(swing, "date")
        swing_price = float(_get_value(swing, "price"))
        swing_type = str(_get_value(swing, "type"))

        subsequent = df[df["Open Time"] > swing_date]
        if subsequent.empty:
            continue

        highs = subsequent["High"].to_numpy()
        lows = subsequent["Low"].to_numpy()
        closes = subsequent["Close"].to_numpy()
        times = subsequent["Open Time"].to_numpy()

        if swing_type == "high":
            for i in range(len(subsequent)):
                if highs[i] > swing_price and closes[i] > swing_price:
                    prev_max = highs[:i].max() if i > 0 else 0.0
                    if prev_max <= swing_price:
                        raids.append(
                            LiquidityEvent(
                                swept_datetime=swing_date,
                                swept_price=swing_price,
                                swept_type=swing_type,
                                sweep_datetime=times[i],
                                sweep_price=float(highs[i]),
                                sweep_type="raid_high",
                            )
                        )
                        break
        elif swing_type == "low":
            for i in range(len(subsequent)):
                if lows[i] < swing_price and closes[i] < swing_price:
                    prev_min = lows[:i].min() if i > 0 else inf
                    if prev_min >= swing_price:
                        raids.append(
                            LiquidityEvent(
                                swept_datetime=swing_date,
                                swept_price=swing_price,
                                swept_type=swing_type,
                                sweep_datetime=times[i],
                                sweep_price=float(lows[i]),
                                sweep_type="raid_low",
                            )
                        )
                        break

    return raids


def identify_liquidity_sweeps(
    df: pd.DataFrame,
    swing_points: Sequence[SwingPoint | Mapping[str, Any]],
) -> list[LiquidityEvent]:
    """
    Identify liquidity sweep events: price sweeps above/below swing points but closes back through.

    - Sweep High: High > swing price and Close < swing price
    - Sweep Low: Low < swing price and Close > swing price
    """
    sweeps: list[LiquidityEvent] = []
    required = ["Open Time", "High", "Low", "Close"]
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise KeyError(f"Missing columns in DataFrame: {missing}")

    for swing in swing_points:
        swing_date = _get_value(swing, "date")
        swing_price = float(_get_value(swing, "price"))
        swing_type = str(_get_value(swing, "type"))

        subsequent = df[df["Open Time"] > swing_date]
        if subsequent.empty:
            continue

        highs = subsequent["High"].to_numpy()
        lows = subsequent["Low"].to_numpy()
        closes = subsequent["Close"].to_numpy()
        times = subsequent["Open Time"].to_numpy()

        if swing_type == "high":
            for i in range(len(subsequent)):
                prev_max = highs[:i].max() if i > 0 else 0.0
                if prev_max <= swing_price and highs[i] > swing_price and closes[i] < swing_price:
                    sweeps.append(
                        LiquidityEvent(
                            swept_datetime=swing_date,
                            swept_price=swing_price,
                            swept_type=swing_type,
                            sweep_datetime=times[i],
                            sweep_price=float(highs[i]),
                            sweep_type="sweep_high",
                        )
                    )
                    break
        elif swing_type == "low":
            for i in range(len(subsequent)):
                prev_min = lows[:i].min() if i > 0 else inf
                if prev_min >= swing_price and lows[i] < swing_price and closes[i] > swing_price:
                    sweeps.append(
                        LiquidityEvent(
                            swept_datetime=swing_date,
                            swept_price=swing_price,
                            swept_type=swing_type,
                            sweep_datetime=times[i],
                            sweep_price=float(lows[i]),
                            sweep_type="sweep_low",
                        )
                    )
                    break

    return sweeps


__all__ = [
    "SwingPoint",
    "LiquidityEvent",
    "identify_liquidity_raids",
    "identify_liquidity_sweeps",
]
