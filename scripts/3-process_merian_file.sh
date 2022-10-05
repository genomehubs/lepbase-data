#!/bin/bash

YAML="sources/features/ATTR_merian.types.yaml"

mkdir -p $(dirname $YAML)

MERIANS=
TRANSLATE=
while read BUSCO STATUS MERIAN IGNORE; do
  TRANSLATE+=$(echo "      ${BUSCO}: ${MERIAN}\n")
  MERIANS+=$(echo "${MERIAN}\n")
done < <(tail -n +2 sources/raw_features/inferred_Merian_bySize_full_table.tsv)

ENUM=
while read MERIAN; do
  ENUM+=$(echo "        - ${MERIAN}\n")
done <<< "$(echo -e "${MERIANS%??}" | sort -Vu)"

echo "attributes:
  merian_unit:
    constraint:
      enum:" > $YAML
echo -e "${ENUM%??}" >> $YAML
echo "    description: Merian unit
    display_level: 2
    display_name: Merian unit
    display_group: ancestral unit
    type: keyword
    translate:" >> $YAML
echo -e "${TRANSLATE%??}" | sort -Vu >> $YAML