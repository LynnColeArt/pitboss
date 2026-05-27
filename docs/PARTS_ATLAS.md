# Pitboss Parts Atlas

Pitboss is in feasibility study mode. This atlas maps the scattered pieces of modern diffusion runtimes so we can borrow ideas, contracts, tests, and methodology without importing a Python runtime.

The working thesis is that most of the hard pieces already exist somewhere. Pitboss should not copy a whole ecosystem. It should identify the small reusable organs, give them native contracts, and graft them together cleanly.

## How To Read This

- **Borrow as code** means a candidate for direct dependency, vendoring, or small adapted reuse after license review.
- **Borrow as method** means study the design, test behavior, file format handling, or pipeline shape.
- **Reference only** means useful for semantics, but not acceptable in the shipped runtime.
- **Sideways move** means a non-linear shortcut or reframing that may reduce implementation cost.

## Atlas Table

| Subsystem | Best source found | Runtime | Borrow as | Avoid | Pitboss contract implication |
| --- | --- | --- | --- | --- | --- |
| Native Apple diffusion pipeline | Apple `ml-stable-diffusion` | Swift, Core ML, Python conversion tooling | Method, maybe code after license review | Treating conversion tooling as runtime dependency | Core ML backend must describe package layout, compute units, scheduler loop, and provenance |
| Modern Swift diffusion packaging | DiffusionKit | Swift, Core ML, MLX-adjacent ideas, repo-specific tooling | Method, possible dependency candidate after deeper review | Assuming supported model families match Pitboss goals | Backend abstraction must support both Core ML-style compiled artifacts and MLX-style tensor execution |
| Flexible Apple tensor backend | MLX Swift and MLX examples | Swift/C++ native Apple stack | Method, possible backend dependency | Treating MLX as a drop-in Core ML replacement | Backend registry should distinguish execution style, memory planning, dtype support, and model artifact requirements |
| Safetensors model/adapters | Hugging Face safetensors | Rust reference, many ecosystem users | Method, maybe native reader spec | Loading tensor bodies before validating headers | Asset registry needs metadata-only inspection, dtype validation, offset ranges, and optional memory mapping |
| Tokenization | Hugging Face tokenizers, OpenCLIP/CLIP references | Rust/Python ecosystem, some native ports | Method, tests, maybe native binding | Quiet tokenizer mismatch | Tokenizer requirements belong in model manifests; first parity target should be CLIP BPE |
| Workflow graph semantics | ComfyUI workflow/API JSON | Python runtime, JSON graph format | Method and fixtures | Claiming arbitrary custom-node support | Compatibility importer maps known nodes to Pitboss IR and preserves source metadata |
| Prompt/metadata conventions | AUTOMATIC1111 webui | Python runtime, de facto asset conventions | Method | Extension compatibility | A1111 importer should parse prompt strings, PNG metadata, model folder layout, and LoRA syntax |
| Denoising loop shape | Latent Diffusion, Stable Diffusion repos, diffusers | Papers plus Python implementations | Method | Porting diffusers wholesale | Scheduler interface must be explicit, deterministic, and backend-independent |
| Samplers/schedulers | DDIM, DPM-Solver, UniPC, consistency-model papers | Papers plus Python implementations | Method, tests | Binding sampler semantics to one pipeline | Scheduler plugins should declare step type, prediction type, sigma/timestep rules, and reproducibility parameters |
| VAE encode/decode | Latent Diffusion / Stable Diffusion implementations | Paper plus PyTorch code, Core ML artifacts | Method, first backend proof | Making full text-to-image the first execution milestone | First Mac proof can run VAE decode through Core ML from a manifest |
| LoRA adapters | LoRA paper, kohya-style LoRA conventions, A1111/Comfy behavior | Papers and Python ecosystem conventions | Method and compatibility tests | One hard-coded tensor naming scheme | Adapter contract needs target module, rank/alpha metadata, text-encoder vs denoiser scope, composition order |
| ControlNet | ControlNet paper and implementations | Paper plus Python implementations | Method | Treating preprocessors as hidden side effects | Control is explicit conditioning with strength, schedule, preprocessor metadata, and plugin capability |
| T2I-Adapter / lightweight control | T2I-Adapter paper | Paper and implementations | Method | Folding all control into ControlNet only | Conditioning capability taxonomy should allow multiple control families |
| IP-Adapter / image prompting | IP-Adapter paper | Paper and implementations | Method | Treating image conditioning as img2img only | Graph IR needs conditioning inputs that are neither text nor control maps |
| Inpainting | SD inpainting pipelines, Comfy/A1111 nodes | Python implementations and model conventions | Method | Burying mask semantics inside sampler flags | Graph nodes must represent mask, masked latent, conditioning, and VAE encode/decode roles |
| Video diffusion | Stable Video Diffusion, AnimateDiff | Papers and Python implementations | Method | Image-only tensor assumptions | Core tensor/media handles need temporal dimensions and memory planning hooks |
| Audio diffusion | Stable Audio Open | Python tooling, paper/model ideas | Method | Audio-specific hacks in image pipeline | Media handles should support waveform/sample-rate/output-container metadata |
| Provenance | A1111 PNG metadata, Comfy workflow embedding, generation-info conventions | Ecosystem conventions | Method | Human-only logs | Provenance should be structured, diffable, machine-readable, and tied to output artifacts |
| Diagnostics | Compiler-style diagnostics, Comfy missing-node behavior, package managers | Cross-domain method | Method | Fatal errors without suggested fixes | Diagnostics need stable codes, node/plugin references, severity, and suggested fixes |

