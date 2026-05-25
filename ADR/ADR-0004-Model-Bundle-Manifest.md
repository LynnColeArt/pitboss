# ADR-0004: Model Bundle Manifest

Status: accepted for spike

## Decision

Pitboss model bundles use strict manifests represented by `PitbossModelManifest`. A manifest describes model family, pipeline types, assets, modules, tokenizers, scheduler defaults, adapter support, control support, backend artifacts, minimum runtime version, and provenance.

## Rationale

Generative media workflows fail badly when model files are discovered by magic folder conventions alone. Strict manifests allow Pitboss to validate a workflow before attempting execution, explain missing artifacts, plan memory, and record provenance.

## Artifact Kinds

The manifest supports these backend artifact kinds:

- `coreml`
- `mlx`
- `safetensors`
- `gguf`
- `onnx`
- `native`

Safetensors can be an interchange or adapter format. Core ML and MLX artifacts are backend-specific execution artifacts. The manifest binds them together without forcing one universal tensor runtime.

## Consequences

- First manifests may feel verbose.
- Validation becomes possible before loading large model bodies.
- Multiple backend artifacts can represent the same conceptual module.
