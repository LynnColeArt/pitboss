# ADR-0005: Comfy Import Scope

Status: accepted for spike

## Decision

Pitboss will initially parse selected Comfy workflow JSON and API prompt JSON into an internal graph IR. It will not execute Comfy workflows, load ComfyUI, or claim arbitrary custom-node compatibility.

## Initial Supported Concepts

- Checkpoint loader.
- CLIP text encode.
- Empty latent image.
- KSampler.
- VAE decode.
- Save image.
- LoRA loader.
- ControlNet loader.
- Apply ControlNet.
- Image loader.
- VAE encode.
- Inpaint conditioning.

## Out Of Scope

- Running ComfyUI.
- Supporting arbitrary custom nodes.
- Recreating Comfy's Python execution model.
- Perfect round-trip export.
- Hidden compatibility shims that change graph semantics.

## Diagnostics

Unsupported nodes become `PITBOSS_COMFY_UNSUPPORTED_NODE` diagnostics. The original source node id and type are preserved so users and agents can decide whether to replace the node or install a future plugin.
