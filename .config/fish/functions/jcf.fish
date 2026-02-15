function jcf --description "Logs limpios con bat y ansifilter y siguiendo"
    journalctl --user -xefu $argv[1] --no-pager | ansifilter | batcat -l log
end
