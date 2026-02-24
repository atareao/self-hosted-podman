function q-enable --argument-names stack
    set -l src "$HOME/.config/containers/available/$stack"
    set -l dest "$HOME/.config/containers/systemd/$stack"

    if test -d "$src"
        # Crear el directorio padre si no existe
        mkdir -p (dirname "$dest")
        
        # Crear el enlace simbólico
        ln -s "$src" "$dest"
        
        # Recargar systemd
        systemctl --user daemon-reload
        
        set_color green
        echo "✅ Stack '$stack' habilitado correctamente."
        set_color normal
        echo "Ahora puedes iniciar los servicios con 'systemctl --user start ...'"
    else
        set_color red
        echo "❌ Error: El stack '$stack' no existe en $src"
        set_color normal
    end
end
