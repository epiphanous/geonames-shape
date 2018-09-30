drop database if exists geonames;
create database geonames default character set utf8mb4 ;
use geonames;

--
-- schema
--
create table `alt_name` (
  `id` bigint not null,
  `gid` bigint not null,
  `code` varchar(7),
  `name` varchar(400) not null,
  `is_preferred` tinyint(1),
  `is_short` tinyint(1),
  `is_colloquial` tinyint(1),
  `is_historic` tinyint(1),
  primary key (`id`)
) engine=innodb default charset=utf8mb4 ;

-- create syntax for table 'countryinfo'
create table `country_info` (
  `country_code` char(2),
  `name` varchar(200),
  `capital` varchar(200),
  `area` double,
  `population` bigint,
  `continent_code` char(2),
  `tld` char(3),
  `currency_code` char(3),
  `currencyname` char(20),
  `phone` char(10),
  `postalcodeformat` varchar(100),
  `postalcoderegex` varchar(255),
  `gid` bigint,
  primary key (`country_code`),
  key `ci_continent_code_key` (`continent_code`),
  unique key `ci_gid_ukey` (`gid`)
) engine=innodb default charset=utf8mb4 ;

create table `country_language` (
  `country_code` char(2) not null,
  `lang_code` varchar(7) not null,
  primary key (`country_code`, `lang_code`)
) engine=innodb default charset=utf8mb4;

create table `country_neighbour` (
  `country_code` char(2) not null,
  `neighbour_code` char(2) not null,
  primary key (`country_code`, `neighbour_code`)
) engine=innodb default charset=utf8mb4;

create table `feature_class_code` (
  `code` char(7) not null,
  `name` varchar(200) not null,
  `description` text,
  primary key `code` (`code`)
) engine=innodb default charset=utf8mb4 ;

create table `feature` (
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
  `parent_admin1` bigint, -- foreign keys
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
) engine=innodb default charset=utf8mb4 ;

create table `hierarchy` (
  `parent_gid` bigint not null,
  `child_gid` bigint not null,
  `type` varchar(10) not null,
  key `h_parent_gid_key` (`parent_gid`),
  key `h_child_gid_key` (`child_gid`),
  key `h_type_key` (`type`)
) engine=innodb default charset=utf8mb4 ;

create table `language` (
  `lang_code` varchar(7) primary key,
  `name` varchar(200) not null
) engine=innodb default charset=utf8mb4 ;

set autocommit=0;
BEGIN;

--
-- feature codes
--
load data local infile '/docker-entrypoint-initdb.d/feature_class_code.txt'
into table `feature_class_code`
character set 'utf8';

COMMIT;
BEGIN;

--
-- load country info
--
load data local infile '/docker-entrypoint-initdb.d/country_info.txt'
into table `country_info`
character set 'utf8';

COMMIT;
BEGIN;

load data local infile '/docker-entrypoint-initdb.d/country_language.txt'
into table `country_language`
character set 'utf8';

COMMIT;
BEGIN;

load data local infile '/docker-entrypoint-initdb.d/country_neighbour.txt'
into table `country_neighbour`
character set 'utf8';

COMMIT;
BEGIN;

--
-- load language codes
--
load data local infile '/docker-entrypoint-initdb.d/language.txt'
into table `language`
character set 'utf8';

COMMIT;
BEGIN;

--
-- load alt names
--
load data local infile '/docker-entrypoint-initdb.d/alternateNamesV2.txt'
into table `alt_name`
(`id`,`gid`,`code`,`name`,`is_preferred`,`is_short`,`is_colloquial`,`is_historic`)
-- character set 'utf8'
;

COMMIT;
BEGIN;

--
-- load features
--
load data local infile '/docker-entrypoint-initdb.d/allCountries.txt'
into table `feature`
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
)
-- character set 'utf8'
;

COMMIT;
BEGIN;

--
-- load hierarchy
--
load data local infile '/docker-entrypoint-initdb.d/hierarchy.txt'
into table `hierarchy`
character set 'utf8';

COMMIT;
BEGIN;

-- add continent codes to continent features
update feature set continent_code = 'AF' where gid = 6255146;
update feature set continent_code = 'AS' where gid = 6255147;
update feature set continent_code = 'EU' where gid = 6255148;
update feature set continent_code = 'NA' where gid = 6255149;
update feature set continent_code = 'OC' where gid = 6255150;
update feature set continent_code = 'SA' where gid = 6255151;
update feature set continent_code = 'AN' where gid = 6255152;

COMMIT;
BEGIN;

-- set continent codes, parent continents and countries
update feature f join country_info ci on ci.country_code=f.country_code
set f.continent_code = ci.continent_code
set f.parent_country = ci.gid
set f.parent_continent =
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
BEGIN;

-- set adm1 parents
update feature fc
  join feature fp on fp.admin1_code=fc.admin1_code and fp.fcode='ADM1'
set fc.parent_admin1 = fp.gid
;

COMMIT;
BEGIN;

-- set adm2 parents
update feature fc
  join feature fp on fp.admin2_code=fc.admin2_code and fp.fcode='ADM2'
set fc.parent_admin2 = fp.gid
;

COMMIT;
BEGIN;

-- set adm3 parents
update feature fc
  join feature fp on fp.admin3_code=fc.admin3_code and fp.fcode='ADM3'
set fc.parent_admin3 = fp.gid
;

COMMIT;
BEGIN;

-- set adm4 parents
update feature fc
  join feature fp on fp.admin3_code=fc.admin3_code and fp.fcode='ADM4'
set fc.parent_admin4 = fp.gid
;

COMMIT;
