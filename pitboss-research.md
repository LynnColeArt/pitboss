MISSION SPEC: Native Zero-Python Generative Media Runtime Recon + Prototype

Working title:
Pitboss
Mission:
Determine whether we can build a zero-Python, Mac-first, plugin-based generative media runtime that can eventually replace or interoperate with key Stable Diffusion ecosystem workflows: ComfyUI-style graphs, Automatic1111-style assets/prompts, ControlNet, LoRA, video diffusion, and Stable Audio-style pipelines.

Primary hypothesis:
Most of the difficult parts already exist somewhere, but not in one coherent place. The job is to identify reusable native components, define clean runtime contracts, and build a tiny proof-of-architecture.

Core product thesis:
Mac users need a serious local generative media system that does not require Python, PyTorch, CUDA assumptions, virtual environments, shell rituals, or fragile notebook-era infrastructure. The system should be native-first, deterministic, plugin-capable, agent-composeable, and built around explicit workflow/model/backend contracts.

Hard constraints:
1. Zero Python runtime dependency.
2. No Python in the shipped app/runtime.
3. No shelling out to Python.
4. No pip, venv, torch, diffusers, transformers, or ComfyUI runtime dependency.
5. Existing Python projects may be read as references only.
6. Do not build a PyTorch clone.
7. Do not implement training or fine-tuning in this phase.
8. Do not promise arbitrary ComfyUI custom-node compatibility.
9. Do not promise Automatic1111 extension compatibility.
10. Prefer Swift for Apple-native runtime pieces.
11. Prefer explicit model manifests and graph validation over dynamic magical loading.
12. Every unsupported feature must fail clearly with a diagnostic.
13. Every generated artifact must eventually be reproducible from recorded provenance.

Strategic target:
A native runtime that can execute local generative media workflows through plugins.

The core owns:
- graph IR
- workflow validation
- model/package manifests
- asset registry
- plugin/capability registry
- backend dispatch
- diagnostics
- provenance
- deterministic seed handling
- tensor/media handle abstractions
- memory planning interface
- scheduler interfaces
- permission model

Plugins own:
- SDXL / SD1.5 image diffusion
- ControlNet
- LoRA / adapter behavior
- textual inversion
- inpainting
- img2img
- video diffusion
- Stable Audio-style audio generation
- ComfyUI workflow import/export
- A1111 prompt/metadata/model-folder compatibility
- native preprocessors
- hardware backends

Target user:
A serious local generative media user on Apple Silicon who wants ComfyUI-class workflow power without Python setup. Secondary targets are future AMD/Linux/ARM users through portable runtime contracts.

Initial platform priority:
1. Apple Silicon macOS
2. Linux AMD/ROCm later
3. Linux ARM later
4. Other backends later

Important distinction:
This is not “port diffusers to Swift.”
This is a native generative media runtime that can speak selected ecosystem formats and semantics.

Research objectives:
Codex must investigate the following existing projects/specs and produce a written assessment of what can be reused, studied, avoided, or replaced.

Research target 1: Apple ml-stable-diffusion
Questions:
- What does the Swift package provide?
- How are Core ML model files loaded?
- How does the denoising pipeline work?
- What parts assume Python conversion?
- What code can be studied or reused under license?
- What architecture lessons should be imported into Forge?
- What parts are too narrow or old for our purpose?

Research target 2: DiffusionKit
Questions:
- How does the Swift package structure Core ML and MLX inference?
- What Python tooling remains in the repo?
- What models/families are currently supported?
- Is it a viable dependency, fork candidate, or reference only?
- What open issues reveal missing features or fragile areas?
- How does it handle memory release, LoRA, Flux, SD3, img2img, etc.?

Research target 3: MLX Swift / MLX examples
Questions:
- What is currently practical in Swift with MLX?
- Can MLX act as an inference backend for diffusion components?
- What parts are production-ready versus research-quality?
- How would an MLX backend differ from a Core ML backend?
- Can Core ML and MLX coexist under one backend interface?

Research target 4: Core ML / Neural Engine / compute units
Questions:
- How do we select CPU/GPU/Neural Engine/Core ML compute units from Swift?
- How do we report whether a given model node can use Neural Engine?
- What operator/model constraints cause Core ML to fall back to GPU/CPU?
- What diagnostics can we expose to users?

Research target 5: Safetensors
Questions:
- Can we implement or use a native Swift safetensors reader?
- What is the exact file structure?
- Can we read metadata without loading tensor bodies?
- Can we memory-map tensors?
- What dtype support is required?
- How should we represent tensor metadata in Forge?
- What security guarantees do we preserve?

