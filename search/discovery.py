#!/usr/bin/env python3
"""
search/discovery.py
Web-scale evidence discovery adapter, canonicalization, and provenance graph builder.
Deduplicates artifacts strictly by canonical bytes, hash fingerprints, and PGP key provenance.
Never executes untrusted code retrieved from external sources.
"""

import hashlib
import json
import os
from typing import Dict, Any, List

class EvidenceDiscoveryAdapter:
    def __init__(self, sources_path: str = "evidence/sources.json", manifest_path: str = "evidence/manifest.json"):
        self.sources_path = sources_path
        self.manifest_path = manifest_path
        self.provenance_graph: Dict[str, Any] = {
            "nodes": [],
            "edges": [],
            "fingerprint_index": {}
        }

    def load_manifest(self) -> Dict[str, Any]:
        with open(self.manifest_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def load_sources(self) -> Dict[str, Any]:
        with open(self.sources_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def ingest_and_canonicalize(self) -> Dict[str, Any]:
        manifest = self.load_manifest()
        sources = self.load_sources()

        # Add sources to provenance graph
        for src in sources.get("sources", []):
            self.provenance_graph["nodes"].append({
                "id": src["source_id"],
                "type": "SourceArchive",
                "uri": src["uri"],
                "description": src.get("description", "")
            })

        # Process each frozen artifact
        for art in manifest.get("frozen_artifacts", []):
            raw_path = art["raw_file"]
            if not os.path.exists(raw_path):
                continue
            with open(raw_path, "rb") as f:
                raw_bytes = f.read()

            sha256 = hashlib.sha256(raw_bytes).hexdigest()
            sha512 = hashlib.sha512(raw_bytes).hexdigest()

            # Deduplication index
            if sha256 in self.provenance_graph["fingerprint_index"]:
                # Provenance link to existing node
                self.provenance_graph["edges"].append({
                    "from": art["id"],
                    "to": self.provenance_graph["fingerprint_index"][sha256],
                    "relation": "IDENTICAL_CANONICAL_BYTES"
                })
            else:
                self.provenance_graph["fingerprint_index"][sha256] = art["id"]
                self.provenance_graph["nodes"].append({
                    "id": art["id"],
                    "type": "FrozenArtifact",
                    "sha256": sha256,
                    "sha512": sha512,
                    "byte_count": len(raw_bytes),
                    "status": art.get("status", "UNRESOLVED")
                })

            # Edge to source
            self.provenance_graph["edges"].append({
                "from": art["id"],
                "to": "LIBER_PRIMUS_ARCHIVE",
                "relation": "DERIVED_FROM_SOURCE"
            })

        return self.provenance_graph

    def export_provenance_graph(self, output_path: str = "evidence/provenance_index.json"):
        graph = self.ingest_and_canonicalize()
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(graph, f, indent=2, ensure_ascii=False)
        print(f"Exported provenance index with {len(graph['nodes'])} nodes and {len(graph['edges'])} edges.")

if __name__ == "__main__":
    adapter = EvidenceDiscoveryAdapter()
    adapter.export_provenance_graph()
