#!/usr/bin/env bash

IMPORT=import
EXPORT=export
mkdir -p $IMPORT
mkdir -p $EXPORT

download_data() {
  GN_BASE="http://download.geonames.org/export/dump"

  TXT="countryInfo.txt featureCodes_en.txt"
  ZIPS="alternateNamesV2.zip allCountries.zip hierarchy.zip"

  (
    cd $IMPORT
    for f in $TXT
    do
      wget -q -N --show-progress "$GN_BASE/$f"
    done

    for f in $ZIPS
    do
      wget -q -N --show-progress "$GN_BASE/$f" && unzip -o $f
    done
  )
}

gen_country_info() {
  sed -e '/^#/d' "$IMPORT/countryInfo.txt" | csvcut -t -H -c 1,5-15,17 | csvformat -K 1 -T > "$IMPORT/country_info.txt"
}

gen_country_language() {
  sed -e '/^#/d' "$IMPORT/countryInfo.txt" | csvcut -t -H -c 1,16 | csvformat -K 1 -T | awk -F '\t' -f two_split_comma.awk > "$IMPORT/country_language.txt"
}

gen_country_neighbour() {
  sed -e '/^#/d' "$IMPORT/countryInfo.txt" | csvcut -t -H -c 1,18 | csvformat -K 1 -T | awk -F '\t' -f two_split_comma.awk > "$IMPORT/country_neighbour.txt"
}

gen_feature_class_code() {
  {
    printf "A\tAdministrative Regions\tcountry, state, region, ...\n"
    printf "H\tHydrographic Features\tsea, river, lake, ...\n"
    printf "L\tArea Features\tpark, area, ..\n"
    printf "P\tPopulated Places\tcity, town, ...\n"
    printf "R\tRoad/Railroad Features\tstreet, railroad, ...\n"
    printf "S\tSpot Features\tairport, building, farm, ...\n"
    printf "T\tHypsographic Features\tmountain, hill, rock, ...\n"
    printf "U\tUndersea Features\tundersea features\n"
    printf "V\tVegetation Features\tforest, heath, ...\n"
  } > "$IMPORT/feature_class_code.txt"
  sed -e 's/^[AHLPRSTUV]\.//' "$IMPORT/featureCodes_en.txt" >> "$IMPORT/feature_class_code.txt"
}

gen_language() {
  {
    printf "post\tpostal code\n"
    printf "link\twebsite link\n"
    printf "iata\tiata airport code\n"
    printf "icao\ticao airport code\n"
    printf "faac\tfaac airport code\n"
    printf "abbr\tabbreviation\n"
    printf "fr_1793\tname used during French Revolution\n" # wtf?
  } > "$IMPORT/language.txt"
  sed -e '1d' "$IMPORT/iso-languagecodes.txt" | awk -F '\t' -f language.awk >> "$IMPORT/language.txt"
}

download_data          && \
gen_country_info       && \
gen_country_language   && \
gen_country_neighbour  && \
gen_feature_class_code && \
gen_language           &&  \
echo "DONE"


