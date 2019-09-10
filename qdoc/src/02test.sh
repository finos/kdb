#!/bin/bash -eux

BIN=../install/bin

QDOC_EX=qdoc_example
QTABLEDOC_EX=qtabledoc_example

# Path for NaturalDocs 1.x goes here.
#NATURAL_DOCS_1_DIR=

PATH="${NATURAL_DOCS_1_DIR}":"$PATH"

"$BIN"/qdoc "$QDOC_EX" "$QDOC_EX"_out

"$BIN"/qtabledoc --verbose \
    -title 'SA Tables' \
    -about "$QTABLEDOC_EX"/bovespa_desc.txt \
    -outdir "$QTABLEDOC_EX"_out \
    "$QTABLEDOC_EX"/*.q

