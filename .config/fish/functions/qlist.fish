function qlist
    set -l available_dir "$HOME/.config/containers/available"
    set -l systemd_dir "$HOME/.config/containers/systemd"

    if not test -d "$available_dir"
        set_color red; echo "❌ El directorio $available_dir no existe."; set_color normal
        return 1
    end

    set -l stacks (ls "$available_dir")
    if test -z "$stacks"
        echo "No hay stacks disponibles."
        return 0
    end

    # --- Spinner ---
    echo -n "🔍 Analizando stacks... "
    set -l frames "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"
    set -l i 1
    set -l table_data

    for stack in $stacks
        # Animación del spinner
        printf "\r%s Analizando: %s" (set_color cyan)$frames[$i](set_color normal) "$stack"
        set i (math $i % 10 + 1)
        
        set -l dest "$systemd_dir/$stack"
        set -l link_status "OFF"
        set -l run_status "---"
        set -l link_color red
        set -l run_color white

        if test -L "$dest"
            set link_status "ON"
            set link_color green
            if systemctl --user is-active --quiet "$stack"
                set run_status "running"
                set run_color green
            else
                set run_status "stopped"
                set run_color yellow
            end
        end

        # Guardamos los datos puros separados por un carácter especial para procesarlos luego
        set -a table_data "$link_color|$link_status|$run_color|$run_status|$stack"
        # Pequeño delay para que el spinner sea visible si tienes pocos stacks
        sleep 0.05 
    end

    # Limpiar línea del spinner
    printf "\r%-50s\n" "✅ Análisis completado"
    
    # --- Cabecera ---
    echo "------------------------------------------"
    printf "%-8s %-12s %s\n" "LINK" "STATUS" "STACK"
    echo "------------------------------------------"

    # --- Cuerpo de la tabla ---
    for line in $table_data
        # Extraemos los valores usando 'string split' (nativo de Fish)
        set -l parts (string split "|" $line)
        set -l l_col $parts[1]; set -l l_txt $parts[2]
        set -l r_col $parts[3]; set -l r_txt $parts[4]
        set -l name  $parts[5]

        # Imprimimos usando set_color directamente para evitar errores de printf
        echo -n " ["
        set_color $l_col; echo -n "$l_txt"; set_color normal
        echo -n "]    "
        set_color $r_col; printf "%-11s" "$r_txt"; set_color normal
        echo " $name"
    end
    echo "------------------------------------------"
end
