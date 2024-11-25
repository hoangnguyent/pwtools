-- MySQL dump 10.18  Distrib 10.3.27-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: pw
-- ------------------------------------------------------
-- Server version	10.3.27-MariaDB-0+deb10u1

DROP DATABASE IF EXISTS pw;

CREATE DATABASE pw CHARACTER SET utf8 COLLATE utf8_general_ci;

use pw;

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auth`
--

DROP TABLE IF EXISTS `auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth` (
  `userid` int(11) NOT NULL DEFAULT 0,
  `zoneid` int(11) NOT NULL DEFAULT 0,
  `rid` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`userid`,`zoneid`,`rid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `files`
--

DROP TABLE IF EXISTS `files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `files` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `added` int(11) NOT NULL,
  `size` bigint(20) NOT NULL,
  `revision` int(4) NOT NULL,
  `md5` varchar(32) NOT NULL,
  `type` enum('element','launcher','patcher') NOT NULL DEFAULT 'element',
  `folder` varchar(1024) NOT NULL,
  `folder_base64` varchar(1024) NOT NULL,
  `file` varchar(512) NOT NULL,
  `file_base64` varchar(512) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `forbid`
--

DROP TABLE IF EXISTS `forbid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `forbid` (
  `userid` int(11) NOT NULL DEFAULT 0,
  `type` int(11) NOT NULL DEFAULT 0,
  `ctime` datetime NOT NULL,
  `forbid_time` int(11) NOT NULL DEFAULT 0,
  `reason` blob NOT NULL,
  `gmroleid` int(11) DEFAULT 0,
  PRIMARY KEY (`userid`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `iplimit`
--

DROP TABLE IF EXISTS `iplimit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `iplimit` (
  `uid` int(11) NOT NULL DEFAULT 0,
  `ipaddr1` int(11) DEFAULT 0,
  `ipmask1` varchar(2) DEFAULT '',
  `ipaddr2` int(11) DEFAULT 0,
  `ipmask2` varchar(2) DEFAULT '',
  `ipaddr3` int(11) DEFAULT 0,
  `ipmask3` varchar(2) DEFAULT '',
  `enable` char(1) DEFAULT '',
  `lockstatus` char(1) DEFAULT '',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `online`
--

DROP TABLE IF EXISTS `online`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `online` (
  `ID` int(11) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `point`
--

DROP TABLE IF EXISTS `point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `point` (
  `uid` int(11) NOT NULL DEFAULT 0,
  `aid` int(11) NOT NULL DEFAULT 0,
  `time` int(11) NOT NULL DEFAULT 0,
  `zoneid` int(11) DEFAULT 0,
  `zonelocalid` int(11) DEFAULT 0,
  `accountstart` datetime DEFAULT NULL,
  `lastlogin` datetime DEFAULT NULL,
  `enddate` datetime DEFAULT NULL,
  PRIMARY KEY (`uid`,`aid`),
  KEY `IX_point_aidzoneid` (`aid`,`zoneid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `account_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `role_name` varchar(64) NOT NULL,
  `role_level` smallint(6) NOT NULL,
  `role_race` tinyint(4) NOT NULL,
  `role_occupation` tinyint(4) NOT NULL,
  `role_gender` tinyint(4) NOT NULL,
  `role_spouse` int(11) NOT NULL,
  `faction_id` int(11) NOT NULL,
  `faction_name` varchar(64) NOT NULL,
  `faction_level` int(11) NOT NULL,
  `faction_domains` varchar(132) NOT NULL,
  `role_faction_rank` int(11) NOT NULL,
  `pvp_time` int(11) NOT NULL,
  `pvp_kills` int(11) NOT NULL,
  `pvp_deads` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usecashlog`
--

DROP TABLE IF EXISTS `usecashlog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usecashlog` (
  `userid` int(11) NOT NULL DEFAULT 0,
  `zoneid` int(11) NOT NULL DEFAULT 0,
  `sn` int(11) NOT NULL DEFAULT 0,
  `aid` int(11) NOT NULL DEFAULT 0,
  `point` int(11) NOT NULL DEFAULT 0,
  `cash` int(11) NOT NULL DEFAULT 0,
  `status` int(11) NOT NULL DEFAULT 0,
  `creatime` datetime NOT NULL,
  `fintime` datetime NOT NULL,
  KEY `IX_usecashlog_creatime` (`creatime`),
  KEY `IX_usecashlog_uzs` (`userid`,`zoneid`,`sn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usecashnow`
--

DROP TABLE IF EXISTS `usecashnow`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usecashnow` (
  `userid` int(11) NOT NULL DEFAULT 0,
  `zoneid` int(11) NOT NULL DEFAULT 0,
  `sn` int(11) NOT NULL DEFAULT 0,
  `aid` int(11) NOT NULL DEFAULT 0,
  `point` int(11) NOT NULL DEFAULT 0,
  `cash` int(11) NOT NULL DEFAULT 0,
  `status` int(11) NOT NULL DEFAULT 0,
  `creatime` datetime NOT NULL,
  PRIMARY KEY (`userid`,`zoneid`,`sn`),
  KEY `IX_usecashnow_creatime` (`creatime`),
  KEY `IX_usecashnow_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `ID` int(11) NOT NULL DEFAULT 0,
  `name` varchar(32) NOT NULL DEFAULT '',
  `passwd` varchar(64) NOT NULL,
  `Prompt` varchar(32) NOT NULL DEFAULT '',
  `answer` varchar(32) NOT NULL DEFAULT '',
  `truename` varchar(32) NOT NULL DEFAULT '',
  `idnumber` varchar(32) NOT NULL DEFAULT '',
  `email` varchar(64) NOT NULL DEFAULT '',
  `mobilenumber` varchar(32) DEFAULT '',
  `province` varchar(32) DEFAULT '',
  `city` varchar(32) DEFAULT '',
  `phonenumber` varchar(32) DEFAULT '',
  `address` varchar(64) DEFAULT '',
  `postalcode` varchar(8) DEFAULT '',
  `gender` int(11) DEFAULT 0,
  `birthday` datetime DEFAULT NULL,
  `creatime` datetime NOT NULL,
  `qq` varchar(32) DEFAULT '',
  `passwd2` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `IX_users_name` (`name`),
  KEY `IX_users_creatime` (`creatime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `uwebplayers`
--

DROP TABLE IF EXISTS `uwebplayers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `uwebplayers` (
  `roleid` int(11) NOT NULL,
  `rolename` varchar(50) DEFAULT NULL,
  `rolelevel` int(11) DEFAULT NULL,
  `rolestatus` int(11) DEFAULT NULL,
  `rolegender` int(11) DEFAULT NULL,
  `roleprof` bigint(20) DEFAULT NULL,
  `rolerep` bigint(20) DEFAULT NULL,
  `redname` bigint(20) DEFAULT NULL,
  `rednametime` bigint(20) DEFAULT NULL,
  `pinknametime` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`roleid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `webshop`
--

DROP TABLE IF EXISTS `webshop`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `webshop` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pcst` int(11) NOT NULL,
  `gcst` int(11) NOT NULL,
  `itit` varchar(64) NOT NULL,
  `idsc` varchar(255) NOT NULL,
  `cats` varchar(5) NOT NULL,
  `iname` varchar(64) NOT NULL,
  `idate` datetime NOT NULL,
  `itmid` int(11) NOT NULL,
  `imask` int(11) NOT NULL,
  `iproc` int(10) unsigned NOT NULL,
  `iqty` int(10) unsigned NOT NULL,
  `imax` int(10) unsigned NOT NULL,
  `guid1` int(10) unsigned NOT NULL,
  `guid2` int(10) unsigned NOT NULL,
  `expir` int(10) unsigned NOT NULL,
  `octet` varchar(8095) NOT NULL,
  `wscat` varchar(10) NOT NULL,
  `icol` tinyint(4) NOT NULL,
  `igrd` int(11) NOT NULL,
  `stim` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wshoplog`
--

DROP TABLE IF EXISTS `wshoplog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wshoplog` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `uname` varchar(50) NOT NULL,
  `role` int(10) unsigned NOT NULL,
  `rname` varchar(50) NOT NULL,
  `buydate` datetime NOT NULL,
  `currency` tinyint(4) NOT NULL,
  `price` int(11) NOT NULL,
  `amount` int(10) unsigned NOT NULL,
  `idata` varchar(8500) NOT NULL,
  `shopid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'pw'
--
/*!50003 DROP PROCEDURE IF EXISTS `acquireuserpasswd` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `acquireuserpasswd`(in name1 VARCHAR(64), out uid1 INTEGER, out passwd1 VARCHAR(64))
BEGIN
    SELECT id, passwd INTO uid1, passwd1 FROM users WHERE name = name1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `addForbid` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addForbid`(in userid1 INTEGER, in type1 INTEGER, in forbid_time1 INTEGER, in reason1 BINARY(255), in gmroleid1 INTEGER)
BEGIN
 DECLARE rowcount INTEGER;
  START TRANSACTION;
    UPDATE forbid SET ctime = now(), forbid_time = forbid_time1, reason = reason1, gmroleid = gmroleid1 WHERE userid = userid1 AND type = type1;
    SET rowcount = ROW_COUNT();
    IF rowcount = 0 THEN
      INSERT INTO forbid VALUES(userid1, type1, now(), forbid_time1, reason1, gmroleid);
    END IF;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `addGM` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addGM`(in userid INTEGER, in zoneid INTEGER)
BEGIN
  DECLARE x INTEGER;
  START TRANSACTION;
    SET x = 0;
    WHILE x < 12 DO
      INSERT INTO auth VALUES (userid, zoneid, x);
      SET x = x + 1;
    END WHILE;
    SET x = 100;
    WHILE x < 106 DO
      INSERT INTO auth VALUES (userid, zoneid, x);
      SET x = x + 1;
    END WHILE;
    SET x = 200;
    WHILE x < 215 DO
      INSERT INTO auth VALUES (userid, zoneid, x);
      SET x = x + 1;
    END WHILE;
    SET x = 500;
    WHILE x < 519 DO
      INSERT INTO auth VALUES (userid, zoneid, x);
      SET x = x + 1;
    END WHILE;
  COMMIT;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `adduser`(IN `name1` VARCHAR(64), IN `passwd1` VARCHAR(64), IN `prompt1` VARCHAR(32), IN `answer1` VARCHAR(32), IN `truename1` VARCHAR(32), IN `idnumber1` VARCHAR(32), IN `email1` VARCHAR(32), IN `mobilenumber1` VARCHAR(32), IN `province1` VARCHAR(32), IN `city1` VARCHAR(32), IN `phonenumber1` VARCHAR(32), IN `address1` VARCHAR(64), IN `postalcode1` VARCHAR(8), IN `gender1` INT, IN `birthday1` VARCHAR(32), IN `qq1` VARCHAR(32), IN `passwd21` VARCHAR(64))
BEGIN
  DECLARE idtemp INTEGER;
    SELECT IFNULL(MAX(id), 1008) + 16 INTO idtemp FROM users;
    INSERT INTO users (id,name,passwd,prompt,answer,truename,idnumber,email,mobilenumber,province,city,phonenumber,address,postalcode,gender,birthday,creatime,qq,passwd2) VALUES( idtemp, name1, passwd1, prompt1, answer1, truename1, idnumber1, email1, mobilenumber1, province1, city1, phonenumber1, address1, postalcode1, gender1, birthday1, now(), qq1, passwd21 );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `adduserpoint` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `adduserpoint`(in uid1 INTEGER, in aid1 INTEGER, in time1 INTEGER)
BEGIN
 DECLARE rowcount INTEGER;
 START TRANSACTION;
    UPDATE point SET time = IFNULL(time,0) + time1 WHERE uid1 = uid AND aid1 = aid;
    SET rowcount = ROW_COUNT();
    IF rowcount = 0 THEN
      INSERT INTO point (uid,aid,time) VALUES (uid1,aid1,time1);
    END IF;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `addUserPriv` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addUserPriv`(in userid INTEGER, in zoneid INTEGER, in rid INTEGER)
BEGIN
  START TRANSACTION;
    INSERT INTO auth VALUES(userid, zoneid, rid);
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `changePasswd` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `changePasswd`(in name1 VARCHAR(64), in passwd1 VARCHAR(64))
BEGIN
  START TRANSACTION;
    UPDATE users SET passwd = passwd1 WHERE name = name1;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `changePasswd2` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `changePasswd2`(in name1 VARCHAR(64), in passwd21 VARCHAR(64))
BEGIN
  START TRANSACTION;
    UPDATE users SET passwd2 = passwd21 WHERE name = name1;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `clearonlinerecords` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `clearonlinerecords`(in zoneid1 INTEGER, in aid1 INTEGER)
BEGIN
  START TRANSACTION;
    UPDATE point SET zoneid = NULL, zonelocalid = NULL WHERE aid = aid1 AND zoneid = zoneid1;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `deleteTimeoutForbid` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteTimeoutForbid`(in userid1 INTEGER)
BEGIN
  START TRANSACTION;
    DELETE FROM forbid WHERE userid = userid1 AND timestampdiff(second, ctime, now()) > forbid_time;
  COMMIT;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delGM`(in userid1 INTEGER)
BEGIN
  START TRANSACTION;
      DELETE FROM auth WHERE userid = userid1;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `delUserPriv` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delUserPriv`(in userid1 INTEGER, in zoneid1 INTEGER, in rid1 INTEGER, in deltype1 INTEGER)
BEGIN
START TRANSACTION;
  IF deltype1 = 0 THEN
    DELETE FROM auth WHERE userid = userid1 AND zoneid = zoneid1 AND rid = rid1;
  ELSE
    IF deltype1 = 1 THEN
      DELETE FROM auth WHERE userid = userid1 AND zoneid = zoneid1;
    ELSE
      IF deltype1 = 2 THEN
        DELETE FROM auth WHERE userid = userid1;
      END IF;
    END IF;
  END IF;
COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `enableiplimit` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `enableiplimit`(in uid1 INTEGER, in enable1 CHAR(1))
BEGIN
  DECLARE rowcount INTEGER;
  START TRANSACTION;
  UPDATE iplimit SET enable=enable1 WHERE uid=uid1;
  SET rowcount = ROW_COUNT();
  IF rowcount = 0 THEN
    INSERT INTO iplimit (uid,enable) VALUES (uid1,enable1);
  END IF;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `lockuser` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `lockuser`(in uid1 INTEGER, in lockstatus1 CHAR(1))
BEGIN
  DECLARE rowcount INTEGER;
  START TRANSACTION;
  UPDATE iplimit SET lockstatus=lockstatus1 WHERE uid=uid1;
  SET rowcount = ROW_COUNT();
  IF rowcount = 0 THEN
    INSERT INTO iplimit (uid,lockstatus,enable) VALUES (uid1,lockstatus1,'t');
  END IF;
  COMMIT;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `recordoffline`(IN `uid1` INT, IN `aid1` INT, INOUT `zoneid1` INT, INOUT `zonelocalid1` INT, INOUT `overwrite1` INT)
BEGIN
  DECLARE rowcount INTEGER;
  START TRANSACTION;
    UPDATE point SET zoneid = NULL, zonelocalid = NULL WHERE uid = uid1 AND aid = aid1 AND zoneid = zoneid1;
    DELETE FROM online WHERE ID = uid1;
    SET rowcount = ROW_COUNT();
    IF overwrite1 = rowcount THEN
      SELECT zoneid, zonelocalid INTO zoneid1, zonelocalid1 FROM point WHERE uid = uid1 AND aid = aid1;
    END IF;
  COMMIT;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `recordonline`(IN `uid1` INT, IN `aid1` INT, INOUT `zoneid1` INT, INOUT `zonelocalid1` INT, INOUT `overwrite` INT)
BEGIN
  DECLARE tmp_zoneid INTEGER;
  DECLARE tmp_zonelocalid INTEGER;
  DECLARE rowcount INTEGER;
  START TRANSACTION;
    SELECT SQL_CALC_FOUND_ROWS zoneid, zonelocalid INTO tmp_zoneid, tmp_zonelocalid FROM point WHERE uid = uid1 and aid = aid1;
    INSERT INTO online (ID) VALUES (uid1);
    SET rowcount = FOUND_ROWS();
    IF rowcount = 0 THEN
      INSERT INTO point (uid, aid, time, zoneid, zonelocalid, lastlogin) VALUES (uid1, aid1, 0, zoneid1, zonelocalid1, now());
    ELSE IF tmp_zoneid IS NULL OR overwrite = 1 THEN
      UPDATE point SET zoneid = zoneid1, zonelocalid = zonelocalid1, lastlogin = now() WHERE uid = uid1 AND aid = aid1;
    END IF;
    END IF;
    IF tmp_zoneid IS NULL THEN
      SET overwrite = 1;
    ELSE
      SET zoneid1 = tmp_zoneid;
      SET zonelocalid1 = tmp_zonelocalid;
    END IF;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `remaintime` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `remaintime`(in uid1 INTEGER, in aid1 INTEGER, out remain INTEGER, out freetimeleft INTEGER)
BEGIN
  DECLARE enddate1 DATETIME;
  DECLARE now1 DATETIME;
  DECLARE rowcount INTEGER;
  START TRANSACTION;
  SET now1 = now();
  IF aid1 = 0 THEN
    SET remain = 86313600;
    SET enddate1 = date_add(now1, INTERVAL '30' DAY);
  ELSE
    SELECT time, IFNULL(enddate, now1) INTO remain, enddate1 FROM point WHERE uid = uid1 AND aid = aid1;
    SET rowcount = ROW_COUNT();
    IF rowcount = 0 THEN
      SET remain = 0;
      INSERT INTO point (uid,aid,time) VALUES (uid1, aid1, remain);
    END IF;
  END IF;
  SET freetimeleft = 0;
  IF enddate1 > now1 THEN
    SET freetimeleft = timestampdiff(second, now1, enddate1);
  END IF;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `setiplimit` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `setiplimit`(in uid1 INTEGER, in ipaddr11 INTEGER, in ipmask11 VARCHAR(2), in ipaddr21 INTEGER, in ipmask21 VARCHAR(2), in ipaddr31 INTEGER, in ipmask31 VARCHAR(2), in enable1 CHAR(1))
BEGIN
  DECLARE rowcount INTEGER;
  START TRANSACTION;
    UPDATE iplimit SET ipaddr1 = ipaddr11, ipmask1 = ipmask11, ipaddr2 = ipaddr21, ipmask2 = ipmask21, ipaddr3 = ipaddr31, ipmask3 = ipmask31 WHERE uid = uid1;
    SET rowcount = ROW_COUNT();
    IF rowcount = 0 THEN
      INSERT INTO iplimit (uid, ipaddr1, ipmask1, ipaddr2, ipmask2, ipaddr3, ipmask3, enable1) VALUES (uid1, ipaddr11, ipmask11, ipaddr21, ipmask21, ipaddr31, ipmask31,'t');
    END IF;
  COMMIT;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserInfo`(IN `name1` VARCHAR(64), IN `prompt1` VARCHAR(64), IN `answer1` VARCHAR(32), IN `truename1` VARCHAR(32), IN `idnumber1` VARCHAR(32), IN `province1` VARCHAR(32), IN `city1` VARCHAR(32), IN `phonenumber1` VARCHAR(32), IN `address1` VARCHAR(64), IN `postalcode1` VARCHAR(8), IN `gender` INT, IN `birthday1` VARCHAR(32), IN `qq1` VARCHAR(32))
BEGIN
  START TRANSACTION;
    UPDATE users SET prompt = prompt1, answer = answer1, truename = truename1, idnumber = idnumber1, email = email1, mobilenumber = mobilenumber1, province = province1, city = city1, phonenumber = phonenumber1, address = address1, postalcode = postalcode1, gender = gender1, birthday = birthda1, qq = qq1 WHERE name = name1;
  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `usecash` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `usecash`(
  in userid1 INTEGER,
  in zoneid1 INTEGER,
  in sn1 INTEGER,
  in aid1 INTEGER,
  in point1 INTEGER,
  in cash1 INTEGER,
  in status1 INTEGER,
  out error INTEGER
)
BEGIN
DECLARE sn_old INTEGER;
DECLARE aid_old INTEGER;
DECLARE point_old INTEGER;
DECLARE cash_old INTEGER;
DECLARE status_old INTEGER;
DECLARE createtime_old DATETIME;
DECLARE time_old INTEGER;
DECLARE need_restore INTEGER;
DECLARE exists1 INTEGER;
DECLARE rowcount INTEGER;
START TRANSACTION;
  SET error = 0;
  SET need_restore = 0;
  SELECT SQL_CALC_FOUND_ROWS sn, aid, point, cash, status, creatime INTO sn_old, aid_old, point_old, cash_old, status_old, createtime_old FROM usecashnow WHERE userid = userid1 AND zoneid = zoneid1 AND sn >= 0;
  SET rowcount = FOUND_ROWS();
  IF rowcount = 1 THEN
    SET exists1 = 1;
  ELSE
    SET exists1 = 0;
  END IF;
  IF status1 = 0 THEN
    IF exists1 = 0 THEN
      SELECT aid, point INTO aid1, point1 FROM usecashnow WHERE userid = userid1 AND zoneid = zoneid1 AND sn = sn1;
      SET point1 = IFNULL(point1,0);
      UPDATE point SET time = time-point1 WHERE uid = userid1 AND aid = aid1 AND time >= point1;
      SET rowcount = ROW_COUNT();
      IF rowcount = 1 THEN
        UPDATE usecashnow SET sn = 0, status = 1 WHERE userid = userid1 AND zoneid = zoneid1 AND sn = sn1;
      ELSE
        SET error = -8;
      END IF;
    END IF;
  ELSE
    IF status1 = 1 THEN
      IF exists1 = 0 THEN
        UPDATE point SET time = time-point1 WHERE uid = userid1 AND aid = aid1 AND time >= point1;
        SET rowcount = ROW_COUNT();
        IF rowcount = 1 THEN
          INSERT INTO usecashnow (userid, zoneid, sn, aid, point, cash, status, creatime) VALUES (userid1, zoneid1, sn1, aid1, point1, cash1, status1, now());
        ELSE
          INSERT INTO usecashnow SELECT userid1, zoneid1, IFNULL(min(sn),0)-1, aid1, point1, cash1, 0, now() FROM usecashnow WHERE userid = userid1 AND zoneid = zoneid1 AND 0 >= sn;
          SET error = -8;
        END IF;
      ELSE
        INSERT INTO usecashnow SELECT userid1, zoneid1, IFNULL(min(sn),0)-1, aid1, point1, cash1, 0, now() FROM usecashnow WHERE userid = userid1 AND zoneid = zoneid1 AND 0 >= sn;
        SET error = -7;
      END IF;
    ELSE
      IF status1 = 2 THEN
        IF exists1 = 1 AND status_old = 1 AND sn_old = 0 THEN
          UPDATE usecashnow SET sn = sn1, status = status1 WHERE userid = userid1 AND zoneid = zoneid1 AND sn = sn_old;
        ELSE
          SET error = -9;
        END IF;
      ELSE
        IF status1 = 3 THEN
           IF exists1 = 1 AND status_old = 2 THEN
            UPDATE usecashnow SET status = status1 WHERE userid = userid1 AND zoneid = zoneid1 AND sn = sn_old;
           ELSE
            SET error = -10;
            END IF;
        ELSE
         IF status1 = 4 THEN
          IF exists1 = 1 THEN
            DELETE FROM usecashnow WHERE userid = userid1 AND zoneid = zoneid1 AND sn = sn_old;
            INSERT INTO usecashlog (userid, zoneid, sn, aid, point, cash, status, creatime, fintime) VALUES (userid1, zoneid1, sn_old, aid_old, point_old, cash_old, status1, createtime_old, now());
          END IF;
          IF NOT (exists1 = 1 AND status_old = 3) THEN
            SET error = -11;
          END IF;
        ELSE
          SET error = -12;
        END IF;
      END IF;
    END IF;
  END IF;
  END IF;
  IF need_restore = 1 THEN
    UPDATE point SET time = time+point_old WHERE uid = userid1 AND aid = aid_old;
    DELETE FROM usecashnow WHERE userid = userid1 AND zoneid = zoneid1 AND sn = sn_old;
    INSERT INTO usecashlog (userid, zoneid, sn, aid, point, cash, status, creatime, fintime) VALUES (userid1, zoneid1, sn_old, aid_old, point_old, cash_old, status1, createtime_old, now());
  END IF;
COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-04-30 19:47:57
