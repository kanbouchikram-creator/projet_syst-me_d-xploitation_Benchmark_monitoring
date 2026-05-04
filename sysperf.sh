#!/bin/bash

MODE=""
TASK_TYPE="cpu"
CUSTOM_CMD=""
NUM_TASKS=3
ENABLE_MONITOR=false
ENABLE_LOG=false
LOG_FILE="history.log"

show_help() {
    echo "===== SysPerf Monitor ====="
    echo "./sysperf.sh -seq|-f|-t|-s|-compare [options]"
    echo "-task cpu|io"
    echo "-cmd \"commande\""
    echo "-n nombre"
    echo "-monitor"
    echo "-log"
    echo "-h"
}

# ===== TASKS =====
cpu_task() {
    local x=0
    for ((i=1; i<=10000000; i++)); do
        x=$((x + i * i))
    done
}

io_task() {
   local file="test_$$-$RANDOM.tmp"
    dd if=/dev/zero of="$file" bs=1M count=100 status=none 2>/dev/null
    rm -f "$file"
}

run_task() {
    if [ -n "$CUSTOM_CMD" ]; then
        bash -c "$CUSTOM_CMD"
    elif [ "$TASK_TYPE" = "cpu" ]; then
        cpu_task
    elif [ "$TASK_TYPE" = "io" ]; then
        io_task
    else
        echo "Erreur : tâche invalide"
        exit 1
    fi
}

# ===== EXECUTION MODES =====
run_seq() {
    for ((i=1; i<=NUM_TASKS; i++)); do
        run_task
    done
}

run_fork() {
    for ((i=1; i<=NUM_TASKS; i++)); do
        run_task &
    done
    wait
}

run_thread() {
    # simulation thread en bash
    for ((i=1; i<=NUM_TASKS; i++)); do
        run_task &
    done
    wait
}

run_subshell() {
    for ((i=1; i<=NUM_TASKS; i++)); do
        ( run_task )
    done
}

# ===== MONITORING =====
monitor_system() {
    echo "----- MONITORING -----"
    uptime
    free -h
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 5
    echo "----------------------"
}

# ===== LOG =====
log_result() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}

# ===== BENCHMARK =====
measure_execution() {
    local mode="$1"

    echo ""
    echo "===== Méthode : $mode ====="

    if [ "$ENABLE_MONITOR" = true ]; then
        monitor_system
    fi

    /usr/bin/time -f "CPU: %P | RAM: %M KB | Temps: %E" bash -c "
        TASK_TYPE='$TASK_TYPE'
        CUSTOM_CMD='$CUSTOM_CMD'
        NUM_TASKS='$NUM_TASKS'

        cpu_task() {
            local x=0
            for ((i=1; i<=3000000; i++)); do
                x=\$((i*i))
            done
        }

        io_task() {
            local file=\"test_\$\$-\$RANDOM.tmp\"
            dd if=/dev/zero of=\"\$file\" bs=1M count=100 status=none 2>/dev/null
            rm -f \"\$file\"
        }

        run_task() {
            if [ -n \"\$CUSTOM_CMD\" ]; then
                bash -c \"\$CUSTOM_CMD\"
            elif [ \"\$TASK_TYPE\" = \"cpu\" ]; then
                cpu_task
            elif [ \"\$TASK_TYPE\" = \"io\" ]; then
                io_task
            fi
        }

        run_seq() {
            for ((i=1; i<=NUM_TASKS; i++)); do run_task; done
        }

        run_fork() {
            for ((i=1; i<=NUM_TASKS; i++)); do run_task & done
            wait
        }

        run_thread() {
            for ((i=1; i<=NUM_TASKS; i++)); do run_task & done
            wait
        }

        run_subshell() {
            for ((i=1; i<=NUM_TASKS; i++)); do ( run_task ); done
        }

        case \"$mode\" in
            seq) run_seq ;;
            fork) run_fork ;;
            thread) run_thread ;;
            subshell) run_subshell ;;
        esac
    "

    result="Mode: $mode | Task: ${CUSTOM_CMD:-$TASK_TYPE} | N: $NUM_TASKS"
    echo "$result"

    if [ "$ENABLE_LOG" = true ]; then
        log_result "$result"
    fi
}

# ===== COMPARE =====
run_compare() {
    echo "===== BENCHMARK COMPLET ====="
    measure_execution "seq"
    measure_execution "fork"
    measure_execution "thread"
    measure_execution "subshell"
}

# ===== ARGUMENTS =====
while [ $# -gt 0 ]; do
    case "$1" in
        -seq) MODE="seq"; shift ;;
        -f) MODE="fork"; shift ;;
        -t) MODE="thread"; shift ;;
        -s) MODE="subshell"; shift ;;
        -compare) MODE="compare"; shift ;;
        -task) TASK_TYPE="$2"; CUSTOM_CMD=""; shift 2 ;;
        -cmd) CUSTOM_CMD="$2"; shift 2 ;;
        -n) NUM_TASKS="$2"; shift 2 ;;
        -monitor) ENABLE_MONITOR=true; shift ;;
        -log) ENABLE_LOG=true; shift ;;
        -h) show_help; exit 0 ;;
        *) echo "Option inconnue"; exit 1 ;;
    esac
done

if [ -z "$MODE" ]; then
    echo "Erreur : mode manquant"
    show_help
    exit 1
fi

case "$MODE" in
    seq) measure_execution "seq" ;;
    fork) measure_execution "fork" ;;
    thread) measure_execution "thread" ;;
    subshell) measure_execution "subshell" ;;
    compare) run_compare ;;
    *) echo "Mode invalide" ;;
esac
