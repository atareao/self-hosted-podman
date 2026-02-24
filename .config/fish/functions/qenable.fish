function qenable --argument-names stack
    # 1. ¿Argumento vacío?
    if test -z "$stack"
        set_color yellow; echo "⚠️ Uso: qenable <stack>"; set_color normal
        return 1
    end

    set -l src "$HOME/.config/containers/available/$stack"
    set -l dest "$HOME/.config/containers/systemd/$stack"

    # 2. ¿Existe el origen?
    if not test -e "$src"
        set_color red; echo "❌ Error: El origen '$src' no existe."; set_color normal
        return 1
    end

    # 3. ¿El destino ya es un archivo real (no un enlace)?
    if test -e "$dest"; and not test -L "$dest"
        set_color red
        echo "❌ Error: El destino '$dest' ya existe y es un archivo real."
        echo "⚠️ Por seguridad, no lo sobrescribiré. Muévelo manualmente."
        set_color normal
        return 1
    end

    # 4. Verificación de sintaxis Quadlet (Opcional pero muy útil)
    # Buscamos archivos .container, .network, etc. y validamos uno
    if test -d "$src"
        set -l first_file (find "$src" -name "*.container" -o -name "*.network" -o -name "*.volume" | head -n 1)
        if test -n "$first_file"
            # Podman quadlet no tiene un 'lint' oficial fácil, pero podemos ver si genera algo
            if not /usr/libexec/podman/quadlet -dryrun >/dev/null 2>&1
                 set_color yellow; echo "⚠️ Advertencia: Quadlet detectó posibles errores en los archivos."; set_color normal
            end
        end
    end

    # 5. Acción
    mkdir -p (dirname "$dest")
    
    if ln -sf "$src" "$dest"
        if systemctl --user daemon-reload
            set_color green; echo "✅ Stack '$stack' habilitado."; set_color normal
            
            # 6. Mostrar qué unidades se han creado
            echo "Servicios disponibles:"
            systemctl --user list-units "$stack*" --all --no-legend
        else
            set_color red; echo "❌ Error al recargar systemd."; set_color normal
            return 1
        end
    end
end
