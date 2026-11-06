function yadmalt --description="generate templates with pass variables"
    # Herramientas en ~/.local/bin (crypta) y clave age: los fijamos aqui
    # para funcionar tambien en shells NO interactivos.
    if test -d $HOME/.local/bin
        if not contains -- $HOME/.local/bin $PATH
            set -gx PATH $HOME/.local/bin $PATH
        end
    end
    if not set -q SOPS_AGE_KEY_FILE
        set -gx SOPS_AGE_KEY_FILE $HOME/.secrets/sops/age/key.txt
    end

    # set variables
    set -l STORE $HOME/.secrets/secrets.yml
    if not test -f $STORE
        echo "Error: No se encontró el almacén de contraseñas en $STORE" >&2
        return 1
    end
    # Un solo punto de verdad: crypta exporta el store como KEY=VALUE
    # (crypta envuelve SOPS; no invocamos sops/yq a mano).
    crypta export -f env | while read -l line
        set -l parts (string split -m1 '=' -- $line)
        if test (count $parts) -eq 2 -a -n "$parts[1]"
            echo "✅ Loading $parts[1]"
            set -gx (string upper $parts[1]) $parts[2]
        end
    end
    echo "🚀 Secretos cargados"
    # configure templates
    echo "📝 Templates configurados"
    yadm alt
    # unset variables
    set -l raw_keys (crypta export -f env | string replace -r '=.*$' '')
    if test -n "$raw_keys"
        set -e (string upper $raw_keys)
    end
    echo "🧹 Secreto descargados"
end
