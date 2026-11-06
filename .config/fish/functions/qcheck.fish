# qcheck: Detecta colisiones globales de quadlets entre stacks ANTES de habilitarlos.
#
#   - Colisiones duras (hacen fallar el comando, return 1):
#       * el mismo basename de unit en DOS o más stacks distintos;
#       * el mismo valor de ContainerName= en DOS o más units distintos.
#   - Avisos de convención (solo avisan, no fallan):
#       * units cuyo nombre no es <stack>.<ext> ni empieza por <stack>-<rol>.
#
# Uso: qcheck
function qcheck
    set -l available_dir "$HOME/.config/containers/available"
    set -l unit_re '\.(container|network|volume|pod|kube)$'

    if not test -d "$available_dir"
        set_color red; echo "❌ Error: No existe '$available_dir'."; set_color normal
        return 1
    end

    set -l names    # nombres lógicos (basename sin .jinja)
    set -l entries  # "<nombre>|<stack>|<ruta>"
    set -l cnames   # "<ContainerName>|<nombre> (<stack>)"
    set -l warns    # "<nombre>|<stack>"

    for stack in (command ls "$available_dir")
        set -l src "$available_dir/$stack"
        test -d "$src"; or continue

        for file in $src/*
            set -l fname (basename "$file")
            set -l logical $fname
            if string match -q '*.jinja' "$logical"
                set logical (string replace -r '\.jinja$' '' "$logical")
            end
            string match -qr $unit_re "$logical"; or continue

            set -a names "$logical"
            set -a entries "$logical|$stack|$file"

            # ContainerName= (global en Podman)
            if test -f "$file"
                for line in (cat "$file")
                    if string match -qr '^ContainerName=' "$line"
                        set -a cnames (string replace -r '^ContainerName=' '' "$line")"|$logical ($stack)"
                    end
                end
            end

            # Convención de nombres: <stack>.<ext> o <stack>-<rol>
            if not string match -q "$stack.*" "$logical"; and not string match -q "$stack-*" "$logical"
                set -a warns "$logical|$stack"
            end
        end
    end

    set -l hard 0

    # --- 1. Colisiones duras: basename de unit repetido en 2+ stacks ---
    set -l dup_names
    if test -n "$names"
        set dup_names (printf '%s\n' $names | sort | uniq -d)
    end
    for name in $dup_names
        test -z "$name"; and continue
        set hard 1
        set_color red; echo "❌ COLISIÓN DE NOMBRE DE UNIT: '$name'"; set_color normal
        for e in $entries
            set -l p (string split '|' $e)
            if test "$p[1]" = "$name"
                echo "     - stack '$p[2]': $p[3]"
            end
        end
    end

    # --- 2. Colisiones duras: ContainerName= repetido en 2+ units ---
    set -l cname_vals
    for c in $cnames
        set -a cname_vals (string split -m1 '|' $c)[1]
    end
    set -l dup_cn
    if test -n "$cname_vals"
        set dup_cn (printf '%s\n' $cname_vals | sort | uniq -d)
    end
    for cn in $dup_cn
        test -z "$cn"; and continue
        set hard 1
        set_color red; echo "❌ COLISIÓN DE ContainerName=: '$cn'"; set_color normal
        for c in $cnames
            set -l p (string split -m1 '|' $c)
            if test "$p[1]" = "$cn"
                echo "     - unit $p[2]: ContainerName=$cn"
            end
        end
    end

    # --- 3. Avisos de convención (informativos) ---
    set -l nw (count $warns)
    if test $nw -gt 0
        set_color yellow
        echo "⚠️  Avisos de convención: $nw unit(s) no siguen <stack>.<ext> ni <stack>-<rol>."
        set_color normal
        set -l shown 0
        for w in $warns
            if test $shown -ge 15; break; end
            set -l p (string split '|' $w)
            echo "     - '$p[1]' (stack '$p[2]')"
            set shown (math $shown + 1)
        end
        if test $nw -gt 15
            echo "     ... y "(math $nw - 15)" más (el resto de la lista es solo informativa)."
        end
    end

    # --- Resumen ---
    if test $hard -eq 0
        set_color green; echo "✅ Sin colisiones duras de quadlets."; set_color normal
        return 0
    else
        set_color red; echo "❌ Se han detectado colisiones duras. Resuélvelas antes de habilitar."; set_color normal
        return 1
    end
end
