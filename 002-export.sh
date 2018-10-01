#!/usr/bin/env bash

BASE=/export
MSQL="mysql --defaults-extra-file=$BASE/my.cnf -B ${MYSQL_DATABASE}"

for t in country_info country_language country_neighbour language feature_class_code feature
do
  echo "exporting $t..."
  time (
    echo "select * from $t" | $MSQL > "$BASE/$t.txt"
  )
done

echo "exporting alt_name..."
echo "select gid, code, name from alt_name where code not in ('link','fr_1793') and is_historic=0" | $MSQL > "$BASE/alt_name.txt"

echo "exporting links..."
echo "select gid, name as link from alt_name where code='link'" | $MSQL > "$BASE/link.txt"

echo "export done"
