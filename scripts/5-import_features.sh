#!/bin/bash

# Run genomehubs import feature-dir

genomehubs index \
    --es-host http://localhost:9200 \
    --taxonomy-source ncbi \
    --config-file sources/lepbase.yaml \
    --feature-dir sources/features