# ADR-0003: Plugin Capability System

Status: accepted for spike

## Decision

Pitboss represents extensibility through explicit plugin descriptors and capabilities.

A capability is a namespaced contract such as:

- `model.family.sdxl`
- `pipeline.text2image`
- `adapter.lora`
- `conditioning.controlnet`
- `backend.coreml`
- `workflow.import.comfy`

A plugin declares:

- Stable id.
- Display name.
- Version.
- Kind.
- Capabilities provided.
- Permissions requested.
- Node types provided.
- Asset types supported.
- Diagnostic hooks.

## Backend Relationship

Backends are described separately from feature plugins because hardware execution and model-family semantics change at different rates. Core ML and MLX can coexist behind one backend registry.

## Unsupported Features

Unsupported workflow nodes or missing capabilities are reported as diagnostics with stable codes and suggested fixes. Pitboss must not silently skip unsupported behavior.

## Consequences

- The prototype can validate workflows before execution exists.
- Agents and humans can inspect what the runtime can do.
- Future plugins need permission declarations instead of arbitrary filesystem or shell access.
