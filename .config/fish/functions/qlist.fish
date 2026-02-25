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

        # 1. Comprobar si el stack está habilitado (si existe algún enlace)
        set -l linked_files (ls $src 2>/dev/null)
        for f in $linked_files
            if test -L "$systemd_dir/$f"
                set link_status "ON"
                set link_color green
                break
            end
        end

        # 2. Si está ON, buscar si ALGUNO de sus servicios está activo
        if test "$link_status" = "ON"
            set run_status "stopped"
            set run_color yellow
            
            for f in $linked_files
                # Solo comprobamos archivos que generan servicios (.container, .kube, .pod)
                if string match -qr '\.(container|kube|pod)$' "$f"
                    set -l service_name (string split -r -m1 . $f)[1]
                    if systemctl --user is-active --quiet "$service_name"
                        set run_status "running"
                        set run_color green
                        break # Si uno está running, el stack está running
                    end
                end
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
