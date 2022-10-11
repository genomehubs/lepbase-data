#!/bin/bash

# get info from config.yaml to make FILE_*.yaml files

BTK_DIR=sources/raw_features

for DIR in $(ls -d ${BTK_DIR}/*/); do
  BTK_ID=$(basename $DIR)
  SCAF_COUNT='"scaffold-count"'
  read -r ACCESSION LEVEL SPAN COUNT TAXID NAME <<< "$(yq -r '[.assembly.accession, .assembly.level, .assembly.span, .assembly.'${SCAF_COUNT}', .taxon.taxid, .taxon.name] | .[]' ${DIR}config.yaml | paste - - - - - -)"
  if [ $COUNT -gt 200 ]; then
    continue
  fi
  LINEAGES=$(yq -r '.busco.lineages | .[]' ${DIR}config.yaml)
  LIBRARIES=$(yq -r '[.reads.paired, .reads.single] | flatten(1) | select( .[] != null ) | map(.prefix) | .[]' ${DIR}config.yaml)
  TOP_LINEAGE=$(echo "$LINEAGES" | head -n 1)
  LIBRARY=$(echo "$LIBRARIES" | head -n 1)

  # turn chunks into windows
  btk pipeline window-stats \
      --window 10000 \
      --window 100000 \
      --window 1000000 \
      --window 0.02 \
      --window 0.05 \
      --window 0.1 \
      --min-window-length 1000 \
      --min-window-count 5 \
      --in "${DIR}/${BTK_ID}.chunk_stats.tsv.gz" \
      --out "${BTK_ID}.window_stats.tsv"
  
  for FILE in $(ls ${BTK_ID}.window_stats.*.tsv); do
    gzip -c $FILE > "sources/features/${FILE}.gz"
    rm $FILE
  done

  cp "${DIR}/${BTK_ID}.window_stats.tsv.gz" "sources/features/${BTK_ID}.window_stats.tsv.gz"

# write window_stats YAML

echo "file:
  format: tsv
  header: true
  name: ${BTK_ID}.window_stats.tsv.gz
  needs:
    - ATTR_feature.types.yaml
    - ATTR_window_stats.types.yaml
  source: BlobToolKit
  source_url: https://blobtoolkit.genomehubs.org/view/dataset/$BTK_ID
analysis:
  analysis_id: assembly-${ACCESSION}
  assembly_id: ${ACCESSION}
  taxon_id: \"${TAXID}\"
  description: Public assembly ${ACCESSION}
  name: Assembly
  title: Public assembly ${ACCESSION}
features:
  assembly_id: ${ACCESSION}
  feature_id:
    header: sequence
  primary_type: ${LEVEL}
taxonomy:
  taxon_id: \"$TAXID\"
attributes:
  sequence_id:
    header: sequence
  feature_type:
    default:
      - ${LEVEL}
      - toplevel
      - sequence
  start:
    header: start
    function: \"{} + 1\"
  end:
    header: end
  strand: 1
  length:
    header: end
  seq_proportion:
    header: end
    function: \"{} / ${SPAN}\"
  midpoint:
    header: end
    function: \"{length} / 2\"
  gc:
    header: gc
  masked:
    header: masked
  busco_count:
    header: ${TOP_LINEAGE}_count" > "sources/features/FILE_${BTK_ID}.window_stats.types.yaml"
if [ ! -z "$LIBRARY" ]; then
  echo "  coverage:
    header: ${LIBRARY}_cov
    function: \"{} + 0.01\"" >> "sources/features/FILE_${BTK_ID}.window_stats.types.yaml"
fi

for FILE in $(ls sources/features/${BTK_ID}.window_stats.*.tsv.gz); do
    WINDOW_FILE=$(basename ${FILE})
    WINDOW=$(perl -e 'my @parts = split(m[(?:window_stats\.|\.tsv\.gz)], "'${WINDOW_FILE}'"); print "$parts[1]";')

echo "file:
  format: tsv
  header: true
  name: ${WINDOW_FILE}
  needs:
    - ATTR_feature.types.yaml
    - ATTR_window_stats.types.yaml
    - FILE_${BTK_ID}.window_stats.types.yaml
  source: BlobToolKit
  source_url: https://blobtoolkit.genomehubs.org/view/dataset/$BTK_ID
analysis:
  analysis_id: assembly-${ACCESSION}-${WINDOW}
  assembly_id: ${ACCESSION}
  taxon_id: \"${TAXID}\"
  description: Public assembly ${ACCESSION} ${WINDOW} windows
  name: Assembly-${WINDOW}
  title: Public assembly ${ACCESSION} ${WINDOW}
features:
  assembly_id: ${ACCESSION}
  feature_id:
    header: sequence
    template: \"{}:{start}-{end}:window\"
  primary_type: window-${WINDOW}
taxonomy:
  taxon_id: \"$TAXID\"
attributes:
  sequence_id:
    header: sequence
  feature_type:
    default:
      - window-${WINDOW}
      - window
  start:
    header: start
    function: \"{} + 1\"
  end:
    header: end
  strand: 1
  length:
    header: start
    function: \"{end} - {}\"
  seq_proportion:
    header: sequence
    function: \"{length} / {.length}\"
  midpoint:
    header: end
    function: \"{length} / 2 + {start}\"
  midpoint_proportion:
    header: sequence
    function: \"{midpoint} / {.length}\"
  gc:
    header: gc
  masked:
    header: masked
  busco_count:
    header: ${TOP_LINEAGE}_count" > "sources/features/FILE_${BTK_ID}.window_stats.${WINDOW}.types.yaml"
if [ ! -z "$LIBRARY" ]; then
  echo "  coverage:
    header: ${LIBRARY}_cov
    function: \"{} + 0.01\"" >> "sources/features/FILE_${BTK_ID}.window_stats.${WINDOW}.types.yaml"
fi

done
# write busco YAMLs
while read LINEAGE; do

tar xOf "${DIR}/${BTK_ID}.busco.${LINEAGE}.tar" "${BTK_ID}.busco.${LINEAGE}/full_table.tsv.gz" > "sources/features/${BTK_ID}.${LINEAGE}.full_table.tsv.gz"

echo "file:
  format: tsv
  header: false
  name: ${BTK_ID}.${LINEAGE}.full_table.tsv.gz
  needs:
    - ATTR_busco.types.yaml
    - ATTR_merian.types.yaml
    - FILE_${BTK_ID}.window_stats.types.yaml
  source: BlobToolKit
  source_url: https://blobtoolkit.genomehubs.org/view/dataset/$BTK_ID
analysis:
  analysis_id: busco5-${LINEAGE}-${ACCESSION}
  assembly_id: ${ACCESSION}
  taxon_id: \"${TAXID}\"
  description: BUSCO v5 analysis of ${ACCESSION} using ${LINEAGE} lineage
  name: BUSCO_${LINEAGE}
  title: BUSCO v5 ${ACCESSION} ${LINEAGE}
features:
  assembly_id: ${ACCESSION}
  feature_id:
    index: 2
    separator:
      - \":\"
    limit: 1
    template: \"{}:{start}-{end}:{busco_gene}\"
  primary_type: busco-gene
taxonomy:
  taxon_id: \"$TAXID\"
attributes:
  sequence_id:
    index: 2
    separator:
      - \":\"
    limit: 1
  feature_type:
    default:
      - busco-gene
      - gene
  start:
    index: 3
  end:
    index: 4
  strand:
    index: 5
    translate:
      \"-\": -1
      \"+\": 1
  length:
    index: 7
  midpoint:
    index: 3
    function: \"{length} / 2 + {}\"
  midpoint_proportion:
    index: 2
    separator:
      - \":\"
    limit: 1
    function: \"{midpoint} / {.length}\"
  busco_gene:
    index: 0
  busco_status:
    index: 1
  busco_score:
    index: 6
  analysis_name:
    default: BUSCO_${LINEAGE}" > "sources/features/FILE_${BTK_ID}.busco.${LINEAGE}.types.yaml"
if [ "$LINEAGE" == "$TOP_LINEAGE" ]; then
  echo "  merian_unit:
    index: 0" >> "sources/features/FILE_${BTK_ID}.busco.${LINEAGE}.types.yaml"
fi
done <<< "${LINEAGES}"
if [ "$BTK_ID" == "CADCXM01" ]; then
  break
fi
done