Research target 6: tokenizers
Questions:
- What native tokenizer libraries exist for Swift/Rust/C/C++?
- What do we need for CLIP BPE, OpenCLIP, T5/SentencePiece, and textual inversion?
- Which tokenizers are required for SD1.5, SDXL, Flux-like models, Stable Audio, and video models?
- Can we implement a minimal CLIP tokenizer natively for the first prototype?
- What exact parity tests are needed?

Research target 7: ComfyUI workflow JSON
Questions:
- What is the schema?
- What fields are stable?
- What is the difference between workflow JSON, API JSON, and subgraph/blueprint formats?
- Can we parse a workflow and produce an internal graph without running ComfyUI?
- What common nodes should be mapped first?
- How should unsupported nodes be reported?
- What metadata should we preserve for round-trip export later?

Research target 8: Automatic1111 compatibility
Questions:
- What asset conventions matter most?
- What prompt syntax conventions matter most?
- What generation parameters must be parsed?
- What metadata is embedded in generated PNGs?
- What model-folder layout should we import?
- What extension behavior is out of scope?

Research target 9: ControlNet
Questions:
- What is the minimal graph structure for ControlNet inference?
- What preprocessors must exist for useful workflows?
- Which preprocessors can be native Apple APIs?
- Which require custom/native implementations?
- How should control strength and control scheduling be represented?
- How should ControlNet be expressed as a plugin capability?

Research target 10: LoRA/adapters
Questions:
- What are the tensor naming conventions for SD1.5 and SDXL LoRAs?
- Should first implementation be merge-at-load or runtime adapter injection?
- How do multiple LoRAs compose?
- How should LoRA strength be scheduled or scoped?
- How do text-encoder LoRAs differ from denoiser LoRAs?
- What is the simplest zero-Python path to useful LoRA support?

Research target 11: Stable Audio / audio diffusion
Questions:
- What model formats and components are used?
- What native backend would be most plausible?
- What tokenizer/conditioning is required?
- What output pipeline is needed for waveform/audio files?
- What can share the core graph/scheduler/backend infrastructure?
- What should be delayed until after image runtime is proven?

Research target 12: video diffusion
Questions:
- Which model families are plausible targets later?
- What changes relative to image diffusion?
- What temporal latent layout concepts must the core anticipate?
- What memory planner requirements appear?
- What should be explicitly out of scope for the first prototype?

Initial development objective:
Build a tiny zero-Python prototype that proves the architecture, not generation quality.

Repository name:
forge-runtime-spike

Required repo structure:
- Package.swift
- README.md
- REPORT.md
- ADR/
- Sources/
  - ForgeCore/
    - Graph/
    - Assets/
    - Plugins/
    - Backends/
    - Diagnostics/
    - Provenance/
    - Workflows/
  - ForgeApple/
    - CoreML/
    - MLX/
    - DeviceProbe/
  - ForgeCompat/
    - Comfy/
    - A1111/
  - ForgeCLI/
- Tests/
  - ForgeCoreTests/
  - ForgeCompatTests/
- Fixtures/
  - comfy/
  - manifests/
  - assets/

Required first deliverables:
1. REPORT.md
2. README.md
3. ADR-0001-Architecture.md
4. ADR-0002-Zero-Python-Policy.md
5. ADR-0003-Plugin-Capability-System.md
6. ADR-0004-Model-Bundle-Manifest.md
7. ADR-0005-Comfy-Import-Scope.md
8. Compiling Swift package
9. CLI command: forge doctor
10. CLI command: forge validate <workflow.json>
11. CLI command: forge inspect plugins
12. Minimal Comfy workflow parser
13. Minimal internal graph IR
14. Minimal plugin registry
15. Minimal backend registry
16. Minimal model manifest schema
17. Clear unsupported-node diagnostics

Prototype does not need to generate images yet.
Prototype must compile and validate graphs.

Core data model requirements:

Define Capability:
- namespace
- name
- version requirement or version range
- optional metadata

Example:
capability: model.family.sdxl
capability: pipeline.text2image
capability: adapter.lora
capability: conditioning.controlnet.depth
capability: backend.coreml
capability: backend.mlx
capability: workflow.import.comfy

Define Plugin:
- id
- display name
- version
- kind: feature, backend, compatibility, model-family, preprocessor
- capabilities provided
- permissions requested
- nodes provided
- asset types supported
- diagnostics hooks

Define Graph:
- nodes
- edges
- inputs
- outputs
- required capabilities
- asset references
- deterministic metadata
- workflow provenance

