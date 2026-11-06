function unjinja --description="Fill scripts"
    # Herramientas en ~/.local/bin (sops, jinrender, yq). En shells NO
    # interactivos (hook post_pull de yadm, `fish -c`) config.fish no se
    # ejecuta, asi que nos aseguramos aqui de tenerlas en el PATH.
    if test -d $HOME/.local/bin
        if not contains -- $HOME/.local/bin $PATH
            set -gx PATH $HOME/.local/bin $PATH
        end
    end

    set -l STORE $HOME/.secrets/secrets.yml
    if not test -f $STORE
        echo "Error: No se encontró el almacén de contraseñas en $STORE" >&2
        return 1
    end

    # sops necesita la clave age. En shells NO interactivos no se ejecuta
    # config.fish, asi que la fijamos aqui.
    if not set -q SOPS_AGE_KEY_FILE
        set -gx SOPS_AGE_KEY_FILE $HOME/.secrets/sops/age/key.txt
    end

    # 1. Carga de secretos.
    #    Expresion agnostica de la version de yq (v3 jq-based / v4 mikefarah):
    #    no usamos ascii_upcase ni upcase; subimos a mayusculas con string upper.
    sops -d $STORE | yq -r 'to_entries[] | select(.key != "sops") | [.key, (.value | tostring)] | @tsv' | while read -l -d \t key value
        if test -n "$key"
            echo "✅ Loading $key"
            set -gx (string upper $key) $value
        end
    end
    echo "🚀 Secretos cargados"

    # FQDN del host: environment.d es la fuente de verdad (no es un secreto).
    # Plantillas en TIEMPO DE RENDER (p.ej. traefik/dynamic/dashboard-auth.yml)
    # lo necesitan como {{ env.FQDN }}; los quadlets usan ${FQDN} de systemd.
    set -l fqdn_file $HOME/.config/environment.d/fqdn.conf
    if test -f $fqdn_file
        set -gx FQDN (string replace -r '^FQDN=' '' (cat $fqdn_file) | head -1)
        echo "🌐 FQDN=$FQDN"
    end

    # 2. Procesado de plantillas Jinja
    yadm list -a | while read -l item
        if test (path extension $item) = ".jinja"
            set -l jinja (path normalize ~/"$item")
            set -l output (path change-extension '' "$jinja")
            jinrender --jinja "$jinja" --output "$output"
        end
    end
    echo "📝 Templates configurados"

    # 3. Limpieza de variables (mayusculas via string upper de Fish)
    set -l raw_keys (sops -d $STORE | yq -r 'keys[] | select(. != "sops")')
    if test -n "$raw_keys"
        set -l keys (string upper $raw_keys)
        set -e $keys
    end
    echo "🧹 Secretos descargados"
end
