#!/usr/bin/env bash

IMPORT=import
EXPORT=export
mkdir -p $IMPORT && rm -f $IMPORT/*.{sql,sh}
mkdir -p $EXPORT && rm -f $EXPORT/*.txt

download_data() {
  GN_BASE="http://download.geonames.org/export/dump"

  TXT="countryInfo.txt featureCodes_en.txt"
  ZIPS="alternateNamesV2.zip allCountries.zip"

  (
    cd $IMPORT
    for f in $TXT
    do
      wget -q -N --show-progress "$GN_BASE/$f"
    done

    for f in $ZIPS
    do
      wget -q -N --show-progress "$GN_BASE/$f" && unzip -u -o $f
    done
  )
}

convert_nulls() {
  awk -F $'\t' -f nulls.awk
}

fix_nulls() {
  for f in alternateNamesV2 allCountries
  do
    fn="$IMPORT/$f.txt"
    fnn="$IMPORT/${f}_nulls.txt"
    [ "$fn" -nt "$fnn" ] && cat "$fn" | convert_nulls > "$fnn"
    test -f "$fnn"
  done
}

gen_country_info() {
  sed -e '/^#/d' "$IMPORT/countryInfo.txt" | csvcut -t -H -c 1,5-15,17 | csvformat -K 1 -T | convert_nulls > "$IMPORT/country_info.txt"
  cp "$IMPORT/country_info.txt" $EXPORT
}

# gen straight to export
gen_country_language() {
  sed -e '/^#/d' "$IMPORT/countryInfo.txt" | csvcut -t -H -c 1,16 | csvformat -K 1 -T | awk -F $'\t' -f two_split_comma.awk | convert_nulls > "$EXPORT/country_language.txt"
}

# gen straight to export
gen_country_neighbour() {
  sed -e '/^#/d' "$IMPORT/countryInfo.txt" | csvcut -t -H -c 1,18 | csvformat -K 1 -T | awk -F $'\t' -f two_split_comma.awk | convert_nulls > "$EXPORT/country_neighbour.txt"
}

# gen straight to export
gen_feature_class_code() {
  {
    printf $'A\tAdministrative Regions\tcountry, state, region, ...\n'
    printf $'H\tHydrographic Features\tsea, river, lake, ...\n'
    printf $'L\tArea Features\tpark, area, ..\n'
    printf $'P\tPopulated Places\tcity, town, ...\n'
    printf $'R\tRoad/Railroad Features\tstreet, railroad, ...\n'
    printf $'S\tSpot Features\tairport, building, farm, ...\n'
    printf $'T\tHypsographic Features\tmountain, hill, rock, ...\n'
    printf $'U\tUndersea Features\tundersea features\n'
    printf $'V\tVegetation Features\tforest, heath, ...\n'
  } > "$EXPORT/feature_class_code.txt"
  sed -e 's/^[AHLPRSTUV]\.//' "$IMPORT/featureCodes_en.txt" | convert_nulls >> "$EXPORT/feature_class_code.txt"
}

# gen straight to export
gen_language() {
  {
    printf $'post\tpostal code\n'
    printf $'link\twebsite link\n'
    printf $'iata\tiata airport code\n'
    printf $'icao\ticao airport code\n'
    printf $'faac\tfaac airport code\n'
    printf $'abbr\tabbreviation\n'
    printf $'fr_1793\tname used during French Revolution\n' # wtf
  } > "$EXPORT/language.txt"
  sed -e '1d' "$IMPORT/iso-languagecodes.txt" | awk -F $'\t' -f language.awk | convert_nulls >> "$EXPORT/language.txt"
}

echo "downloading data"       && \
download_data                 && \
echo "fixing nulls"           && \
fix_nulls                     && \
echo "gen country info"       && \
gen_country_info              && \
echo "gen country language"   && \
gen_country_language          && \
echo "gen country neighbour"  && \
gen_country_neighbour         && \
echo "gen feature class code" && \
gen_feature_class_code        && \
echo "gen language"           && \
gen_language                  && \
echo "cp to import"           && \
cp -f my.cnf 001-load.sh 002-export.sh $IMPORT && \
echo "co to export"           && \
cp -f my.cnf $EXPORT          && \
echo "docker down"            && \
docker-compose down           && \
echo "docker up"              && \
docker-compose up             && \
echo "*** DONE BACKFILL ***" || echo "XXX ERROR XXX"