Define GraphNode:
- id
- type
- display name
- inputs
- outputs
- parameters
- required capabilities
- plugin provider if known
- source format metadata, e.g. Comfy node id/type

Define Asset:
- id
- type
- path
- hash/checksum optional
- format
- metadata
- provenance
- required capabilities

Define Backend:
- id
- platform
- device type
- capabilities
- memory estimate support
- execution support status
- diagnostic status

Define Diagnostic:
- severity: info, warning, error
- code
- message
- node id optional
- plugin id optional
- suggested fix optional

Define Provenance:
- runtime version
- plugin versions
- model ids/hashes
- workflow source
- seed
- scheduler
- backend
- precision
- generation parameters
- adapter strengths
- control inputs

Initial CLI behavior:

forge doctor:
- prints host platform
- prints OS version
- prints architecture
- detects Apple Silicon if available
- reports Core ML availability
- reports MLX availability if implemented or stubbed
- reports registered plugins
- reports zero-Python policy status
- must not call Python

forge inspect plugins:
- lists plugin ids
- lists capabilities
- lists provided node types
- lists backend providers
- outputs human-readable text
- optional JSON flag if easy

forge validate <workflow.json>:
- parses a Comfy workflow JSON if possible
- creates internal graph representation
- maps known node types to native/internal node types
- reports unsupported nodes clearly
- reports missing capabilities
- reports whether graph is executable in current prototype
- exits nonzero on validation errors
- must not call ComfyUI or Python

Initial known node mapping target:
Support parsing/mapping stubs for common Comfy concepts:
- checkpoint loader
- CLIP text encode
- empty latent image
- KSampler
- VAE decode
- save image
- LoRA loader
- ControlNet loader
- apply ControlNet
- image loader
- VAE encode
- inpaint conditioning node if present

These do not need to execute yet.
They need to map into internal graph nodes with required capabilities.

Model bundle manifest draft:
Create a JSON schema-like Swift Codable type for Forge model bundles.

Required manifest fields:
- manifestVersion
- bundleId
- displayName
- modelFamily
- pipelineTypes
- assets
- modules
- tokenizer requirements
- scheduler defaults
- adapter support
- control support
- backend artifacts
- minimum runtime version
- provenance

Example model families:
- sd15
- sdxl
- flux
- stable-audio
- video-temporal

Example backend artifact kinds:
- coreml
- mlx
- safetensors
- gguf
- onnx
- native

Zero-Python enforcement:
Add a repository policy:
- No .py files unless explicitly placed under docs/reference-notes and marked non-executable.
- No requirements.txt.
- No pyproject.toml.
- No setup.py.
- No venv instructions.
- No pip instructions.
- No torch/diffusers runtime dependency.
- No subprocess invocation of python/python3.
- Build/test must pass without Python installed.

Codex should search the repo for violations and report them.

Architecture decision records:
Codex must write ADRs in plain Markdown.

ADR-0001 should answer:
- Why a native runtime?
- Why plugin architecture?
- Why Mac-first?
- Why graph IR?
- Why not direct diffusers port?

ADR-0002 should answer:
- What does zero-Python mean?
- What is allowed as reference material?
- What is forbidden in runtime/build/test?
- How will violations be detected?

ADR-0003 should answer:
- What is a plugin?
- What is a capability?
- What is a backend?
- How are unsupported features reported?

ADR-0004 should answer:
- What is a model bundle?
- Why use strict manifests?
- How do safetensors/Core ML/MLX artifacts fit?

ADR-0005 should answer:
- What subset of ComfyUI workflow JSON is targeted first?
- What is explicitly out of scope?
- How are unsupported nodes represented?

Research report requirements:
REPORT.md must include:
1. Executive summary
2. Existing projects surveyed
3. Reusable parts
4. Non-reusable parts
5. Licenses noticed
6. Native-code opportunities
7. Python dependencies to avoid
8. Core ML/MLX feasibility
9. Safetensors feasibility
10. Tokenizer feasibility
11. Comfy workflow import feasibility
12. A1111 compatibility feasibility
13. LoRA feasibility
14. ControlNet feasibility
15. Stable Audio feasibility
16. Video feasibility
17. Biggest risks
18. Recommended first real inference milestone
19. Open questions
20. Next tickets

First real inference milestone recommendation:
Codex should evaluate this proposed milestone and either confirm or revise it:

Milestone 1:
Run SDXL or SD1.5 text-to-image on Apple Silicon without Python, using a preexisting Core ML model package if possible.

