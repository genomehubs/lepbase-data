#!/bin/bash

# Run genomehubs import feature-dir
curl -X DELETE "http://localhost:9200/taxon-*"
curl -X DELETE "http://localhost:9200/a*"
curl -X DELETE "http://localhost:9200/f*"

genomehubs init \
    --config-file sources/lepbase.yaml \
    --taxonomy-source ncbi \
    --taxon-preload \
    --restore-indices &&

genomehubs index \
    --es-host http://localhost:9200 \
    --taxonomy-source ncbi \
    --config-file sources/lepbase.yaml \
    --assembly-dir sources/assembly-data

genomehubs index \
    --es-host http://localhost:9200 \
    --taxonomy-source ncbi \
    --config-file sources/lepbase.yaml \
    --feature-dir sources/features