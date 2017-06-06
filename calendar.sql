-- Create the calendar table structure

CREATE TABLE calendar_table (
	`date` DATE NOT NULL PRIMARY KEY,
	`year` SMALLINT NULL,
	`quarter` TINYINT NULL,
	`month` TINYINT NULL,
	`day` TINYINT NULL,
	`day_of_week` TINYINT NULL,
	`month_name` VARCHAR( 9 ) NULL,
	`day_name` VARCHAR( 9 ) NULL,
	`week_of_year` TINYINT NULL,
	`is_weekday` BINARY(1) NULL,
	`is_holiday` BINARY(1) NULL,
	`holiday_name` VARCHAR(32) NULL,
	`day_number_of_month` TINYINT NULL,
	`week_alternate` VARCHAR(1) NULL
);

-- Create a table of integers

CREATE TABLE `ints` ( 
	`i` TINYINT( 1 ) 
);

ALTER TABLE  `ints` ADD INDEX ( `i` );
 
INSERT INTO `ints` ( `i` ) VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- Create 100,000 integers based from our 10 integers

CREATE TEMPORARY TABLE 100k AS

SELECT a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i AS i

FROM ints a 
JOIN ints b 
JOIN ints c 
JOIN ints d 
JOIN ints e

ORDER BY i ASC

;

-- Insert dates into calendar table

SET @start_date = CONCAT( YEAR( CURDATE() - INTERVAL 1 YEAR ), '-01-01');
SET @end_date = @start_date + INTERVAL 40 year - INTERVAL 1 DAY;
SET @days = DATEDIFF( @end_date, @start_date );
SET @week = 'a';
INSERT INTO calendar_table ( `date`, `week_alternate` )
SELECT 
( 
	DATE( @start_date ) + INTERVAL 100k.i DAY ) AS `date`, 
	IF( DAYOFWEEK( DATE( @start_date ) + INTERVAL 100k.i DAY ) = 1, 
		IF( @week = 'a', 
			@week := 'b', 
			@week := 'a' 
		), 
		@week 
) AS `week_alternate` 

FROM 100k

WHERE 100k.i <= @days

;

-- Populate date details within the calendar table

UPDATE calendar_table

SET 
	is_weekday = CASE 
		WHEN DAYOFWEEK( `date` ) IN ( 1,7 ) THEN 0 
		ELSE 1 
	END,
	`day_number_of_month` = CEIL( DAYOFMONTH( `date` ) / 7 ),
	`year` = YEAR( `date` ),
	`quarter` = QUARTER( `date` ),
	`month` = MONTH( `date` ),
	`day` = DAYOFMONTH( `date` ),
	`day_of_week` = DAYOFWEEK( `date` ),
	`month_name` = MONTHNAME( `date` ),
	`day_name` = DAYNAME( `date` ),
	`week_of_year` = WEEK( `date` )

;

-- Add major holidays to the calendar table

-- New Year's Day

UPDATE calendar_table 

SET 
	`is_holiday` = 1, 
	`holiday_name` = "New Year's Day" 

WHERE `month` = 1 
	AND `day` = 1

;

-- Martin Luther King Day

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = 'Martin Luther King Day'
	
WHERE `month` = 1 
	AND `day_of_week` = 2 
	AND `day` BETWEEN 15 AND 21
	
;

-- Presidents Day

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = "Presidents' Day"
	
WHERE `month` = 2 
	AND `day_of_week` = 2 
	AND `day` BETWEEN 15 AND 21
	
;

-- Memorial Day

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = 'Memorial Day'
	
WHERE `month` = 5 
	AND `day_of_week` = 2 
	AND `day` BETWEEN 25 AND 31
	
;

-- Fourth of July, with weekend deals

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = 'Independence Day'
	
WHERE `month` = 7 
	AND `day` = 4
	
;

-- Labor day

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = 'Labor Day'
		
WHERE `month` = 9 
	AND `day_of_week` = 2 
	AND `day` BETWEEN 1 AND 7
	
;

-- Veterans Day

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = 'Veterans Day'

WHERE `month` = 11 
	AND `day` = 11
	
;

-- Thanskgiving 

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = 'Thanksgiving Day'
	
WHERE `month` = 11 
	AND `day_of_week` = 5 
	AND `day` BETWEEN 22 AND 28

;

-- Christmas

UPDATE calendar_table

SET 
	`is_holiday` = 1, 
	`holiday_name` = 'Christmas Day'

WHERE `month` = 12 
	AND `day` = 25
	
;

-- Pay periods and days Pay periods are 1 week, and payday is every friday

CREATE OR REPLACE VIEW calendar_paydays AS
(
	SELECT
		DATE_SUB( DATE( `date` ), INTERVAL 12 DAY ) AS beginning_of_pay_period,
		DATE_SUB( DATE( `date` ), INTERVAL 6 DAY ) AS end_of_pay_period,
		`date` AS payday
	
	FROM calendar_table
	
	WHERE `day_of_week` = 6

);