#!/usr/bin/env python3
"""Validate the core HAR itself before publishing to OHPM."""
import json
from pathlib import Path
import sys
import tarfile

root = Path(__file__).resolve().parents[1]
core = json.loads((root / "dimina/oh-package.json5").read_text())
archive = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "dimina/build/default/outputs/default/dimina.har"
with tarfile.open(archive) as har:
    metadata = json.load(har.extractfile("package/oh-package.json5"))
    assert metadata["name"] == core["name"], "unexpected core package name"
    assert metadata["version"] == core["version"], "stale core HAR version"
    assert metadata["license"] == core["license"] == "Apache-2.0"
    for filename in ["LICENSE", "README.md", "CHANGELOG.md", metadata.get("types", metadata.get("main", "Index.ets"))]:
        path = f"package/{filename}"
        assert path in har.getnames(), f"missing {path} in {archive}"
        member = har.getmember(path)
        assert member.isfile() and har.extractfile(member).read().strip(), f"empty or invalid {path}"
    assert har.extractfile("package/LICENSE").read() == (root / "dimina/LICENSE").read_bytes(), "license differs from source"
    assert not metadata.get("metadata", {}).get("debug", False), "publish a release HAR"
print(f"Validated {metadata['name']}@{metadata['version']}: release HAR with non-empty license and documentation")
