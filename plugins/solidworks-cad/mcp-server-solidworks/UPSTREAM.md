# Bundled MCP provenance

This directory contains source derived from **SolidPilot / mcp-server-solidworks**.

- Source snapshot: https://github.com/tian-yu200/dsh-solidworks
- Snapshot commit: `bc2b86e007c5cde4f84c0095aaebcf76fe21ff09`
- Upstream copyright: Copyright (c) 2025-2026 Cagatay Bakan
- License: GNU Affero General Public License v3.0 only

This v2.0.0 distribution was packaged on 2026-11-24 with the following standalone-plugin adjustments:
- Removed machine-specific BOM template and `D:\solidworks` fallback paths so templates and interop assemblies resolve from the user's `SOLIDWORKS_INSTALL_DIR` or standard SolidWorks installation.
- Merged runtime Python dependencies (`mcp`, `httpx`, `python-dotenv`, `ezdxf`, `Pillow`, `pypdfium2`) into the top-level `requirements.txt` for isolated plugin venv setup.
- Excluded test suites, sample media, and unused low-level adapter entry points so only the twelve high-level `mcp__solidworks__` tools and `solidworks://skill/references/*` resources are exposed.

The original `LICENSE` and `CLA.md` are preserved in this directory. Build outputs,
NuGet packages, local virtual environments, logs, SolidWorks files, and proprietary
SolidWorks interop assemblies are intentionally excluded from this distribution.
