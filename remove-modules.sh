#!/usr/bin/env bash
cp Makefile Makefile.bak
for line in $(grep -n "PatternGrammar" Makefile | cut -d: -f1 | tac)
do
    if [ $line -gt 15 ]; then
        sed -i "$((line-15)),${line}d" Makefile
    else
        sed -i "1,${line}d" Makefile
    fi
done
