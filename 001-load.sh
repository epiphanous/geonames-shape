#!/usr/bin/env bash

BASE=/docker-entrypoint-initdb.d
MSQL="mysql --defaults-extra-file=$BASE/my.cnf ${MYSQL_DATABASE}"

# schema
echo "creating schema..."
(
  time $MSQL<<EOF
create table alt_name (
  id bigint not null,
  gid bigint not null,
  code varchar(7),
  name varchar(400) not null,
  is_preferred tinyint(1) not null default 0,
  is_short tinyint(1) not null default 0,
  is_colloquial tinyint(1) not null default 0,
  is_historic tinyint(1) not null default 0,
  primary key (id),
  key an_code (code),
  key an_historic (is_historic)
) engine=myisam default charset=utf8mb4 ;

create table country_info (
  country_code char(2) not null,
  name varchar(200),
  capital varchar(200),
  area double,
  population bigint,
  continent_code char(2),
  tld char(3),
  currency_code char(3),
  currencyname char(20),
  phone varchar(20),
  postalcodeformat varchar(100),
  postalcoderegex varchar(255),
  gid bigint,
  primary key (country_code),
  key ci_continent_code_key (continent_code),
  unique key ci_gid_ukey (gid)
) engine=myisam default charset=utf8mb4 ;

create table feature (
  gid bigint not null,
  name varchar(200),
  latitude decimal(10,7),
  longitude decimal(10,7),
  fclass char(1),
  fcode varchar(10),
  continent_code char(2) not null default '',
  country_code char(2) not null default '',
  admin1_code varchar(20) not null default '',
  admin2_code varchar(80) not null default '',
  admin3_code varchar(20) not null default '',
  admin4_code varchar(20) not null default '',
  parent_continent bigint,
  parent_country bigint,
  parent_admin1 bigint,
  parent_admin2 bigint,
  parent_admin3 bigint,
  parent_admin4 bigint,
  population bigint,
  elevation int,
  dem int,
  timezone varchar(40),
  mod_date date,

  primary key (gid),
  key fcode_key (fcode),
  key f_continent_code_key (continent_code),
  key f_country_code_key (country_code),
  key f_admin1_code_key (admin1_code),
  key f_admin2_code_key (admin2_code),
  key f_admin3_code_key (admin3_code),
  key f_admin4_code_key (admin4_code)
) engine=myisam default charset=utf8mb4 ;

EOF
) || exit $?

echo "loading country_info..."
time (echo "load data local infile '$BASE/country_info.txt' into table country_info character set 'utf8mb4'" | $MSQL) || exit $?

echo "loading alternateNamesV2"
(
  time $MSQL<<EOF
load data local infile '$BASE/alternateNamesV2_nulls.txt'
  into table alt_name character set 'utf8mb4'
  (id,gid,code,name,is_preferred,is_short,is_colloquial,is_historic)
EOF
) || exit $?

echo "loading allCountries"
(
  time $MSQL <<EOF
load data local infile '$BASE/allCountries_nulls.txt'
  into table feature character set 'utf8mb4'
  (gid, name, @dummy, @dummy, latitude, longitude, fclass, fcode,
  country_code, @dummy, admin1_code, admin2_code, admin3_code,
  admin4_code, population, elevation, dem, timezone, mod_date)
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

DROP TABLE fp;
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