## Paper Leads

These papers are not just citations. They are places to mine abstractions when codebases are too tangled.

| Paper | Why it matters to Pitboss | Pitboss extraction target |
| --- | --- | --- |
| Latent Diffusion Models, arXiv:2112.10752 | Establishes latent-space generation, conditioning, and VAE separation used by Stable Diffusion-family systems | Manifest module roles: text encoder, denoiser, VAE encoder/decoder |
| DDIM, arXiv:2010.02502 | Shows deterministic/non-Markovian sampling shape that became a common scheduler family | Scheduler contract with deterministic seed/timestep semantics |
| DPM-Solver, arXiv:2206.00927 | Fast ODE solver framing for diffusion sampling | Scheduler plugins should expose solver order and prediction assumptions |
| UniPC, arXiv:2302.04867 | Predictor-corrector sampler design used in modern pipelines | Scheduler interface should not assume one-step Euler-style updates only |
| ControlNet, arXiv:2302.05543 | Clean separation of frozen base model and trainable conditional branch | ControlNet as conditioning plugin, not sampler magic |
| LoRA, arXiv:2106.09685 | Adapter method for low-rank updates | Adapter manifests need rank, alpha, target module, and composition semantics |
| T2I-Adapter, arXiv:2302.08453 | Alternative control path with lightweight adapters | Control capability taxonomy should be broader than ControlNet |
| IP-Adapter, arXiv:2308.06721 | Image prompt adapter that coexists with text prompts | Graph conditioning should allow image prompt embeddings |
| Stable Video Diffusion, arXiv:2311.15127 | Shows temporal latent/video additions beyond still-image diffusion | Media handles and memory planner must anticipate temporal axes |
| AnimateDiff, arXiv:2307.04725 | Motion module grafted onto personalized image diffusion models | Pitboss should keep room for adapter-like temporal modules |
| Consistency Models, arXiv:2303.01469 | Different sampling regime that reduces step count | Scheduler/backend contracts should not assume all generation is classic many-step denoising |

## Sideways Problem-Solving Notes

These are deliberately non-linear angles. They may save Pitboss from doing the obvious expensive thing first.

### Use VAE Decode As The First Inference Proof

Full text-to-image requires tokenizer parity, text encoder, denoiser, scheduler, VAE, seeds, precision, and image output all at once. VAE decode isolates a small but real backend proof:

- Load a manifest.
- Load a Core ML model artifact.
- Feed known latent input.
- Save an image.
- Record provenance.

