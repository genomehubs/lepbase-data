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

# write window_stats YAML
echo "file:
  format: tsv
  header: false
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
# write busco YAMLs
while read LINEAGE; do
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
    template: \"{}:{start}-{end}\"
  primary_type: busco-gene
taxonomy:
  taxon_id: \"$TAXID\"
attributes:
  sequence_id:
    index: 2
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
if [ "$ID" == "CADCXM01" ]; then
  break
fi
done