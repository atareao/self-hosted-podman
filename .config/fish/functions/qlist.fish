function qlist
    set -l available_dir "$HOME/.config/containers/available"
    set -l systemd_dir "$HOME/.config/containers/systemd"

    echo -n "🔍 Analizando stacks... "
    set -l table_data
    for stack in (ls "$available_dir")
        set -l src "$available_dir/$stack"
        set -l link_status "OFF"
        set -l run_status "---"
        set -l link_color red
        set -l run_color white

        # Buscamos el primer archivo Quadlet para comprobar el enlace
        set -l main_file (ls $src | grep -E '\.(container|kube|pod|volume|network)$' | head -n 1)

        if test -n "$main_file"; and test -L "$systemd_dir/$main_file"
            set link_status "ON"
            set link_color green
            set -l service_name (string split -r -m1 . $main_file)[1]
            if systemctl --user is-active --quiet "$service_name"
                set run_status "running"
                set run_color green
            else
                set run_status "stopped"
                set run_color yellow
            end
        end
        set -a table_data "$link_color|$link_status|$run_color|$run_status|$stack"
    end

    printf "\r%-50s\n" "✅ Análisis completado"
    echo "------------------------------------------"
    printf "%-8s %-12s %s\n" "LINK" "STATUS" "STACK"
    echo "------------------------------------------"
    for line in $table_data
        set -l parts (string split "|" $line)
        echo -n " ["
        set_color $parts[1]; echo -n "$parts[2]"; set_color normal
        echo -n "]    "
        set_color $parts[3]; printf "%-11s" "$parts[4]"; set_color normal
        echo " $parts[5]"
    end
    echo "------------------------------------------"
end
