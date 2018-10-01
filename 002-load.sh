#!/usr/bin/env bash

BASE=/docker-entrypoint-initdb.d
#MSQL="mysql -h localhost --user=root --password=123 ${MYSQL_DATABASE}"
MSQL=cat

for t in feature_class_code country_info country_neighbour language hierarchy
do
  echo "loading $t"
  time (echo "load data local infile '$BASE/$t.txt' into table $t character set 'utf8'" | $MSQL) || exit $?
done

echo "loading alternateNamesV2"
(
  time $MSQL<<EOF
load data local infile '$BASE/alternateNamesV2.txt'
into table alt_name
  (id,gid,code,name,is_preferred,is_short,is_colloquial,is_historic)
EOF
) || exit $?

echo "loading allCountries"
(
  time $MSQL <<EOF
load data local infile '$BASE/allCountries.txt'
into table feature
(gid, name, @dummy, @dummy,
 latitude, longitude, fclass, fcode, country_code, @dummy,
 admin1_code, admin2_code, admin3_code, admin4_code, population,
 elevation, dem, timezone, mod_date)
EOF
) || exit $?

echo 'update continent codes for continent features'
(
  time $MSQL <<EOF
update feature set continent_code = 'AF' where gid = 6255146;
update feature set continent_code = 'AS' where gid = 6255147;
update feature set continent_code = 'EU' where gid = 6255148;
update feature set continent_code = 'NA' where gid = 6255149;
update feature set continent_code = 'OC' where gid = 6255150;
update feature set continent_code = 'SA' where gid = 6255151;
update feature set continent_code = 'AN' where gid = 6255152;
EOF
) || exit $?

echo 'set continent codes, parent continents and countries'
(
  time $MSQL <<EOF
set max_heap_table_size=128*1024*1024;

CREATE TABLE fp (
  country_code char(2) primary key,
  continent_code char(2),
  country_gid bigint,
  continent_gid bigint
) engine=memory
AS
SELECT country_code, continent_code, gid as country_gid,
  CASE continent_code
    WHEN 'AF' then 6255146
    WHEN 'AS' then 6255147
    WHEN 'EU' then 6255148
    WHEN 'NA' then 6255149
    WHEN 'OC' then 6255150
    WHEN 'SA' then 6255151
    WHEN 'AN' then 6255152
    ELSE null
  END as continent_gid
FROM country_info;

UPDATE feature fc JOIN fp USING (country_code)
  SET fc.continent_code = fp.continent_code,
      fc.parent_continent = fp.continent_gid,
      fc.parent_country = fp.country_gid
;
drop table fp;
EOF
) || exit $?

function join_by { local IFS="$1"; shift; echo "$*"; }

keys=(country_code)
keyDefs=("country_code:char(2)")

for a in 1 2 3 4
do
  echo "set admin$a parents..."
  clen=20
  [[ $a = 2 ]] && clen=80
  keys+=("admin${a}_code")
  keyDefs+=("admin${a}_code:varchar($clen)")
  cols=$(join_by , ${keys[@]})
  defs=$(join_by , ${keyDefs[@]} | sed -e 's/:/ /g')

  (
    time $MSQL <<EOF
set max_heap_table_size=128*1024*1024;

create table fp ($defs, gid bigint, primary key fp_pk ($cols)) engine=memory
as select $cols, gid from feature where fcode='ADM$a';

update feature fc join fp using ($cols)
set fc.parent_admin$a = fp.gid;

drop table fp;
EOF
    ) || exit $?
done

echo DONE
