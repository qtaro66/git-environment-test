# Windows Development Environment Kit v2

This kit automates and verifies a VS Code-centered Windows development environment.

## Files

- `setup-dev.ps1` — installs missing tools and applies selected defaults.
- `verify-dev.ps1` — verifies the environment without changing normal configuration.
- `vscode-extensions.txt` — required VS Code extension IDs.

## Recommended workflow

On a fresh Windows machine:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup-dev.ps1
```

Restart Windows if Docker Desktop or WSL asks for it, then run:

```powershell
.\verify-dev.ps1
```

A fully working environment should end with:

```text
Environment Status: READY
```

## Notes

- GitHub and Docker sign-in remain interactive.
- Passwords and tokens are not stored in these scripts.
- Python packages should normally go inside project-local `.venv` environments.
- ESLint/Prettier npm packages should normally be project-local rather than global.
- Reference environment validated in August 2026 used VS Code, Git, Python 3.14, Node.js LTS, WSL2, and Docker Desktop.
