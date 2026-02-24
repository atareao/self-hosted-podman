function q-disable --argument-names stack
    set -l dest "$HOME/.config/containers/systemd/$stack"

    if test -L "$dest"
        # Eliminar el enlace simbólico
        rm "$dest"
        
        # Recargar para que systemd olvide las unidades
        systemctl --user daemon-reload
        
        set_color yellow
        echo "🛑 Stack '$stack' deshabilitado."
        set_color normal
        echo "Nota: Los contenedores que estuvieran corriendo seguirán activos hasta que los detengas o reinicies."
    else
        set_color red
        echo "❌ Error: El stack '$stack' no está habilitado (no se encontró el link en $dest)"
        set_color normal
    end
end
