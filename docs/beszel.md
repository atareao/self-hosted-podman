# beszel — monitor de sistemas y agentes

## Qué es
- Aplicación: monitor de sistemas y agentes
- Imagen: `docker.io/henrygd/beszel:latest` (hub) y `docker.io/henrygd/beszel-agent:latest` (agente)
- Contenedores: 2 (beszel + beszel-agent)
- Red(es): `beszel.network` (hub + agente), `proxy.network` (hub, vía Traefik)
- Dominio: `beszel.${FQDN}` (publicado en el puerto `8090`)
- Puerto interno del hub: 8090
- Puerto del agente: `45876/tcp` (sólo dentro de `beszel.network`)

## Ficheros
- Quadlet(s):
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel.container
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel-agent.container
- Volumen(es):
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel-data.volume
  - /data/self-hosted-podman/.config/containers/available/beszel/beszel-agent-data.volume
- Config no secreta: (ninguna)
- Secretos:
  - `beszel_key` (clave pública SSH del hub, la usa el agente)

## Cómo funciona
- El hub (`beszel`) guarda su estado en el volumen `beszel-data` y se expone vía Traefik en
  `https://beszel.${FQDN}` (el contenedor escucha en `8090`).
- No hay OAuth ni SSO: el acceso es con usuario/contraseña. El primer usuario se crea en el
  primer acceso a la UI (el hub arranca sin usuarios). No se define `DISABLE_PASSWORD_AUTH`.
- El agente (`beszel-agent`) escucha en `45876/tcp` dentro de `beszel.network` y el hub lo consulta
  por **SSH** (modo clásico), usando el usuario `root` del contenedor del agente (el agente ya
  corre como root). En este modo sólo se necesita la clave pública del hub.
- El agente puede arrancar solo (`After=network-online.target beszel.service`, sin `Requires=`):
  es el hub quien se conecta al agente, no al contrario.
- El agente monta `%t/podman/podman.sock` en modo lectura para leer métricas de Podman.
- No se define Healthcheck en los quadlets.

## Aprovisionamiento del agente (modo SSH)
El hub genera su par de claves en `beszel_data/id_ed25519` la primera vez que arranca. La clave
**pública** se extrae y se guarda como secreto `beszel_key`, que el agente recibe como `KEY`:

```bash
mp=$(podman volume inspect beszel-data -f '{{.Mountpoint}}')
ssh-keygen -y -f "$mp/id_ed25519" | podman secret create beszel_key -
```

Si el par aún no existe (hub nunca arrancado), arranca primero el hub, espera a que genere
`id_ed25519` y repite. Después, en la UI: *Add system* → host `beszel-agent`, puerto `45876`,
usuario `root` (y la clave se selecciona automáticamente al estar provisionada en el hub).

## Variables / configuración
| Var | Dónde | Valor | Descripción |
|---|---|---|---|
| LISTEN | Environment= (agente) | `45876` | Puerto TCP de escucha del agente (modo SSH) |

## Cómo habilitar / desplegar
1. Secretos:
   - Arrancar el hub, obtener la clave pública desde `beszel-data` y crear el secreto:
     - `mp=$(podman volume inspect beszel-data -f '{{.Mountpoint}}')`
     - `ssh-keygen -y -f "$mp/id_ed25519" | podman secret create beszel_key -`
2. `cd .config/containers/available/beszel && qctl install`
3. `systemctl --user daemon-reload`
4. `systemctl --user restart beszel beszel-agent`
5. Primer acceso a `https://beszel.${FQDN}` → crear el usuario administrador.

## Follow-ups
- El token universal (modo WebSocket) y el alta del sistema se hacen manualmente en la UI del hub; el modo SSH sólo requiere `beszel_key`.
- Valorar `DISABLE_SSH=true` + `HUB_URL`/`TOKEN` si se prefiere WebSocket (exige token de la UI).
