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

        set -l src "$available_dir/$stack"
        set -l link_status "OFF"
        set -l run_status "---"
        set -l link_color red
        set -l run_color white

        # 1. Identificamos el archivo principal para construir el nombre con namespace
        set -l main_file (ls $src | grep -E '\.(container|kube|pod)$' | head -n 1)
        if test -z "$main_file"
            set main_file (ls $src | grep -E '\.(volume|network)$' | head -n 1)
        end

        if test -n "$main_file"
            # El nombre en systemd ahora lleva el prefijo del stack
            set -l ns_name "$stack-$main_file"
            set -l target "$systemd_dir/$ns_name"
            # El nombre del servicio es el nombre del enlace sin la extensión
            set -l service_name (string split -r -m1 . $ns_name)[1]

            # 2. Comprobamos si el enlace con namespacing existe
            if test -L "$target"
                set link_status "ON"
                set link_color green

                # 3. Comprobamos si el servicio (con prefijo) está activo
                if systemctl --user is-active --quiet "$service_name"
                    set run_status "running"
                    set run_color green
                else
                    set run_status "stopped"
                    set run_color yellow
                end
            end
        end

        set -a table_data "$link_color|$link_status|$run_color|$run_status|$stack"
        sleep 0.05
    end

    # Limpiar línea del spinner
    printf "\r%-50s\n" "✅ Análisis completado"

    echo "------------------------------------------"
    printf "%-8s %-12s %s\n" "LINK" "STATUS" "STACK"
    echo "------------------------------------------"

    for line in $table_data
        set -l parts (string split "|" $line)
        set -l l_col $parts[1]; set -l l_txt $parts[2]
        set -l r_col $parts[3]; set -l r_txt $parts[4]
        set -l name  $parts[5]

        echo -n " ["
        set_color $l_col; echo -n "$l_txt"; set_color normal
        echo -n "]    "
        set_color $r_col; printf "%-11s" "$r_txt"; set_color normal
        echo " $name"
    end
    echo "------------------------------------------"
end
