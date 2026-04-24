# OpenClaw — Instalador comunitario

Repositorio **independiente**: solo contiene el instalador y la landing. Cada proyecto en GitHub es su propio remoto; publicar aquí no afecta a otros repositorios de tu cuenta.

## Landing con GitHub Pages (gratis)

1. Sube este código a un repositorio **público** (por ejemplo `openclaw-easy-install` bajo tu usuario u organización).
2. En GitHub: **Settings** → **Pages** → **Build and deployment** → **Source**: *Deploy from a branch*.
3. **Branch**: `main` → carpeta **/** (root) → **Save**.

En unos segundos la web estará en:

`https://TU_USUARIO.github.io/openclaw-easy-install/`

(El nombre de la ruta final coincide con el **nombre del repositorio**.)

La landing detecta sola el dueño y el repo cuando se abre en `*.github.io` y actualiza los comandos `curl`/`irm` y los enlaces del pie. Si abres el `index.html` en local o con otro dominio, se usa el valor por defecto definido en `REPO_DEFAULT` al inicio del script en `index.html` (cámbialo si hace falta).

## Uso

Instrucciones y comandos de instalación en la propia web publicada o en `index.html`.
