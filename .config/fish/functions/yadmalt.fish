function yadmalt --description="generate templates with pass variables"
    # Herramientas en ~/.local/bin (sops, yq) y clave age: los fijamos aqui
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
    # Expresion agnostica de la version de yq; mayusculas con string upper.
    sops -d $STORE | yq -r 'to_entries | .[] | select(.key != "sops") | (.key + " " + (.value | tostring))' | while read -l key value
        echo "✅ Loading $key"
        set -gx (string upper $key) $value
    end
    echo "🚀 Secretos cargados"
    # configure templates
    echo "📝 Templates configurados"
    yadm alt
    # unset variables
    set -e (sops -d $STORE | yq -r 'keys[] | select(. != "sops")' | string upper)
    echo "🧹 Secreto descargados"
end
