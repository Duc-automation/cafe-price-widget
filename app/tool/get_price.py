#!/usr/bin/env python3
"""
get_price.py - Lay bang gia ca phe tu api.chocaphe.vn

Chi dung thu vien chuan cua Python (khong can pip install gi).

Cach dung:
    python app/tool/get_price.py                 # ban ghi moi nhat
    python app/tool/get_price.py 2026-09-10      # ngay cu the (yyyy-MM-dd)

Hoac dung venv cua du an:
    .venv\\Scripts\\python.exe app\\tool\\get_price.py
"""

from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request

# Console Windows hay dung cp1252 -> in tieng Viet bi loi khi pipe output.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:  # noqa: BLE001 - Python cu / khong ho tro
    pass

BASE_URL = "https://api.chocaphe.vn/v1/prices"

# Header giong het app Flutter (app/lib/services/coffee_price_api.dart)
HEADERS = {
    "Accept": "application/json",
    "User-Agent": "gia-ca-phe-widget/1.0",
}

TIMEOUT = 20  # giay


def fetch(date: str | None = None) -> dict:
    """Goi API. date=None -> ban ghi moi nhat; date='yyyy-MM-dd' -> ngay do.

    Luu y: URL phai co '/v1/' - thieu se bi may chu tra HTTP 433.
    """
    url = BASE_URL + (f"?date={urllib.parse.quote(date)}" if date else "")
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as res:
        if res.status != 200:
            raise RuntimeError(f"May chu tra loi HTTP {res.status}")
        return json.load(res)


def print_price(body: dict) -> None:
    if body.get("status_code") != 200:
        print("API tra ve loi:", body.get("message"))
        return

    d = body["data"]
    dom = d.get("domestic_price") or {}

    print(f"\n=== GIA CA PHE NGAY {d.get('date')} ===")
    print(f"Trung binh noi dia : {dom.get('average_price')}  ({dom.get('price_change')})")
    print(f"Cap nhat luc       : {d.get('updated_at')}")
    print()

    rows = dom.get("item") or []
    print(f"{'Thi truong':<22}{'Gia':>12}{'Thay doi':>12}")
    print("-" * 46)
    for it in rows:
        print(
            f"{it.get('market', ''):<22}"
            f"{it.get('average_price', ''):>12}"
            f"{it.get('price_change', ''):>12}"
        )

    intl = d.get("international_price") or {}
    robusta = (intl.get("coffee_liffe") or [{}])[0]  # London, USD/tan
    arabica = (intl.get("coffee_ice") or [{}])[0]  # New York, cent/lb
    if robusta.get("Ask"):
        print(f"\nRobusta London  : {robusta['Ask']} USD/tan (ky han {robusta.get('Month')})")
    if arabica.get("Ask"):
        print(f"Arabica New York: {arabica['Ask']} cent/lb (ky han {arabica.get('Month')})")

    if d.get("title"):
        print(f"\n{d['title']}")


def main() -> int:
    date = sys.argv[1] if len(sys.argv) > 1 else None
    try:
        print_price(fetch(date))
    except Exception as e:  # noqa: BLE001
        print("LOI:", e)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
