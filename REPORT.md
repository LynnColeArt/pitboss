# Pitboss Research Report

## 1. Executive Summary

Pitboss is feasible as a zero-Python native runtime spine, but the first phase should stay contract-first. The useful near-term win is not image quality; it is a runtime that can inspect workflows, validate capabilities, describe model bundles, and report unsupported behavior without loading Python infrastructure.

The strongest Apple-native path is Core ML for the first real inference milestone, with MLX as a parallel research/backend track. Safetensors and tokenizer support remain critical because ecosystem assets are not native Apple bundles by default.

Recommended next milestone: on Apple Silicon, run a single Core ML model component from Swift, preferably VAE decode or text encoder invocation, before attempting full SDXL text-to-image.

## 2. Existing Projects Surveyed

- Apple `ml-stable-diffusion`: https://github.com/apple/ml-stable-diffusion
- Argmax DiffusionKit: https://github.com/argmaxinc/DiffusionKit
- MLX Swift: https://github.com/ml-explore/mlx-swift
- MLX examples: https://github.com/ml-explore/mlx-examples
- Core ML compute unit documentation: https://developer.apple.com/documentation/coreml/mlcomputeunits
- Safetensors: https://github.com/huggingface/safetensors
- Tokenizers: https://github.com/huggingface/tokenizers
- ComfyUI: https://github.com/comfyanonymous/ComfyUI
- ComfyUI docs: https://docs.comfy.org/
- AUTOMATIC1111 Stable Diffusion WebUI: https://github.com/AUTOMATIC1111/stable-diffusion-webui
- ControlNet paper: https://arxiv.org/abs/2302.05543
- LoRA paper: https://arxiv.org/abs/2106.09685
- Stable Audio Open: https://github.com/Stability-AI/stable-audio-tools
- Stable Video Diffusion paper: https://arxiv.org/abs/2311.15127

## 3. Reusable Parts

Apple `ml-stable-diffusion` is the most relevant reference for Swift invoking Core ML diffusion components. It is valuable for pipeline shape, Core ML package expectations, scheduler loops, and Apple-platform integration patterns.

DiffusionKit is worth studying for a more modern Swift package shape that considers both Core ML and MLX-style execution. It should be treated as a dependency candidate only after license, API stability, supported model families, and Python tooling boundaries are reviewed on the Mac.

MLX Swift is reusable as a possible backend interface and tensor execution layer, especially for Apple Silicon experiments that do not fit Core ML conversion cleanly.

Safetensors is reusable as a format specification and security model. Pitboss should implement or bind a native reader that can inspect metadata and optionally memory-map tensor bodies.

ComfyUI and A1111 are reusable as compatibility references, not runtime dependencies.

## 4. Non-Reusable Parts

Python execution systems are not reusable inside Pitboss runtime:

- ComfyUI execution engine.
- A1111 extension system.
- diffusers pipelines.
- PyTorch model loading.
- Python conversion scripts as build/runtime dependencies.

These systems can inform semantics, file formats, naming conventions, and migration diagnostics.

## 5. Licenses Noticed

License review must be repeated before vendoring code. Initial notes:

- Apple `ml-stable-diffusion` is available on GitHub and should be reviewed before reuse.
- DiffusionKit must be reviewed before direct dependency or fork.
- Hugging Face safetensors and tokenizers have permissive open-source positioning, but exact license obligations must be checked at vendoring time.
- ComfyUI and A1111 are reference-only for this phase.

## 6. Native-Code Opportunities

- Swift CLI and package contracts.
- Core ML backend probing and invocation.
- MLX backend probing and invocation.
- Native safetensors metadata reader.
- Native CLIP BPE tokenizer for the first tokenizer parity slice.
- Apple Vision/Core Image preprocessors for selected ControlNet inputs.
- Structured diagnostics and provenance recording.

## 7. Python Dependencies To Avoid

Pitboss must not depend on Python, pip, virtual environments, PyTorch, diffusers, transformers, ComfyUI, or A1111 at runtime. The policy checker now focuses on runtime/build/test surfaces while allowing documentation to discuss these boundaries.

## 8. Core ML / MLX Feasibility

Core ML is the best first execution target because Apple provides stable Swift-facing APIs and compute-unit selection. Pitboss should expose which backend is selected and whether a model is expected to use CPU, GPU, Neural Engine, or a fallback.

MLX is attractive for a more flexible native tensor backend. It may be better for research velocity and models that are awkward to convert to Core ML. Pitboss should keep Core ML and MLX behind separate backend descriptors rather than choosing one forever.

