function restart_pi() {
    pkill qemu
    ./run.sh tests/pi
}

function restart_spigotto() {
    pkill qemu
    ./run.sh tests/spigotto.labmda
}

function restart_out() {
    pkill qemu
    make -C "Asm part" run
}

(inotifywait -m -e close_write tests/pi|
    while read file_path file_event file_name
    do
        restart_pi&
    done)&

(inotifywait -m -e close_write tests/spigotto.labmda|
    while read file_path file_event file_name
    do
        restart_spigotto&
    done)&

(inotifywait -m -e close_write "Asm part/out.asm"|
    while read file_path file_event file_name
    do
        restart_out&
    done)