Minimum:
- Native Swift CLI or minimal app invokes model
- Uses Core ML backend
- Uses native tokenizer or precomputed embeddings only if tokenizer is not ready
- Executes denoising loop or calls existing Swift pipeline
- Saves image
- Records provenance
- No Python

Alternative acceptable milestone:
If full text-to-image is too large, run VAE decode or text encoder invocation through Core ML first as a smaller backend proof.

Development tickets:
Ticket 1: Initialize Swift package
- Create repo structure
- Add ForgeCore, ForgeApple, ForgeCompat, ForgeCLI targets
- Add unit test targets
- Ensure swift test passes

Ticket 2: Define core types
- Capability
- PluginDescriptor
- NodeDescriptor
- Graph
- GraphNode
- GraphEdge
- AssetRef
- BackendDescriptor
- Diagnostic
- ProvenanceRecord

Ticket 3: Plugin registry
- Register built-in stub plugins
- Query capabilities
- Return diagnostics for missing capabilities
- Unit tests

Ticket 4: Backend registry and doctor
- Detect platform
- Detect architecture
- Stub Core ML backend availability
- Stub MLX backend availability
- Implement forge doctor

Ticket 5: Comfy workflow parser
- Load JSON
- Preserve original node ids/types
- Parse enough structure to list nodes and edges
- Map known node names/types to internal nodes
- Unsupported nodes produce diagnostics
- Unit tests with fixture workflow

Ticket 6: Manifest type
- Create ForgeModelManifest Codable type
- Add fixture manifest
- Validate required fields
- Unit tests

Ticket 7: CLI validate
- Implement forge validate <path>
- Output diagnostics
- Nonzero exit on errors
- Optional --json output if easy

Ticket 8: Zero-Python policy checker
- Implement simple repository scan
- Fail or warn on .py, requirements.txt, pyproject.toml, setup.py, subprocess python calls
- Add to forge doctor or separate forge policy-check

Ticket 9: Research report
- Fill REPORT.md with findings and links
- Include source links and notes
- Identify recommended next implementation branch

Definition of done for this mission:
- Repo compiles on macOS.
- swift test passes.
- forge doctor runs.
- forge inspect plugins runs.
- forge validate parses at least one Comfy workflow fixture.
- Unsupported nodes are reported cleanly.
- Model manifest fixture validates.
- REPORT.md is substantive and specific.
- ADRs exist and reflect actual code.
- No Python is used.
- Next milestone is clearly recommended.

Failure conditions:
- Any Python runtime dependency.
- Any hidden shell-out to Python.
- Prototype depends on ComfyUI, diffusers, torch, or transformers.
- Report is vague or does not distinguish reusable code from reference-only code.
- Graph IR is inseparable from ComfyUI’s exact format.
- Plugin system allows arbitrary filesystem/shell access by default.
- CLI fails without explaining missing capabilities.
- Architecture assumes image diffusion only and cannot plausibly extend to audio/video.

Design principles:
1. The core should be boring, explicit, and small.
2. Plugins should provide weirdness without corrupting the core.
3. Unsupported ecosystem behavior must be visible, not magical.
4. Python may be studied but not invited inside.
5. Model and workflow contracts matter more than UI at this phase.
6. Agent-readability is a first-class goal.
7. Diagnostics are product features.
8. Provenance is mandatory.
9. Backends are replaceable.
10. The first prototype should be ugly and correct, not beautiful and haunted.

Agent-composition requirements:
The runtime should eventually be friendly to Codex-like agents.
Therefore:
- Workflow files must be structured, text-editable, and diffable.
- Plugin capabilities must be inspectable.
- Validation errors must be machine-readable.
- Diagnostics should include suggested fixes where possible.
- Every node type should eventually expose semantic metadata:
  - what it does
  - good use cases
  - bad use cases
  - inputs
  - outputs
  - common failure modes
  - compatible model families

Do not build the agent composer yet.
But do not design the runtime in a way that makes agent composition hard.

Suggested README opening:
Forge Runtime is an experimental zero-Python native generative media runtime. The first target is Apple Silicon macOS. The long-term goal is to support plugin-based image, video, and audio generation workflows with explicit model manifests, graph validation, native backend dispatch, and reproducible provenance.

Suggested first issue title:
Spike: Zero-Python Native Runtime Spine for Mac-First Generative Workflows

Suggested first issue body:
Build the initial Forge Runtime spike according to MISSION_SPEC.md. Focus on core contracts, CLI diagnostics, Comfy workflow parsing, plugin/capability registry, and research report. Do not implement full image generation yet unless the core contracts are already passing tests.

End of mission.
