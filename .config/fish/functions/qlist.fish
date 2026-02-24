function qlist
    set -l available_dir "$HOME/.config/containers/available"
    set -l systemd_dir "$HOME/.config/containers/systemd"

    if not test -d "$available_dir"
        set_color red; echo "❌ El directorio $available_dir no existe."; set_color normal
        return 1
    end

    # 1. Recopilar stacks
    set -l stacks (ls "$available_dir")
    if test -z "$stacks"
        echo "No hay stacks disponibles en $available_dir"
        return 0
    end

    # 2. Spinner visual mientras procesamos
    echo -n "🔍 Analizando stacks... "
    set -l frames "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏"
    set -l i 1

    # Cabecera de la tabla (la imprimimos después para que no la borre el spinner)
    set -l table_header "------------------------------------------\n"
    set -l table_titles (printf "%-7s %-12s %s\n" "LINK" "STATUS" "STACK")
    set -l table_body ""

    for stack in $stacks
        # Actualizar spinner
        printf "\r%s Analizando: %s" (set_color cyan)$frames[$i](set_color normal) $stack
        set i (math $i + 1); if test $i -gt 10; set i 1; end
        
        set -l dest "$systemd_dir/$stack"
        set -l link_color red
        set -l link_text "OFF"
        set -l run_status (set_color white)"---"(set_color normal)

        if test -L "$dest"
            set link_color green
            set link_text "ON " # Espacio para alinear
            
            if systemctl --user is-active --quiet "$stack"
                set run_status (set_color green)"running"(set_color normal)
            else
                set run_status (set_color yellow)"stopped"(set_color normal)
            end
        end

        # Construir la línea de la tabla
        # Usamos string collect para evitar problemas con printf y variables complejas
        set -l link_part (set_color $link_color)"$link_text"(set_color normal)
        set -l line (printf " [%b]    %-19b %s\n" "$link_part" "$run_status" "$stack")
        set table_body $table_body$line
    end

    # Limpiar línea del spinner y mostrar tabla
    printf "\r%-40s\n" "✅ Análisis completado"
    echo "------------------------------------------"
    printf "%-7s %-12s %s\n" "LINK" "STATUS" "STACK"
    echo "------------------------------------------"
    echo -e $table_body
    echo "------------------------------------------"
end
