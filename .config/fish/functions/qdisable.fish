function qdisable --argument-names stack
    if test -z "$stack"; return 1; end
    set -l src "$HOME/.config/containers/available/$stack"
    set -l dest_dir "$HOME/.config/containers/systemd"

    if not test -d "$src"
        set_color red; echo "❌ Error: No existe el stack '$stack' en available."; set_color normal
        return 1
    end

    echo "Deteniendo servicios de '$stack'..."
    for file in $src/*
        set -l fname (basename "$file" | cut -d. -f1)
        systemctl --user stop "$fname" 2>/dev/null
    end

    set -l files_removed 0
    for file in $src/*
        set -l fname (basename "$file")
        set -l target "$dest_dir/$fname"
        if test -L "$target"
            if rm "$target"
                set files_removed (math $files_removed + 1)
            end
        end
    end

    systemctl --user daemon-reload
    set_color yellow; echo "🛑 Stack '$stack' deshabilitado ($files_removed enlaces eliminados)."; set_color normal
end
