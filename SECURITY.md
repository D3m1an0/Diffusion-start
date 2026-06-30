# Security Policy

## Supported Versions

Only the latest commit on `main` is supported. There are no maintained release branches.

## Reporting a Vulnerability

If you find a security issue (e.g. unsafe download/execution behavior in the installer scripts, credential leakage, etc.), please report it privately rather than opening a public issue:

- Open a [GitHub Security Advisory](https://github.com/D3m1an0/Diffusion-start/security/advisories/new), or
- Contact the maintainer directly through the GitHub profile.

Please include:
- A description of the issue and its impact
- Steps to reproduce
- The OS/script affected (`install-mac.command`, `install-windows.bat`/`.ps1`)

You should receive a response within a few days. Once a fix is available, it will be pushed to `main` and noted in the commit message.

## Notes on this project

The installer scripts download third-party models and tools from external sources (civitai.com, civitai.red, HuggingFace, GitHub releases). They do not collect or transmit any personal data, and API keys you provide are used only to authenticate your own downloads — they are never stored in the repository or sent anywhere besides the original download host.
