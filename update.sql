use geonames;
drop table if exists temp_update_table;
create temporary table temp_update_table(
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

-- Consider using a memory engine for this, will be faster but will chew up RAM! (likely > 4GB)


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

drop table temp_update_table;

-- We'd reallocate the RAM here if we used a memory engine for the temp table
