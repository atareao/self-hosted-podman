function qenable --argument-names stack
    # 1. ¿Argumento vacío?
    if test -z "$stack"
        set_color yellow; echo "⚠️ Uso: qenable <stack>"; set_color normal
        return 1
    end

    set -l src "$HOME/.config/containers/available/$stack"
    set -l dest_dir "$HOME/.config/containers/systemd"

    # 2. ¿Existe el origen?
    if not test -d "$src"
        set_color red; echo "❌ Error: El origen '$src' no existe o no es un directorio."; set_color normal
        return 1
    end

    # 3. Verificación de sintaxis Quadlet
    if not /usr/libexec/podman/quadlet -user -dryrun >/dev/null 2>&1
        set_color yellow; echo "⚠️ Advertencia: Quadlet detectó posibles errores en los archivos de '$stack'."; set_color normal
    end

    # 4. Acción: Enlazar archivos individuales con namespacing
    mkdir -p "$dest_dir"

    set -l files_linked 0
    for file in $src/*
        set -l fname (basename "$file")

        # Solo enlazamos archivos reconocidos por Quadlet (omitimos .jinja)
        if string match -qr '\.(container|volume|network|kube|pod)$' "$fname"
            # --- Aplicamos Namespacing ---
            set -l ns_name "$stack-$fname"
            set -l target "$dest_dir/$ns_name"

            # Verificación de seguridad: si existe un archivo real
            if test -e "$target"; and not test -L "$target"
                set_color red; echo "❌ Error: '$target' ya existe y es un archivo real. Saltando..."; set_color normal
                continue
            end

            if ln -sf "$file" "$target"
                set files_linked (math $files_linked + 1)
            end
        end
    end

    # 5. Finalizar y recargar
    if test $files_linked -gt 0
        if systemctl --user daemon-reload
            set_color green; echo "✅ Stack '$stack' habilitado con namespacing ($files_linked archivos)."; set_color normal

            # 6. Mostrar unidades creadas
            echo "Servicios disponibles (ahora con prefijo '$stack-'):"
            # Listamos las unidades que empiezan por el nombre del stack
            systemctl --user list-units "$stack-*" --all --no-legend
        else
            set_color red; echo "❌ Error al recargar systemd."; set_color normal
            return 1
        end
    else
        set_color yellow; echo "⚠️ No se encontraron archivos válidos en '$stack'."; set_color normal
    end
end
