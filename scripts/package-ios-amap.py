#!/usr/bin/env python3
"""Build the optional, self-contained Swift package. Never uploads artifacts."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def package(version, output, cache):
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", version):
        raise ValueError("version must be the core SDK's release version, without v")
    destination = output / f"DiminaMapAMap-{version}"
    archive = output / f"DiminaMapAMap-{version}.zip"
    if destination.exists() or archive.exists():
        raise FileExistsError(f"Output already exists: {destination} / {archive}")
    output.mkdir(parents=True, exist_ok=True)
    cache.mkdir(parents=True, exist_ok=True)
    vendors = json.loads((ROOT / "iOS/MapAMap/vendor.json").read_text())
    with tempfile.TemporaryDirectory(prefix="dimina-map-package-") as temp:
        work = Path(temp)
        package_root = work / destination.name
        frameworks = package_root / "Frameworks"
        sources = package_root / "Sources/DiminaMapAMap"
        frameworks.mkdir(parents=True)
        sources.mkdir(parents=True)
        for name, vendor in vendors.items():
            download = cache / f"{name}-{vendor['version']}.zip"
            if not download.exists():
                partial = download.with_suffix(".download")
                run("curl", "--fail", "--location", "--retry", "3", vendor["url"], "-o", partial)
                partial.rename(download)
            if hashlib.sha256(download.read_bytes()).hexdigest() != vendor["sha256"]:
                raise ValueError(f"Checksum mismatch: {download}")
            extracted = work / name
            with zipfile.ZipFile(download) as sdk:
                sdk.extractall(extracted)
            original = extracted / f"{name}.framework"
            if name == "MAMapKit":
                resources = sources / "Resources"
                resources.mkdir()
                shutil.copytree(original / "AMap.bundle", resources / "AMap.bundle")
            # Official fat archives contain arm64 device + x86_64 simulator, not arm64 simulator.
            slices = []
            for arch, platform in [("arm64", "iPhoneOS"), ("x86_64", "iPhoneSimulator")]:
                framework = work / f"{name}-{arch}" / original.name
                shutil.copytree(original, framework)
                run("xcrun", "lipo", original / name, "-thin", arch, "-output", framework / name)
                info_path = framework / "Info.plist"
                with info_path.open("rb") as stream:
                    info = plistlib.load(stream)
                info["CFBundleSupportedPlatforms"] = [platform]
                info["DTPlatformName"] = platform.lower()
                with info_path.open("wb") as stream:
                    plistlib.dump(info, stream)
                shutil.rmtree(framework / "_CodeSignature", ignore_errors=True)
                slices.extend(["-framework", framework])
            run("xcodebuild", "-create-xcframework", *slices, "-output", frameworks / f"{name}.xcframework")

        source = (ROOT / "iOS/dimina/DiminaKit/Map/DMPAMapProvider.swift").read_text()
        guard = "#if canImport(MAMapKit) && canImport(AMapFoundationKit)\n"
        if not source.startswith(guard) or not source.rstrip().endswith("#endif"):
            raise ValueError("Provider source layout changed; review the package generator")
        # This package explicitly depends on both SDKs: a missing SDK must fail compilation.
        source = "import Dimina\n" + source[len(guard):].rstrip().removesuffix("#endif")
        (sources / "DMPAMapProvider.swift").write_text(source)
        template = (ROOT / "iOS/MapAMap/Package.swift.template").read_text()
        (package_root / "Package.swift").write_text(template.replace("@VERSION@", version))
        shutil.copy(ROOT / "iOS/MapAMap/README.md", package_root / "README.md")
        shutil.copy(ROOT / "LICENSE", package_root / "LICENSE")
        shutil.copy(ROOT / "iOS/MapAMap/vendor.json", package_root / "vendor.json")
        (package_root / "NOTICE").write_text(
            "Dimina adapter source: Apache-2.0. Bundled AMap SDK binaries and resources:\n"
            "Copyright AutoNavi. All Rights Reserved. https://lbs.amap.com/\n"
        )
        shutil.copytree(package_root, destination)
    run("ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", destination, archive)
    print(archive)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--cache", type=Path, default=Path(tempfile.gettempdir()) / "dimina-amap-downloads")
    args = parser.parse_args()
    package(args.version, args.output.resolve(), args.cache.resolve())
