# ADR-0001: Architecture

Status: accepted for spike

## Decision

Pitboss will be a native runtime with a small explicit core, plugin-provided capabilities, replaceable backends, and an internal graph IR. The first implementation is a Swift package with separate core, Apple, compatibility, and CLI targets.

## Rationale

Mac-first local generative media should not inherit notebook-era setup, dynamic runtime loading, or Python package fragility. A native runtime gives Pitboss predictable packaging, clearer platform diagnostics, and a more realistic path to Apple Silicon acceleration.

The core owns contracts:

- Graph IR.
- Workflow validation.
- Model manifests.
- Plugin and capability registries.
- Backend descriptors.
- Diagnostics.
- Provenance and deterministic metadata.

Plugins own model-family and ecosystem-specific behavior. This keeps SDXL, LoRA, ControlNet, Comfy import, A1111 compatibility, audio, and video extensions from corrupting the core.

## Why Not A Direct Diffusers Port

A direct port would reproduce the shape of the Python ecosystem instead of defining a stable native runtime. Pitboss should interoperate with selected ecosystem formats while keeping loading, validation, provenance, and backend dispatch explicit.

## Consequences

- The first prototype validates workflows rather than generating images.
- Unsupported nodes are diagnostics, not hidden dynamic behavior.
- Native backend implementations can arrive incrementally behind stable contracts.
