function qdisable --argument-names stack
    # 1. ¿Argumento vacío?
    if test -z "$stack"
        set_color yellow
        echo "⚠️ Uso: qdisable <nombre-del-stack>"
        set_color normal
        return 1
    end

    set -l dest "$HOME/.config/containers/systemd/$stack"

    # 2. ¿Existe el destino y es un enlace simbólico?
    if not test -L "$dest"
        set_color red
        if test -e "$dest"
            echo "❌ Error: '$dest' existe pero NO es un enlace simbólico (es un archivo o directorio real)."
            echo "⚠️ No lo borraré automáticamente para evitar pérdida de datos."
        else
            echo "❌ Error: El stack '$stack' no parece estar habilitado (no existe $dest)."
        end
        set_color normal
        return 1
    end

    # 3. Gestión de servicios activos (Opcional pero recomendado)
    # Intentamos detener los servicios asociados antes de romper el enlace.
    # Usamos el wildcard para capturar todas las unidades que genera el stack.
    echo "Deteniendo servicios asociados a '$stack'..."
    systemctl --user stop "$stack*" 2>/dev/null

    # 4. Eliminar el enlace simbólico
    if rm "$dest"
        # 5. Recargar para que systemd limpie las unidades generadas
        if systemctl --user daemon-reload
            set_color green
            echo "✅ Stack '$stack' deshabilitado correctamente."
            set_color normal
            echo "Las definiciones de Quadlet han sido eliminadas de systemd."
        else
            set_color red
            echo "❌ Error al recargar systemd tras eliminar el enlace."
            set_color normal
            return 1
        end
    else
        set_color red
        echo "❌ Error físico al intentar borrar el enlace en $dest."
        set_color normal
        return 1
    end
end
