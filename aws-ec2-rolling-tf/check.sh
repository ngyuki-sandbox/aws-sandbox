#!/bin/bash

: ${1:?}

while sleep 1; do
    echo -n "$(date +%H:%M:%S): "
    curl -fsS ${1} 2>&1 | head -1
done
