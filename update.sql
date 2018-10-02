/*
  This script creates a temporary table, loads the allCountries into it, checks for differences between the current
  and the new table, updates the rows that need to be updated (checks their modification timestamps) then inserts
  new rows if any are present. Leverages on the previous `load.sql` script for determining parents etc
*/
use geonames;
drop table if exists temp_update_table;
create table temp_update_table(
  `gid` bigint not null,
  `name` varchar(200),
  `latitude` decimal(10,7),
  `longitude` decimal(10,7),
  `fclass` char(1),
  `fcode` varchar(10),
  `continent_code` char(2),
  `country_code` char(2),
  `admin1_code` varchar(20),
  `admin2_code` varchar(80),
  `admin3_code` varchar(20),
  `admin4_code` varchar(20),
  `parent_continent` bigint,
  `parent_country` bigint,
  `parent_admin1` bigint,
  `parent_admin2` bigint,
  `parent_admin3` bigint,
  `parent_admin4` bigint,
  `population` bigint,
  `elevation` int,
  `dem` int,
  `timezone` varchar(40),
  `mod_date` date,

  primary key (`gid`),
  key `fcode_key` (`fcode`),
  key `f_continent_code_key` (`continent_code`),
  key `f_country_code_key` (`country_code`),
  key `f_admin1_code_key` (`admin1_code`),
  key `f_admin2_code_key` (`admin2_code`),
  key `f_admin3_code_key` (`admin3_code`),
  key `f_admin4_code_key` (`admin4_code`)
) engine=innodb default charset=utf8mb4;


-- Consider using a memory engine and a temporary table for this, will be faster but will chew up RAM! (likely > 4GB)

begin;
load data local infile '/docker-entrypoint-initdb.d/allCountries.txt'
into table `temp_update_table`
(
  `gid`,
  `name`,
  @dummy,
  @dummy,
  `latitude`,
  `longitude`,
  `fclass`,
  `fcode`,
  `country_code`,
  @dummy,
  `admin1_code`,
  `admin2_code`,
  `admin3_code`,
  `admin4_code`,
  `population`,
  `elevation`,
  `dem`,
  `timezone`,
  `mod_date`
);
commit;

begin;
UPDATE feature f
INNER JOIN temp_update_table t ON (f.gid = t.gid)
SET f.name = t.name,
    f.latitude = t.latitude,
    f.longitude = t.longitude,
    f.fclass = t.fclass,
    f.fcode = t.fcode,
    f.country_code = t.country_code,
    f.admin1_code = t.admin1_code,
    f.admin2_code = t.admin2_code,
    f.admin3_code = t.admin3_code,
    f.admin4_code = t.admin4_code,
    f.population = t.population,
    f.elevation = t.elevation,
    f.dem = t.dem,
    f.timezone = t.timezone,
    f.mod_date = t.mod_date
where f.mod_date < t.mod_date;
commit;

begin;
delete t
from temp_update_table t
join feature f on t.gid = f.gid;
commit;

BEGIN;

-- set continent codes
update temp_update_table f join country_info ci on ci.country_code=f.country_code
set f.continent_code = ci.continent_code,
f.parent_country = ci.gid,
f.parent_continent =
  case ci.continent_code
    when 'AF' then 6255146
    when 'AS' then 6255147
    when 'EU' then 6255148
    when 'NA' then 6255149
    when 'OC' then 6255150
    when 'SA' then 6255151
    when 'AN' then 6255152
  end
;
COMMIT;
begin;
update temp_update_table fc
  join temp_update_table fp on fp.admin1_code=fc.admin1_code and fp.fcode='ADM1'
set fc.parent_admin1 = fp.gid
;

update temp_update_table fc
  join temp_update_table fp on fp.admin2_code=fc.admin2_code and fp.fcode='ADM2'
set fc.parent_admin2 = fp.gid
;

update temp_update_table fc
  join temp_update_table fp on fp.admin3_code=fc.admin3_code and fp.fcode='ADM3'
