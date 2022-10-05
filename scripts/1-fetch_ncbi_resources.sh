#!/bin/bash

# Download NCBI datasets executable
curl https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/LATEST/mac/datasets > datasets
chmod a+x datasets

# Download NCBI Amphiesmenoptera datasets zip
mkdir -p sources/assembly-data
./datasets download genome taxon "Amphiesmenoptera" \
   --no-progressbar \
   --dehydrated \
   --filename sources/assembly-data/Amphiesmenoptera.zip

# Unzip NCBI Amphiesmenoptera datasets zip
unzip -o -d sources/assembly-data \
   sources/assembly-data/Amphiesmenoptera.zip \
   ncbi_dataset/data/assembly_data_report.jsonl

# Parse NCBI Amphiesmenoptera datasets
genomehubs parse --ncbi-datasets-genome sources/assembly-data \
   --outfile sources/assembly-data/ncbi_datasets_Amphiesmenoptera.tsv.gz

# Clean up expanded ncbi datasets zip
rm -rf sources/assembly-data/ncbi_dataset \
   sources/assembly-data/Amphiesmenoptera.zip \
   datasets

# Delete existing indices
curl -X DELETE "http://localhost:9200/*"

# Run genomehubs init
genomehubs init \
    --es-host http://localhost:9200 \
    --taxonomy-source ncbi \
    --config-file sources/lepbase.yaml \
    --taxonomy-ncbi-root 85604 \
    --taxon-preload

# Run genomehubs index assembly assembly-data
genomehubs index \
    --es-host http://localhost:9200 \
    --taxonomy-source ncbi \
    --config-file sources/lepbase.yaml \
    --assembly-dir sources/assembly-data