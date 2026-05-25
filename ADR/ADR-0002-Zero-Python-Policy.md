# ADR-0002: Zero-Python Policy

Status: accepted for spike

## Decision

Pitboss runtime, build, and test code must not depend on Python or shell out to Python. Python projects may be read as reference material, but they are not runtime dependencies.

## Forbidden

- Python files in runtime source.
- `requirements.txt`, `pyproject.toml`, or `setup.py`.
- Runtime subprocess calls to Python or Python package tools.
- PyTorch, diffusers, transformers, or ComfyUI as runtime dependencies.
- Virtual environment setup as part of normal build/test/runtime.

## Allowed

- Documentation that discusses Python ecosystem compatibility.
- Reference notes under `docs/reference-notes` if needed later.
- Reading existing Python projects to understand formats, semantics, or migration risks.

## Enforcement

`pitboss policy-check` scans runtime/build/test surfaces. It flags Python dependency files, `.py` source outside reference notes, and source that appears to invoke forbidden runtime tools.

The checker intentionally does not fail documentation for saying the word Python, because the project must be able to document ecosystem boundaries and forbidden dependencies.
