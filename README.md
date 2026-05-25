# Pitboss

Pitboss is an experimental zero-Python native generative media runtime. The project is still in feasibility study mode: the current goal is to test whether the architecture, contracts, and native backend seams make sense before committing to a full inference implementation.

The long-term goal is to support plugin-based image, video, and audio generation workflows with explicit model manifests, graph validation, native backend dispatch, diagnostics, and reproducible provenance.

## Current Status

This repository is a feasibility-study spike. It does not generate images yet.

Implemented now:

- Swift package with `PitbossCore`, `PitbossApple`, `PitbossCompat`, and `PitbossCLI` targets.
- `pitboss doctor`.
- `pitboss inspect plugins`.
- `pitboss validate <workflow.json>`.
- `pitboss policy-check`.
- Minimal Comfy API/workflow JSON parser.
- Internal graph IR.
- Plugin and backend descriptor contracts.
- Model bundle manifest type and fixture.
- Unsupported-node diagnostics.
- Linux-safe host probing with Apple/Core ML/MLX seams represented honestly.

## Commands

```sh
swift test
swift run pitboss doctor
swift run pitboss inspect plugins
swift run pitboss validate Fixtures/comfy/basic-api-workflow.json
swift run pitboss validate Fixtures/comfy/unsupported-api-workflow.json
swift run pitboss policy-check
```

## Zero-Python Policy

Pitboss runtime, build, and test code must not depend on Python, PyTorch, diffusers, transformers, ComfyUI, virtual environments, or shelling out to Python. Existing Python projects may be studied as reference material only.

Documentation is allowed to discuss Python ecosystem compatibility and forbidden dependencies. Runtime source is not allowed to invoke them.

## Linux Now, Mac Later

This spike was created on Linux with Swift 6.3.1. On Linux, `pitboss doctor` should report Core ML as unavailable and MLX as a backend contract stub. That is expected. When the project moves to Apple Silicon macOS, the next step is to replace the stubs with real Core ML and MLX backend probes.

## Repository Layout

- `Sources/PitbossCore`: graph, manifest, plugin, backend, diagnostic, provenance, and policy contracts.
- `Sources/PitbossApple`: Apple-platform probing and future Core ML/MLX backend seams.
- `Sources/PitbossCompat`: ecosystem importers such as Comfy and A1111 compatibility.
- `Sources/PitbossCLI`: command-line interface.
- `Tests`: unit tests for core contracts and compatibility parsing.
- `Fixtures`: small workflow and manifest examples.
- `ADR`: architecture decision records.
- `docs/PARTS_ATLAS.md`: feasibility map of subsystem sources, papers, reusable methods, and sideways implementation paths.

## First Real Inference Milestone

Recommended next inference milestone: run a small Core ML model component from a native Swift CLI on Apple Silicon, preferably VAE decode or text encoder invocation before full text-to-image. Full SDXL text-to-image should come after tokenizer parity, model manifest validation, and backend diagnostics are stronger.