This proves native model invocation without needing the whole diffusion stack.

### Borrow Tests Before Borrowing Code

For risky subsystems, tests may be more valuable than implementations.

Examples:

- Tokenizer parity fixtures.
- Safetensors header parsing fixtures.
- LoRA tensor-name mapping fixtures.
- Scheduler timestep/sigma sequences.
- Comfy workflow import fixtures.

If Pitboss owns native code but borrows battle-tested expected behavior, it gets ecosystem alignment without runtime inheritance.

### Treat Python Projects As Specimens, Not Ancestors

ComfyUI, A1111, diffusers, and Stable Audio tools are rich specimens. Pitboss should dissect them for:

- File conventions.
- Error cases.
- Parameter naming.
- Edge-case behavior.
- User expectations.

Pitboss should not inherit their execution model.

### Put Weirdness Behind Capabilities

Diffusion ecosystems grow by accretion: LoRA, ControlNet, IP-Adapter, T2I-Adapter, AnimateDiff, inpainting, regional prompting, tiled VAE, latent upscalers. Pitboss should expect weirdness, but require it to enter through declared capabilities and diagnostics.

### Generalize Media Handles Early

Do not build an image-only core and then bolt on audio/video. The first executable may be image-only, but core graph values should leave room for:

- Image tensors.
- Latent tensors.
- Temporal latent tensors.
- Waveforms.
- Masks.
- Conditioning embeddings.
- Control maps.

### Prefer Explicit Failure Over Magic Compatibility

Unsupported nodes should become useful diagnostics. A user should be able to paste in a Comfy graph and learn:

- Which parts mapped cleanly.
- Which capabilities are missing.
- Which nodes are impossible without a plugin.
- Which assets need manifests.

That is already product value, even before generation works.

## Near-Term Research Tickets

1. Build a Mac-focused Core ML artifact inventory: which SD1.5/SDXL/VAE/text-encoder artifacts are available, what format they ship in, and how Swift loads them.
2. Deep-read Apple `ml-stable-diffusion` and DiffusionKit for backend seams, license posture, tokenizer handling, LoRA status, and model-family coverage.
3. Create tokenizer parity fixtures for CLIP BPE.
4. Create safetensors header-reader design notes and fixture cases.
5. Map LoRA tensor naming across SD1.5 and SDXL.
6. Map ControlNet and T2I/IP adapter graph shapes into Pitboss capabilities.
7. Add a native safetensors header reader with metadata-only inspection.

## Source Links

- Apple ml-stable-diffusion: https://github.com/apple/ml-stable-diffusion
- DiffusionKit: https://github.com/argmaxinc/DiffusionKit
- MLX Swift: https://github.com/ml-explore/mlx-swift
- MLX examples: https://github.com/ml-explore/mlx-examples
- Core ML compute units: https://developer.apple.com/documentation/coreml/mlcomputeunits
- Safetensors: https://github.com/huggingface/safetensors
- Tokenizers: https://github.com/huggingface/tokenizers
- ComfyUI: https://github.com/comfyanonymous/ComfyUI
- Comfy docs: https://docs.comfy.org/
- AUTOMATIC1111 webui: https://github.com/AUTOMATIC1111/stable-diffusion-webui
- Latent Diffusion Models: https://arxiv.org/abs/2112.10752
- DDIM: https://arxiv.org/abs/2010.02502
- DPM-Solver: https://arxiv.org/abs/2206.00927
- UniPC: https://arxiv.org/abs/2302.04867
- ControlNet: https://arxiv.org/abs/2302.05543
- LoRA: https://arxiv.org/abs/2106.09685
- T2I-Adapter: https://arxiv.org/abs/2302.08453
- IP-Adapter: https://arxiv.org/abs/2308.06721
- Stable Video Diffusion: https://arxiv.org/abs/2311.15127
- AnimateDiff: https://arxiv.org/abs/2307.04725
- Consistency Models: https://arxiv.org/abs/2303.01469
