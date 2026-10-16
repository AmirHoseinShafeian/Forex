from __future__ import annotations

import math
import os
import threading
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import FastAPI, HTTPException, Query

MOCK_MODE = os.getenv("MT5_BRIDGE_MOCK", "0") == "1"
MT5 = None

if not MOCK_MODE:
    try:
        import MetaTrader5 as MT5  # type: ignore[assignment]
    except ImportError:
        MT5 = None

app = FastAPI(title="XAUUSD MT5 Bridge", version="1.0.0")
MT5_LOCK = threading.RLock()

TIMEFRAME_NAMES = {"M1", "M5", "M15", "M30", "H1", "H4", "D1"}
MOCK_SECONDS = {
    "M1": 60,
    "M5": 300,
    "M15": 900,
    "M30": 1800,
    "H1": 3600,
    "H4": 14400,
    "D1": 86400,
}


def _error(status: int, code: str, message: str) -> HTTPException:
    return HTTPException(status_code=status, detail={"code": code, "message": message})


def _ensure_mt5() -> Any:
    if MOCK_MODE:
        return None
    if MT5 is None:
        raise _error(503, "python_dependency_missing", "MetaTrader5 package is not installed")
    if MT5.terminal_info() is None and not MT5.initialize():
        code, message = MT5.last_error()
        raise _error(503, "mt5_unavailable", f"MT5 initialize failed ({code}): {message}")
    return MT5


def _select_symbol(symbol: str) -> Any:
    mt5 = _ensure_mt5()
    info = mt5.symbol_info(symbol)
    if info is None:
        raise _error(404, "symbol_not_found", f"Symbol '{symbol}' was not found in MT5")
    if not info.visible and not mt5.symbol_select(symbol, True):
        raise _error(409, "symbol_unavailable", f"Symbol '{symbol}' cannot be selected")
    return info


def _utc_iso(timestamp: float) -> str:
    return datetime.fromtimestamp(timestamp, tz=timezone.utc).isoformat().replace("+00:00", "Z")


def _valid_price(value: float) -> bool:
    return math.isfinite(value) and value > 0


@app.get("/health")
def health() -> dict[str, Any]:
    if MOCK_MODE:
        return {"status": "ok", "connected": True, "mode": "mock", "terminal": "Mock MT5"}
    with MT5_LOCK:
        mt5 = _ensure_mt5()
        terminal = mt5.terminal_info()
        account = mt5.account_info()
    connected = terminal is not None and account is not None
    return {
        "status": "ok" if connected else "error",
        "connected": connected,
        "mode": "live",
        "terminal": terminal.name if terminal else None,
        "error": None
        if connected
        else "MetaTrader 5 is not connected to a trading account",
    }


@app.get("/symbols")
def symbols() -> dict[str, Any]:
    if MOCK_MODE:
        return {"symbols": [{"name": "XAUUSD", "digits": 3, "description": "Gold vs US Dollar", "visible": True}]}
    with MT5_LOCK:
        mt5 = _ensure_mt5()
        values = mt5.symbols_get()
    if values is None:
        raise _error(502, "symbols_failed", "MT5 did not return a symbol list")
    return {
        "symbols": [
            {"name": item.name, "digits": item.digits, "description": item.description, "visible": item.visible}
            for item in values
        ]
    }


@app.get("/tick")
def tick(symbol: str = Query(min_length=1, max_length=64)) -> dict[str, Any]:
    if MOCK_MODE:
        now = datetime.now(tz=timezone.utc)
        phase = now.timestamp() / 15
        bid = 4121.0 + math.sin(phase) * 1.5
        ask = bid + 0.42
        return {
            "symbol": symbol,
            "timeUtc": now.isoformat().replace("+00:00", "Z"),
            "bid": round(bid, 3),
            "ask": round(ask, 3),
            "last": round((bid + ask) / 2, 3),
            "lastPriceSource": "midpoint",
            "spreadPrice": round(ask - bid, 3),
            "spreadPoints": 420.0,
            "digits": 3,
            "point": 0.001,
        }

    with MT5_LOCK:
        mt5 = _ensure_mt5()
        info = _select_symbol(symbol)
        value = mt5.symbol_info_tick(symbol)
    if value is None:
        raise _error(502, "tick_failed", f"MT5 did not return a tick for '{symbol}'")
    if (
        not _valid_price(value.bid)
        or not _valid_price(value.ask)
        or not math.isfinite(value.last)
        or value.last < 0
        or value.ask < value.bid
    ):
        raise _error(502, "invalid_tick", "MT5 returned invalid Bid/Ask/Last values")
    last = value.last if value.last > 0 else (value.bid + value.ask) / 2
    return {
        "symbol": symbol,
        "timeUtc": _utc_iso(value.time_msc / 1000 if value.time_msc else value.time),
        "bid": value.bid,
        "ask": value.ask,
        "last": last,
        "lastPriceSource": "last" if value.last > 0 else "midpoint",
        "spreadPrice": value.ask - value.bid,
        "spreadPoints": (value.ask - value.bid) / info.point,
        "digits": info.digits,
        "point": info.point,
    }


@app.get("/candles")
def candles(
    symbol: str = Query(min_length=1, max_length=64),
    timeframe: str = Query(pattern="^(M1|M5|M15|M30|H1|H4|D1)$"),
    count: int = Query(default=500, ge=1, le=2000),
) -> dict[str, Any]:
    if timeframe not in TIMEFRAME_NAMES:
        raise _error(400, "invalid_timeframe", f"Unsupported timeframe '{timeframe}'")
    if MOCK_MODE:
        seconds = MOCK_SECONDS[timeframe]
        now = datetime.now(tz=timezone.utc)
        end = int(now.timestamp()) // seconds * seconds
        rows = []
        for index in range(count):
            timestamp = end - (count - 1 - index) * seconds
            base = 4118 + math.sin(index * 0.31) * 8 + index * 0.015
            close = base + math.sin(index * 1.17) * 2.2
            rows.append({
                "openTimeUtc": _utc_iso(timestamp),
                "open": round(base, 3),
                "high": round(max(base, close) + 1.2, 3),
                "low": round(min(base, close) - 1.2, 3),
                "close": round(close, 3),
                "tickVolume": 50 + index % 80,
            })
        return {"symbol": symbol, "timeframe": timeframe, "candles": rows}

    with MT5_LOCK:
        mt5 = _ensure_mt5()
        _select_symbol(symbol)
        timeframe_value = getattr(mt5, f"TIMEFRAME_{timeframe}")
        rates = mt5.copy_rates_from_pos(symbol, timeframe_value, 0, count)
    if rates is None or len(rates) == 0:
        code, message = mt5.last_error()
        raise _error(502, "candles_failed", f"MT5 copy_rates failed ({code}): {message}")
    rows = []
    for rate in rates:
        values = [float(rate[name]) for name in ("open", "high", "low", "close")]
        if not all(_valid_price(value) for value in values):
            raise _error(502, "invalid_candle", "MT5 returned a non-finite candle price")
        if values[1] < max(values[0], values[3]) or values[2] > min(values[0], values[3]):
            raise _error(502, "invalid_candle", "MT5 returned an invalid OHLC range")
        rows.append({
            "openTimeUtc": _utc_iso(int(rate["time"])),
            "open": values[0],
            "high": values[1],
            "low": values[2],
            "close": values[3],
            "tickVolume": int(rate["tick_volume"]),
        })
    return {"symbol": symbol, "timeframe": timeframe, "candles": rows}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8765)
