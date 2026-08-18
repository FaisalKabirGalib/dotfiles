#!/usr/bin/env python3
import json
import os
import sqlite3
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path


STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "omarchy" / "agents" / "usage"


def number(value):
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0


def date_for(value):
    if isinstance(value, (int, float)):
        if value > 10_000_000_000:
            value /= 1000
        return datetime.fromtimestamp(value).strftime("%Y-%m-%d")
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).astimezone().strftime("%Y-%m-%d")
    except (TypeError, ValueError):
        return datetime.now().strftime("%Y-%m-%d")


def empty_stats():
    now = datetime.now()
    dates = [(now - timedelta(days=offset)).strftime("%Y-%m-%d") for offset in range(6, -1, -1)]
    return {
        "todayPrompts": 0,
        "todaySessions": set(),
        "todayTotalTokens": 0,
        "todayTokensByModel": {},
        "recentDays": {date: 0 for date in dates},
        "totalPrompts": 0,
        "totalSessions": set(),
        "activeDates": set(),
        "modelUsage": {},
    }


def add_usage(stats, day, session, model, input_tokens, output_tokens, cache_read, cache_write):
    total = input_tokens + output_tokens + cache_read + cache_write
    if total <= 0:
        return
    stats["totalPrompts"] += 1
    stats["totalSessions"].add(session)
    stats["activeDates"].add(day)
    bucket = stats["modelUsage"].setdefault(model or "unknown", {
        "inputTokens": 0,
        "outputTokens": 0,
        "cacheReadInputTokens": 0,
        "cacheCreationInputTokens": 0,
    })
    bucket["inputTokens"] += input_tokens
    bucket["outputTokens"] += output_tokens
    bucket["cacheReadInputTokens"] += cache_read
    bucket["cacheCreationInputTokens"] += cache_write
    if day in stats["recentDays"]:
        stats["recentDays"][day] += total
    if day == datetime.now().strftime("%Y-%m-%d"):
        stats["todayPrompts"] += 1
        stats["todaySessions"].add(session)
        stats["todayTotalTokens"] += total
        stats["todayTokensByModel"][model or "unknown"] = stats["todayTokensByModel"].get(model or "unknown", 0) + total


def record(agent_id, name, stats):
    return {
        "schemaVersion": 1,
        "id": agent_id,
        "name": name,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "ready": stats["totalPrompts"] > 0,
        "hasLocalStats": True,
        "hasPromptStats": True,
        "usageStatusText": "Local usage",
        "authHelpText": "Usage is read from local sessions.",
        "limits": [],
        "todayPrompts": stats["todayPrompts"],
        "todaySessions": len(stats["todaySessions"]),
        "todayTotalTokens": stats["todayTotalTokens"],
        "todayTokensByModel": stats["todayTokensByModel"],
        "recentDays": [{"date": date, "messageCount": count} for date, count in stats["recentDays"].items()],
        "totalPrompts": stats["totalPrompts"],
        "totalSessions": len(stats["totalSessions"]),
        "activeDays": len(stats["activeDates"]),
        "activeDates": sorted(stats["activeDates"]),
        "modelUsage": stats["modelUsage"],
    }


def pi_stats():
    stats = empty_stats()
    root = Path.home() / ".pi" / "agent" / "sessions"
    if not root.is_dir():
        return stats
    for path in root.rglob("*.jsonl"):
        try:
            for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
                entry = json.loads(line)
                message = entry.get("message") or {}
                if entry.get("type") != "message" or message.get("role") != "assistant":
                    continue
                usage = message.get("usage") or {}
                total = number(usage.get("totalTokens"))
                input_tokens = number(usage.get("input"))
                output_tokens = number(usage.get("output"))
                cache_read = number(usage.get("cacheRead"))
                cache_write = number(usage.get("cacheWrite"))
                if total and not (input_tokens or output_tokens or cache_read or cache_write):
                    input_tokens = total
                add_usage(stats, date_for(entry.get("timestamp") or message.get("timestamp")), str(path), message.get("model"), input_tokens, output_tokens, cache_read, cache_write)
        except OSError:
            continue
    return stats


def opencode_stats():
    stats = empty_stats()
    db = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / "opencode" / "opencode.db"
    if not db.is_file():
        return stats
    try:
        connection = sqlite3.connect(db.resolve().as_uri() + "?mode=ro", uri=True, timeout=2)
        connection.execute("PRAGMA query_only = ON")
        rows = connection.execute("SELECT session_id, data FROM message")
        for session_id, raw in rows:
            try:
                entry = json.loads(raw)
                if entry.get("role") != "assistant":
                    continue
                tokens = entry.get("tokens") or {}
                cache = tokens.get("cache") or {}
                add_usage(
                    stats,
                    date_for((entry.get("time") or {}).get("created")),
                    "opencode:" + str(session_id),
                    entry.get("modelID"),
                    number(tokens.get("input")),
                    number(tokens.get("output")) + number(tokens.get("reasoning")),
                    number(cache.get("read")),
                    number(cache.get("write")),
                )
            except (TypeError, ValueError, json.JSONDecodeError):
                continue
        connection.close()
    except sqlite3.Error:
        return stats
    return stats


def write_record(payload):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    target = STATE_DIR / (payload["id"] + ".json")
    with tempfile.NamedTemporaryFile("w", dir=STATE_DIR, prefix="." + payload["id"] + ".", delete=False) as handle:
        json.dump(payload, handle, separators=(",", ":"))
        handle.write("\n")
    os.replace(handle.name, target)


def main():
    write_record(record("pi", "Pi", pi_stats()))
    write_record(record("opencode", "OpenCode", opencode_stats()))


if __name__ == "__main__":
    main()
