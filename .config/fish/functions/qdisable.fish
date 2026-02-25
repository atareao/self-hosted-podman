function qdisable --argument-names stack
    # 1. ¿Argumento vacío?
    if test -z "$stack"
        set_color yellow
        echo "⚠️ Uso: qdisable <nombre-del-stack>"
        set_color normal
        return 1
    end

    set -l dest_dir "$HOME/.config/containers/systemd"

    # 2. Gestión de servicios activos
    # Con el namespacing, detener los servicios es muy sencillo y preciso
    echo "Deteniendo servicios asociados al stack '$stack'..."
    systemctl --user stop "$stack-*" 2>/dev/null

    # 3. Eliminar los enlaces simbólicos con namespacing
    # Buscamos archivos que empiecen por "stack-"
    set -l files_removed 0
    
    # Usamos un comodín para capturar todos los enlaces del namespace del stack
    for link in $dest_dir/$stack-*
        # Verificación de seguridad: que sea un enlace simbólico
        if test -L "$link"
            if rm "$link"
                set files_removed (math $files_removed + 1)
            end
        end
    end

    # 4. Verificar si realmente se borró algo
    if test $files_removed -eq 0
        set_color yellow
        echo "⚠️ No se encontraron enlaces activos para el stack '$stack' en $dest_dir."
        set_color normal
    end

    # 5. Recargar systemd para limpiar el estado
    if systemctl --user daemon-reload
        set_color green
        echo "✅ Stack '$stack' deshabilitado correctamente ($files_removed enlaces eliminados)."
        set_color normal
        echo "Las unidades de systemd han sido eliminadas."
    else
        set_color red
        echo "❌ Error al recargar systemd."
        set_color normal
        return 1
    end
end
