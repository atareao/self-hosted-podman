function yadmalt --description="generate templates with pass variables"
    # set variables
    set -l STORE $HOME/.secrets/secrets.yml
    if not test -f $store
        echo "Error: No se encontró el almacén de contraseñas en $store" >&2
        return 1
    end
    sops -d $STORE | yq -r 'to_entries | .[] | select(.key != "sops") | ((.key | ascii_upcase) + " " + (.value | tostring))' | while read -l key value
        echo "✅ Loading $key"
        set -gx $key $value
    end
    echo "🚀 Secretos cargados"
    # configure templates
    echo "📝 Templates configurados"
    yadm alt
    # unset variables
    set -e (sops -d $STORE | yq -r 'keys | .[] | select(. != "sops") | ascii_upcase')
    echo "🧹 Secreto descargados"
end
