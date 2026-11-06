function qenable --argument-names stack
    if test -z "$stack"
        set_color yellow; echo "⚠️ Uso: qenable <stack>"; set_color normal
        return 1
    end

    set -l src "$HOME/.config/containers/available/$stack"
    set -l dest_dir "$HOME/.config/containers/systemd"

    if not test -d "$src"
        set_color red; echo "❌ Error: El origen '$src' no existe."; set_color normal
        return 1
    end

    mkdir -p "$dest_dir"
    set -l files_linked 0

    # --- PRE-SCAN DE COLISIÓN DE NOMBRE GLOBAL (atómico) ---
    # El directorio systemd/ es plano: si otro stack ya tiene un unit con el
    # mismo basename, colisionaría. Comprobamos TODOS los units a habilitar
    # antes de enlazar nada; si hay colisión, abortamos sin dejar el stack a medias.
    for file in $src/*
        set -l fname (basename "$file")
        if string match -qr '\.(container|volume|network|kube|pod)$' "$fname"
            for other in $HOME/.config/containers/available/*/
                set -l other_stack (basename "$other")
                if test "$other_stack" = "$stack"; continue; end
                if test -e "$other$fname"
                    set_color red
                    echo "❌ ERROR DE COLISIÓN DE NOMBRE GLOBAL:"
                    echo "   El unit '$fname' ya existe en el stack '$other_stack'."
                    echo "   Abortando sin enlazar."
                    set_color normal
                    return 1
                end
            end
        end
    end

    for file in $src/*
        set -l fname (basename "$file")
        if string match -qr '\.(container|volume|network|kube|pod)$' "$fname"
            set -l target "$dest_dir/$fname"

            # --- ESCUDO DE SEGURIDAD ---
            if test -L "$target"
                set -l existing_link (readlink "$target")
                if test "$existing_link" != "$file"
                    set_color red
                    echo "❌ ERROR DE COLISIÓN:"
                    echo "   El archivo '$fname' ya está habilitado por otro stack."
                    echo "   Apunta a: $existing_link"
                    echo "   No se ha sobrescrito."
                    set_color normal
                    continue
                end
            else if test -e "$target"
                set_color red; echo "❌ Error: '$target' es un archivo real. Abortando."; set_color normal
                continue
            end

            if ln -sf "$file" "$target"
                set files_linked (math $files_linked + 1)
            end
        end
    end

    if test $files_linked -gt 0
        systemctl --user daemon-reload
        set_color green; echo "✅ Stack '$stack' habilitado ($files_linked archivos)."; set_color normal
        echo "Servicios:"
        systemctl --user list-units "$stack*" --all --no-legend
    end
end
