import argparse
import json
import os
import sys
from typing import Any, Dict

import requests

API_URL = "https://api.tailscale.com/api/v2/tailnet"

def get_acl(tailnet: str, api_key: str) -> Dict[str, Any]:
    resp = requests.get(f"{API_URL}/{tailnet}/acl", auth=(api_key, ""))
    resp.raise_for_status()
    return resp.json()

def set_acl(tailnet: str, api_key: str, data: Dict[str, Any]) -> None:
    resp = requests.post(
        f"{API_URL}/{tailnet}/acl",
        auth=(api_key, ""),
        headers={"Content-Type": "application/json"},
        data=json.dumps(data),
    )
    resp.raise_for_status()

def get_ip_ranges(tailnet: str, api_key: str) -> Dict[str, Any]:
    resp = requests.get(f"{API_URL}/{tailnet}/ip-ranges", auth=(api_key, ""))
    resp.raise_for_status()
    return resp.json()

def set_ip_ranges(tailnet: str, api_key: str, data: Dict[str, Any]) -> None:
    resp = requests.post(
        f"{API_URL}/{tailnet}/ip-ranges",
        auth=(api_key, ""),
        headers={"Content-Type": "application/json"},
        data=json.dumps(data),
    )
    resp.raise_for_status()


def main() -> None:
    parser = argparse.ArgumentParser(description="Export or import Tailscale ACL configuration")
    parser.add_argument(
        "action",
        choices=["export", "import"],
        help="Action to perform on the ACL configuration",
    )
    parser.add_argument("file", help="Path to ACL JSON file")
    parser.add_argument(
        "--tailnet",
        default=os.getenv("TAILSCALE_TAILNET"),
        help="Tailscale tailnet name (or set TAILSCALE_TAILNET)",
    )
    parser.add_argument(
        "--api-key",
        default=os.getenv("TAILSCALE_API_KEY"),
        help="Tailscale API key (or set TAILSCALE_API_KEY)",
    )
    args = parser.parse_args()

    if not args.tailnet:
        parser.error(
            "Tailnet must be provided via --tailnet or TAILSCALE_TAILNET env"
        )
    if not args.api_key:
        parser.error(
            "Tailscale API key must be provided via --api-key or TAILSCALE_API_KEY env"
        )

    if args.action == "export":
        data = {
            "acl": get_acl(args.tailnet, args.api_key),
            "ip_ranges": get_ip_ranges(args.tailnet, args.api_key),
        }
        with open(args.file, "w") as f:
            json.dump(data, f, indent=2)
    else:
        with open(args.file, "r") as f:
            config = json.load(f)
        set_acl(args.tailnet, args.api_key, config.get("acl", {}))
        if "ip_ranges" in config:
            set_ip_ranges(args.tailnet, args.api_key, config["ip_ranges"])


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
