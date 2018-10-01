#!/usr/bin/env bash

BASE=/export
MSQL="mysql --defaults-extra-file=$BASE/my.cnf -B ${MYSQL_DATABASE}"

rowCount() {
  q="$*"
  cq=$(echo "$q" | sed -e 's/^.* from /select count(*) from /')
  # (>&2 echo "running: $cq")
  echo "$cq" | $MSQL -N
}

dump_pages() {
  q=$1
  ps=25000
  p=0
  n=$(rowCount $q)
  # (>&2 echo "$n rows from $q")
  offset=0
  cmd=$MSQL
  while [ $((n - offset)) -ge 0 ]
  do
    (>&2 echo $offset)
    echo "$q limit $offset, $ps" | $cmd
    ((offset += ps))
    cmd="$MSQL -N"
  done
}

for t in country_info feature
do
  echo "exporting $t..."
  time (
    dump_pages "select * from $t" > "$BASE/$t.txt"
  )
done

echo "exporting alt_name..."
time (
  dump_pages "select gid, code, name from alt_name where code not in ('link','fr_1793') and is_historic=0" > "$BASE/alt_name.txt"
)

echo "exporting links..."
time (
  dump_pages "select gid, name as link from alt_name where code='link'" > "$BASE/link.txt"
)

echo "export done"
