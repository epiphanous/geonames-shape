#!/usr/bin/env bash

BASE=/export
MSQL="mysql --defaults-extra-file=$BASE/my.cnf -B ${MYSQL_DATABASE}"

dump_pages() {
  q=$1
  d=$(echo "$q" | sed -e 's/^select .* from /delete from /')
  lim=10000
  n=0
  cmd=$MSQL
  foundSome=$lim
  while [ $foundSome -eq $lim ]
  do
    echo "$q limit $lim" | $cmd
    cmd="$MSQL -N"
    foundSome=$(echo "$d limit $lim; select row_count();" | $cmd)
    let "n += $foundSome"
    (>&2 echo $n)
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
