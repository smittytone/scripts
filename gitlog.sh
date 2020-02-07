#!/usr/bin/env bash

# Not my code -- written by A Houghton

echo -e "Year\tAdded\tRemoved\tTotal"

total=0

for year in $(seq 2010 2019); do
    yearAdd=0
    yearSub=0
    TMPFILE=$(mktemp)
    git log --numstat --pretty="%H" --since="${year}-01-01 00:00" --until="${year}-12-31 23:59"  | egrep '(\d+\s+){2}' > $TMPFILE
    while read add sub ignore; do
        yearAdd=$((yearAdd+add))
        yearSub=$((yearSub+sub))
    done < $TMPFILE
    rm $TMPFILE
    total=$((total+yearAdd-yearSub))
    echo -e "$year\t$yearAdd\t-$yearSub\t$total"
done