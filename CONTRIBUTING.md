# Contributing

Thanks for considering a contribution to Diffusion-Start.

## Reporting bugs

Open an issue with:
- OS and script used (`install-mac.command`, `install-windows.bat`/`.ps1`)
- What you expected vs. what happened
- Relevant terminal output

## Suggesting models or custom nodes

Open an issue describing the model/node, why it's useful, and a working download link (civitai/HuggingFace/GitHub). Keep in mind the installer favors models that don't require gated access where possible, since they need to work unattended.

## Pull requests

- Keep changes focused — one fix or feature per PR.
- Test the installer script you changed end-to-end before submitting (`install-mac.command` on macOS, `install-windows.ps1` on Windows).
- Don't commit API keys, tokens, or other credentials. The scripts are designed to prompt for these at runtime, not embed them.
- Match the existing style of the script you're editing (the `download()` helper pattern, progress output, etc.).

## Scope

This repo bundles installer scripts and `custom_nodes/` for ComfyUI. Large model binaries are downloaded at install time, not committed to the repo — please don't add large files directly to a PR.
