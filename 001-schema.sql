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
) engine=myisam default charset=utf8mb4 ;

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
) engine=myisam default charset=utf8mb4 ;

create table `country_language` (
  `country_code` char(2) not null,
  `lang_code` varchar(7) not null,
  primary key (`country_code`, `lang_code`)
) engine=myisam default charset=utf8mb4;

create table `country_neighbour` (
  `country_code` char(2) not null,
  `neighbour_code` char(2) not null,
  primary key (`country_code`, `neighbour_code`)
) engine=myisam default charset=utf8mb4;

create table `feature_class_code` (
  `code` char(7) not null,
  `name` varchar(200) not null,
  `description` text,
  primary key `code` (`code`)
) engine=myisam default charset=utf8mb4 ;

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
) engine=myisam default charset=utf8mb4 ;

create table `hierarchy` (
  `parent_gid` bigint not null,
  `child_gid` bigint not null,
  `type` varchar(10) not null,
  key `h_parent_gid_key` (`parent_gid`),
  key `h_child_gid_key` (`child_gid`),
  key `h_type_key` (`type`)
) engine=myisam default charset=utf8mb4 ;

create table `language` (
  `lang_code` varchar(7) primary key,
  `name` varchar(200) not null
) engine=myisam default charset=utf8mb4 ;
