# Scripts Bash para desarrolladores en Linux (gratis)

🇬🇧 [Read in English](README.en.md)

Scripts seguros y comentados en español: vista previa antes de borrar y confirmación en todo lo destructivo.

**Gratis y de código abierto (MIT).** Úsalo en tus proyectos y en los de tus clientes.

## Qué incluye

- Limpiar node_modules y cachés (con vista previa)
- Ver y liberar puertos ocupados
- Actualizar todos tus repos con `pull --ff-only`
- Generar `.gitignore` sin internet
- Borrar ramas ya fusionadas (dry-run por defecto)

## Instalación

```bash
git clone https://github.com/carlosp5751258-lgtm/ctrlia-scripts-bash.git
cd ctrlia-scripts-bash && chmod +x *.sh
./02-limpiar-caches.sh --help
```

Todos tienen `--help`, usan `set -euo pipefail` y piden confirmación antes de cualquier acción destructiva.

## ¿Quieres la versión completa?

Esta es la versión gratis y funciona sola. La **versión Pro** añade:

- 7 scripts más: backups con rotación, preparar Ubuntu con nvm y uv, nuevo proyecto, renombrar en lote, monitor de recursos, certificados SSL y compresión de imágenes

👉 [Ver la versión Pro](https://claudecodees.gumroad.com/l/scripts-bash-devs) · paga lo que quieras desde 2 USD. Comprarla también ayuda a que sigamos publicando recursos gratis.

## Licencia

MIT: puedes usarlo, modificarlo y compartirlo, también en proyectos comerciales. Ver [LICENSE](LICENSE).

---
Parte de **[Ctrl+IA](https://ctrlia.dev/)**: recursos en español para programar con IA. Hecho por Carlos P.
