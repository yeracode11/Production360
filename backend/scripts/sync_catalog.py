#!/usr/bin/env python3
"""Синк каталога: POST JSON-выгрузки из 1С на backend API."""

import argparse
import json
import sys
from pathlib import Path

import httpx

SYNC_ENDPOINTS = {
    "edinicaIzm": "/sync/units",
    "nomenklatura": "/sync/products",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync catalog JSON from 1C to backend")
    parser.add_argument("file", type=Path, help="JSON file with dataType + data")
    parser.add_argument("--base-url", default="http://localhost:8000")
    args = parser.parse_args()

    if not args.file.exists():
        print(f"File not found: {args.file}")
        sys.exit(1)

    with args.file.open(encoding="utf-8") as f:
        payload = json.load(f)

    data_type = payload.get("dataType")
    endpoint = SYNC_ENDPOINTS.get(data_type)
    if endpoint is None:
        print(f"Unknown dataType: {data_type!r}. Expected: {list(SYNC_ENDPOINTS)}")
        sys.exit(1)

    url = f"{args.base_url.rstrip('/')}{endpoint}"
    response = httpx.post(url, json=payload, timeout=120.0)
    if response.status_code >= 400:
        print(f"Error {response.status_code}: {response.text}")
        sys.exit(1)

    print(response.json())


if __name__ == "__main__":
    main()
