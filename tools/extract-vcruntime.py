#!/usr/bin/env python3
"""Extract and verify the project's pinned x64 VC++ runtime DLLs."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def cab_ranges(data: bytes) -> list[tuple[int, int]]:
    ranges = []
    offset = 0
    while True:
        offset = data.find(b"MSCF", offset)
        if offset < 0:
            return ranges
        if offset + 12 <= len(data):
            size = struct.unpack_from("<I", data, offset + 8)[0]
            if size >= 36 and offset + size <= len(data):
                ranges.append((offset, size))
        offset += 4


def run_7zz(executable: str, cab: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [executable, "x", "-y", f"-o{destination}", str(cab)],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def is_cab(path: Path) -> bool:
    with path.open("rb") as stream:
        return stream.read(4) == b"MSCF"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--installer", required=True, type=Path)
    parser.add_argument("--provenance", required=True, type=Path)
    parser.add_argument("--destination", required=True, type=Path)
    parser.add_argument("--sevenzip", default=shutil.which("7zz") or "7zz")
    args = parser.parse_args()

    provenance = json.loads(args.provenance.read_text(encoding="utf-8"))
    installer_hash = sha256(args.installer)
    expected_installer_hash = provenance["official_vc_redist_x64_exe_sha256"].upper()
    if installer_hash != expected_installer_hash:
        raise SystemExit(
            f"VC_redist.x64.exe SHA-256 mismatch: {installer_hash} != {expected_installer_hash}"
        )

    expected = {item["file"]: item["sha256"].upper() for item in provenance["files"]}
    args.destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="madeira-vcredist-") as temp_name:
        work = Path(temp_name)
        data = args.installer.read_bytes()
        outer_cabs = []
        for index, (offset, size) in enumerate(cab_ranges(data)):
            cab = work / f"outer-{index}.cab"
            cab.write_bytes(data[offset : offset + size])
            outer_cabs.append(cab)

        if not outer_cabs:
            raise SystemExit("No embedded CAB archives found in the Microsoft installer")

        nested_cabs = []
        for index, cab in enumerate(outer_cabs):
            extracted = work / f"outer-{index}"
            run_7zz(args.sevenzip, cab, extracted)
            for path in extracted.rglob("*"):
                if path.is_file() and is_cab(path):
                    nested_cabs.append(path)

        found: dict[str, Path] = {}
        for index, cab in enumerate(nested_cabs):
            extracted = work / f"nested-{index}"
            run_7zz(args.sevenzip, cab, extracted)
            for path in extracted.rglob("*"):
                if path.is_file():
                    name = path.name
                    if name.endswith("_amd64"):
                        name = name[: -len("_amd64")]
                    if name in expected and sha256(path) == expected[name]:
                        found[name] = path

        missing = sorted(set(expected) - set(found))
        if missing:
            raise SystemExit("Expected signed Microsoft DLLs not found: " + ", ".join(missing))

        for name, source in found.items():
            shutil.copyfile(source, args.destination / name)
            if sha256(args.destination / name) != expected[name]:
                raise SystemExit(f"Hash changed while staging {name}")

    print(f"Verified and staged {len(found)} Microsoft VC++ runtime DLLs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
