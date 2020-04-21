#!/bin/bash

#
# An implemention of Conway's Game of Life in pure Bash script
#
# Copyright (C) 2017 Richard Merry - All Rights Reserved
# Permission to copy and modify is granted under the MIT license
# Version 1.0.0
# Licence: MIT

ACTIVE=true
DORMANT=false

COLS=20
LINES=20
NCELLS=400

CELLS=()
NEIGHBOUR_CACHE=()
DOUBLE_WIDTH=false
PROGRAM_NAME=$0

function clear {
  echo -e "\033[2J"
}

function draw {
    clear

    if [[ $DOUBLE_WIDTH == true ]] ; then
        for ((i=0; i<=$NCELLS; i++)) do
            if [[ ${CELLS[$i]} == $ACTIVE ]] ; then
                local y="$((i/COLS))"
                local x="$(((i%COLS+1)*2-1))"
                echo -en "\033[$y;${x}H\033[0;100m  \033[0m"
            fi
        done
    else
        for ((i=0; i<=$NCELLS; i++)) do
            if [[ ${CELLS[$i]} == $ACTIVE ]] ; then
                local y="$((i/COLS))"
                local x="$((i%COLS))"
                echo -en "\033[$y;${x}H\033[0;100m \033[0m"
            fi
        done
    fi
}

function game_loop {
    local last_tick=$(date +%s%3N)
    local current_tick=0
    local diff=0

    for (( ; ; )) do
        current_tick=$(date +%s%3N)
        diff=$(($current_tick-$last_tick))

        if [[ $diff -ge $SPEED ]]; then
            last_tick=$(date +%s%3N)
            draw
            update
        fi
    done
}

function init {
    COLS=${COLS:-20}
    LINES=${LINES:-20}
    NCELLS=$((COLS*LINES))
    SPEED=${SPEED:-1000}

    echo "Generating topology..."

    for ((i=0; i<=$NCELLS; i++)) do
        local rnd=$(($RANDOM%2+1))

        if [[ $rnd -eq 1 ]] ; then
            CELLS[$i]=$ACTIVE
        else
            CELLS[$i]=$DORMANT
        fi
    done

    # Calculating the indicies of the neighbours for a given cell is costly
    # in realtime, calculate and cache the list of neighbours for all cells

    echo "Precaching resources..."

    for ((i=0; i<=$NCELLS; i++)) do
        local neighbours=""

        if [[ $i -lt $COLS ]] ; then # on top row
            if [[ $((i%COLS)) -eq 0 ]] ; then # on left edge
                neighbours="$((i+1));$((i+COLS));$((i+COLS+1))"
            elif [[ $((COLS-1)) -eq $i ]] ; then # on right edge
                neighbours="$((i-1));$((i+COLS-1));$((i+COLS))"
            else
                neighbours="$((i-1));$((i+1));$((i+COLS-1));$((i+COLS));$((i+COLS+1))"
            fi
        elif [[ $(((COLS*LINES)-COLS)) -le $i ]] ; then # on bottom row
            if [[ $((i%COLS)) -eq 0 ]] ; then # on left edge
                neighbours="$((i-COLS));$((i-COLS+1));$((i+1))"
            elif [[ $((COLS*LINES-1)) -eq $i ]] ; then # on right edge
                neighbours="$((i-COLS-1));$((i-COLS));$((i-1))"
            else
                neighbours="$((i-COLS-1));$((i-COLS));$((i-COLS+1));$((i-1));$((i+1)) "
            fi
        elif [[ $((i%COLS)) -eq 0 ]] ; then # on (none top or bottom) left edge
            neighbours="$((i-COLS));$((i-COLS+1));$((i+1));$((i+COLS));$((i+COLS+1))"
        elif [[ $(((i+1-COLS)%COLS)) -eq 0 ]] ; then # on (none top or bottom) right edge
            neighbours="$((i-COLS-1));$((i-COLS));$((i-1));$((i+COLS-1));$((i+COLS))"
        else # inner
            neighbours="$((i-COLS-1));$((i-COLS));$((i-COLS+1));$((i-1));$((i+1));$((i+COLS-1));$((i+COLS));$((i+COLS+1))"
        fi

        NEIGHBOUR_CACHE[$i]=$neighbours
    done
}

function update {
    local dcells=()

    for ((i=0; i<=$NCELLS; i++)) do
        # Get number of ACTIVE neighbours for cell `$i`
        local neighbours=0
        IFS=';' read -ra neighbour_list <<< "${NEIGHBOUR_CACHE[$i]}"
        for n in "${neighbour_list[@]}"; do
            if [[ ${CELLS[$n]} == $ACTIVE ]] ; then
                neighbours=$((neighbours+1))
            fi
        done

        if [[ $neighbours -eq 3 ]] ; then
            dcells[$i]=$ACTIVE
        elif [[ $neighbours -eq 2 ]] &&
             [[ ${CELLS[$i]} == $ACTIVE ]] ; then
            dcells[$i]=$ACTIVE
        else
            dcells[$i]=$DORMANT
        fi
    done

    CELLS=("${dcells[@]}")
}

function print_usage {
    echo "Usage: $PROGRAM_NAME [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "  -D,     --double-width               Use two columns per cell"
    echo "  -h,     --help                       Display this message and exit"
    echo "  -m=NUM, --speed=NUM                  Cellular evolution speed in milliseconds;"
    echo "                                       defaults to 1000"
    echo "  -s=NUM, --size=NUM                   Grid size; defaults to 20"
    echo

    exit $1
}

for i in "$@"
do
    case $i in
        -s=*|--size=*)
            COLS="${i#*=}"
            LINES="$COLS"
            ;;
        -m=*|--speed=*)
            SPEED="${i#*=}"
            ;;
        -D|--double-width)
            DOUBLE_WIDTH=true
            ;;
        -h|--help)
            print_usage 0
            ;;
        *)
            print_usage 1
            ;;
    esac
done

init
game_loop
