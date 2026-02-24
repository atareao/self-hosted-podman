function qlist
    set -l available_dir "$HOME/.config/containers/available"
    set -l systemd_dir "$HOME/.config/containers/systemd"

    if not test -d "$available_dir"
        set_color red; echo "❌ El directorio $available_dir no existe."; set_color normal
        return 1
    end

    # --- Sección del Spinner ---
    # Creamos un proceso en segundo plano para el spinner
    echo -n "🔍 Analizando stacks... "
    set -l frames "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"
    
    # Recopilamos los datos primero
    set -l results
    set -l stacks (ls "$available_dir")
    
    for stack in $stacks
        # Dibujar spinner
        set -l frame $frames[(math (math $status % 10) + 1)]
        printf "\r%s %s" (set_color cyan)$frame(set_color normal) "Analizando stacks..."
        
        set -l dest "$systemd_dir/$stack"
        set -l link_status
        set -l run_status

        if test -L "$dest"
            set link_status (set_color green)"ON"(set_color normal)
            if systemctl --user is-active --quiet "$stack"
                set run_status (set_color green)"running"(set_color normal)
            else
                set run_status (set_color yellow)"stopped"(set_color normal)
            end
        else
            set link_status (set_color red)"OFF"(set_color normal)
            set run_status (set_color white)"---"(set_color normal)
        end
        
        # Guardamos el resultado formateado en una lista
        set -a results " [$link_status]    $run_status    $stack"
    end

    # Limpiar la línea del spinner
    printf "\r%-30s\n" "✅ Análisis completado:"
    
    # --- Mostrar Tabla Final ---
    echo "------------------------------------------"
    printf "%-7s %-19s %s\n" "LINK" "STATUS" "STACK"
    echo "------------------------------------------"
    for line in $results
        # Usamos printf con %b para interpretar los códigos de color guardados
        set -l col_link (echo $line | awk '{print $1}')
        set -l col_stat (echo $line | awk '{print $2}')
        set -l col_name (echo $line | awk '{print $3}')
        printf " %b    %-19b %s\n" "$col_link" "$col_stat" "$col_name"
    end
    echo "------------------------------------------"
end