Current Linux status: Core ML is unavailable and MLX is represented as a stub. This is expected.

## 9. Safetensors Feasibility

Safetensors is a good fit for Pitboss because the format separates a JSON header from tensor data and is designed to avoid arbitrary code execution during loading. Pitboss should first read metadata without loading tensor bodies, then add memory mapping and dtype validation.

Required dtype coverage should start with common diffusion asset types such as F16, BF16, F32, and relevant integer metadata.

## 10. Tokenizer Feasibility

Tokenizers are a real risk because SD1.5, SDXL, Flux-like models, Stable Audio, and video models do not all share one tokenizer story. First useful slice: implement or bind a native CLIP BPE tokenizer and test parity against known prompt-token fixtures.

Later tokenizer needs:

- OpenCLIP variants.
- T5/SentencePiece-style tokenization.
- Textual inversion token insertion.
- Audio model conditioning tokenizers.

## 11. Comfy Workflow Import Feasibility

Feasible for graph inspection and subset import. Pitboss now parses Comfy API prompt JSON and visual workflow JSON enough to preserve node ids/types, map common node concepts, build edges, and report unsupported nodes.

Pitboss should preserve source metadata for future round-trip export, but round-trip fidelity is not a first milestone.

## 12. A1111 Compatibility Feasibility

A1111 compatibility should focus on asset conventions first:

- Model folder layout.
- Prompt and negative prompt syntax.
- Generation parameter strings.
- PNG metadata import.
- LoRA textual syntax.

A1111 extension compatibility is out of scope.

## 13. LoRA Feasibility

LoRA support is plausible but should start as a manifest and graph capability, then merge-at-load for a controlled first implementation. Runtime adapter injection is more flexible but requires deeper backend-specific support.

Pitboss must account for:

- SD1.5 and SDXL tensor naming differences.
- Multiple LoRA composition.
- Text-encoder versus denoiser LoRAs.
- Adapter strength and future scheduling.

## 14. ControlNet Feasibility

ControlNet should be represented as explicit conditioning graph nodes and plugin capabilities. The first practical native preprocessors should prefer Apple APIs where appropriate, such as depth/segmentation/edge-adjacent image processing, but custom native implementations will still be needed for full ecosystem parity.

Control strength and scheduling should be graph parameters, not hidden sampler flags.

## 15. Stable Audio Feasibility

Stable Audio-style pipelines can share graph, manifest, scheduler, backend, diagnostics, and provenance contracts. They should be delayed until the image runtime proves model loading and backend dispatch. Audio adds waveform output, audio file encoding, and different conditioning requirements.

## 16. Video Feasibility

Video diffusion should be anticipated in the core through tensor/media handle abstractions and memory planning. It should not be implemented in the first prototype.

Key differences from image:

- Temporal latent layouts.
- Much larger memory pressure.
- Frame conditioning and consistency constraints.
- Output container handling.

## 17. Biggest Risks

- Tokenizer parity can quietly break generation semantics.
- Core ML conversion artifacts may not cover the model families users actually want.
- LoRA and ControlNet support differ across backends.
- Custom Comfy nodes are too broad to support directly.
- Memory planning for SDXL/video may become a product blocker.
- License and vendoring choices need careful review before reuse.

## 18. Recommended First Real Inference Milestone

Revise the proposed milestone downward before attempting full SDXL text-to-image.

Recommended milestone:

1. On Apple Silicon, load and invoke one Core ML model component from Swift.
2. Prefer VAE decode or text encoder invocation.
3. Load its model bundle through `PitbossModelManifest`.
4. Record provenance for model id, artifact path, backend, precision, and host.
5. Save a deterministic output artifact.
6. Keep Python absent from build/test/runtime.

After that works, attempt full SD1.5 or SDXL text-to-image.

## 19. Open Questions

- Should Pitboss vendor a safetensors reader in Swift, bind Rust, or use C++?
- Which tokenizer implementation gives the best parity and packaging story?
- Should first full inference target SD1.5 for smaller memory or SDXL for modern relevance?
- What model bundle format should be considered canonical on disk?
- How strict should Comfy import be about unknown widget values?
- Which Apple APIs are good enough for first ControlNet preprocessors?

## 20. Next Tickets

1. Add a native safetensors header reader.
2. Add CLIP BPE tokenizer parity fixtures.
3. Add real Apple Silicon Core ML probe.
4. Add provenance serialization for validation runs.
5. Add Comfy visual workflow fixture coverage.
6. On Mac, run a Core ML VAE decode proof.
