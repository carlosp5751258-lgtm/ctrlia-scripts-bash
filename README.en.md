# Bash scripts for Linux developers (free)

🇪🇸 [Leer en español](README.md)

Safe, commented scripts: a preview before deleting and confirmation for anything destructive.

**Free and open source (MIT).** Use it in your projects and your clients' projects. The files are commented in Spanish.

## What's included

- Clean node_modules and caches (with a preview)
- See and free busy ports
- Update all your repos with `pull --ff-only`
- Generate `.gitignore` offline
- Delete merged branches (dry-run by default)

## Installation

```bash
git clone https://github.com/carlosp5751258-lgtm/ctrlia-scripts-bash.git
cd ctrlia-scripts-bash && chmod +x *.sh
./02-limpiar-caches.sh --help
```

They all have `--help`, use `set -euo pipefail` and ask for confirmation before any destructive action.

## Want the full version?

This is the free version and it works on its own. The **Pro version** adds:

- 7 more scripts: rotating backups, Ubuntu setup with nvm and uv, new project, batch rename, resource monitor, SSL certificates and image compression

👉 [See the Pro version](https://claudecodees.gumroad.com/l/scripts-bash-devs) · pay what you want from 2 USD. Buying it also helps us keep publishing free resources.

## License

MIT: you can use, modify and share it, including in commercial projects. See [LICENSE](LICENSE).

---
Part of **[Ctrl+IA](https://ctrlia.dev/en/)**: resources for coding with AI. Made by Carlos P.