set fc.parent_admin3 = fp.gid
;

update temp_update_table fc
  join temp_update_table fp on fp.admin3_code=fc.admin3_code and fp.fcode='ADM4'
set fc.parent_admin4 = fp.gid
;


create table feature_parent as
select F.*,H.child_gid
from temp_update_table F join hierarchy H on H.parent_gid=F.gid
;

COMMIT;
BEGIN;

update temp_update_table FC join feature_parent FP on FC.gid = FP.child_gid
set
  FC.parent_continent = FP.gid,
  FC.continent_code = FP.continent_code
where FP.fcode = 'CONT'
;

COMMIT;
BEGIN;

drop table feature_parent;
create table feature_parent as
select F.*,H.child_gid
from temp_update_table F join hierarchy H on H.parent_gid=F.gid
;

COMMIT;
BEGIN;

update temp_update_table FC join feature_parent FP on FC.gid = FP.child_gid
set
  FC.parent_continent = FP.parent_continent,
  FC.continent_code = FP.continent_code,
  FC.parent_country = FP.gid
where FP.fcode = 'PCLI'
;

COMMIT;
BEGIN;
drop table feature_parent;
create table feature_parent as
select F.*,H.child_gid
from temp_update_table F join hierarchy H on H.parent_gid=F.gid
;

COMMIT;
BEGIN;

update temp_update_table FC join feature_parent FP on FC.gid = FP.child_gid
set
  FC.parent_continent = FP.parent_continent,
  FC.continent_code = FP.continent_code,
  FC.parent_country = FP.parent_country,
  FC.parent_admin1 = FP.gid
where FP.fcode = 'ADM1'
;

COMMIT;
BEGIN;

drop table feature_parent;
create table feature_parent as
select F.*,H.child_gid
from temp_update_table F join hierarchy H on H.parent_gid=F.gid
;

COMMIT;
BEGIN;

update temp_update_table FC join feature_parent FP on FC.gid = FP.child_gid
set
  FC.parent_continent = FP.parent_continent,
  FC.continent_code = FP.continent_code,
  FC.parent_country = FP.parent_country,
  FC.parent_admin1 = FP.parent_admin1,
  FC.parent_admin2 = FP.gid
where FP.fcode = 'ADM2'
;

COMMIT;
BEGIN;

drop table feature_parent;
create table feature_parent as
select F.*,H.child_gid
from temp_update_table F join hierarchy H on H.parent_gid=F.gid
;

COMMIT;
BEGIN;

update temp_update_table FC join feature_parent FP on FC.gid = FP.child_gid
set
  FC.parent_continent = FP.parent_continent,
  FC.continent_code = FP.continent_code,
  FC.parent_country = FP.parent_country,
  FC.parent_admin1 = FP.parent_admin1,
  FC.parent_admin2 = FP.parent_admin2,
  FC.parent_admin3 = FP.gid
where FP.fcode = 'ADM3'
;

COMMIT;
BEGIN;

drop table feature_parent;
create table feature_parent as
select F.*,H.child_gid
from temp_update_table F join hierarchy H on H.parent_gid=F.gid
;

COMMIT;
BEGIN;

update temp_update_table FC join feature_parent FP on FC.gid = FP.child_gid
set
  FC.parent_continent = FP.parent_continent,
  FC.continent_code = FP.continent_code,
  FC.parent_country = FP.parent_country,
  FC.parent_admin1 = FP.parent_admin1,
  FC.parent_admin2 = FP.parent_admin2,
  FC.parent_admin3 = FP.parent_admin3,
  FC.parent_admin4 = FP.gid
where FP.fcode = 'ADM4';

COMMIT;
BEGIN;

drop table feature_parent;
delete from hierarchy where `type`='ADM';

COMMIT;

-- finally, merge the tables
begin;
insert into feature select * from temp_update_table;
drop table temp_update_table;
commit;
