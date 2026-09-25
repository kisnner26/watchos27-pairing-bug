"""pymobiledevice3 `remote pair-host`, but listening and advertising on IPv4 *and* IPv6.

Apple's own pairable host (remotepairingd) is reached by the watch over IPv6
link-local, while pymobiledevice3 11.19.1 binds 0.0.0.0 and publishes only an A
record. This wrapper removes that difference. Result on watchOS 27.2: the watch
lists the host and asks for its passcode, but never opens a TCP connection
(same as the unmodified `pair-host`).

Usage (pymobiledevice3 installed with pipx):
    ~/.local/pipx/venvs/pymobiledevice3/bin/python tools/pair_host_dualstack.py ["Host name"]
Then on the watch: Settings ▸ Developer ▸ Paired Macs ▸ Other Devices ▸ <host> ▸ Pair.
"""
import asyncio
import logging
import socket
import subprocess
import sys

from pymobiledevice3 import bonjour
from pymobiledevice3.remote import tunnel_service
from pymobiledevice3.remote.tunnel_service import PairableHostInfo, serve_pairable_host

PORT = 58123  # fixed, so the IPv4 and IPv6 sockets share the advertised port

logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(name)s %(levelname)s %(message)s")
logging.getLogger("asyncio").setLevel(logging.WARNING)


def en0_addresses() -> list[tuple[int, str]]:
    out = subprocess.run(["ifconfig", "en0"], capture_output=True, text=True).stdout
    addrs = []
    for line in out.splitlines():
        parts = line.split()
        if parts[:1] == ["inet"]:
            addrs.append((socket.AF_INET, parts[1]))
        elif parts[:1] == ["inet6"]:
            addrs.append((socket.AF_INET6, parts[1].split("%")[0]))
    return addrs


ADDRS = en0_addresses()
print("advertising addresses:", ADDRS, flush=True)
bonjour._local_addresses = lambda: ADDRS  # A + AAAA records

_orig_start_server = asyncio.start_server


async def start_server_all(handle, host=None, port=0, **kw):
    # host=None binds every interface, both address families
    return await _orig_start_server(handle, host=None, port=port, **kw)


tunnel_service.asyncio.start_server = start_server_all


async def main() -> None:
    info = PairableHostInfo(name=sys.argv[1] if len(sys.argv) > 1 else "Mac pmd3 v6", model="Mac17,7")
    print(f"identifier={info.identifier}", flush=True)

    def pin(p: str) -> None:
        print(f"\n  >>> CODE: {p}\n", flush=True)

    result = await serve_pairable_host(info, port=PORT, pin_callback=pin, timeout=300, heartbeat_interval=20)
    print("PAIRED:", result.peer_device, "record:", result.record_path, flush=True)


asyncio.run(main())
