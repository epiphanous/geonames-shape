#!/usr/bin/env bash

BASE=/export
MSQL="mysql --defaults-extra-file=$BASE/my.cnf ${MYSQL_DATABASE}"
UTF8="SET CHARSET utf8mb4"

dump_pages() {
  q=$1
  f=$2
  mkdir -p $f && rm -rf $f/* || exit $?
  d=$(echo "$q" | sed -e 's/^select .* from /delete from /')
  echo "f:   $f"
  echo "q:   $q"
  echo "d:   $d"
  lim=50000
  echo lim: $lim
  n=0
  foundSome=$lim
  k=1
  cmd=$MSQL
  while [ $foundSome -eq $lim ]
  do
    kx=$(printf "%03d" $k)
    echo "$UTF8; $q limit $lim" | $cmd > $f/$kx.txt
    cmd="$MSQL -N"
    foundSome=$(echo "$d limit $lim; select row_count();" | $cmd)
    let "n += $foundSome"
    let "k += 1"
    printf $'%8d\n' $n
  done
}

for t in country_info feature alt_name
do
  echo "exporting $t..."
  time (
    dump_pages "select * from $t" "$BASE/$t"
  )
done

echo "export done"
