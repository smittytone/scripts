#!/bin/bash
if [ ! -f ${PWD}/.buildcount ]; then
    echo "BUILD_COUNT=1" > ${PWD}/.buildcount
else
    source ${PWD}/.buildcount
    BUILD_COUNT=$((BUILD_COUNT+1))
    echo "BUILD_COUNT=${BUILD_COUNT}" > ${PWD}/.buildcount
fi

