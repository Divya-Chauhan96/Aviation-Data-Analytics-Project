use aviation;
CREATE TABLE flights (
    YEAR SMALLINT,
    MONTH TINYINT,
    DAY TINYINT,
    DAY_OF_WEEK TINYINT,
    AIRLINE VARCHAR(10),
    FLIGHT_NUMBER INT,
    TAIL_NUMBER VARCHAR(10),
    ORIGIN_AIRPORT VARCHAR(5),
    DESTINATION_AIRPORT VARCHAR(5),
    SCHEDULED_DEPARTURE INT,
    DEPARTURE_TIME VARCHAR(10),  -- Temporary for import
    DEPARTURE_DELAY VARCHAR(10), -- Temporary for import
    TAXI_OUT VARCHAR(10),        -- Temporary for import
    WHEELS_OFF VARCHAR(10),      -- Temporary for import
    SCHEDULED_TIME INT,
    ELAPSED_TIME VARCHAR(10),    -- Temporary for import
    AIR_TIME VARCHAR(10),        -- Temporary for import
    DISTANCE INT,
    WHEELS_ON VARCHAR(10),       -- Temporary for import
    TAXI_IN VARCHAR(10),         -- Temporary for import
    SCHEDULED_ARRIVAL INT,
    ARRIVAL_TIME VARCHAR(10),    -- Temporary for import
    ARRIVAL_DELAY VARCHAR(10),   -- Temporary for import
    DIVERTED TINYINT,
    CANCELLED TINYINT,
    CANCELLATION_REASON VARCHAR(5) NULL,
    AIR_SYSTEM_DELAY VARCHAR(10), -- Temporary for import
    SECURITY_DELAY VARCHAR(10),   -- Temporary for import
    AIRLINE_DELAY VARCHAR(10),    -- Temporary for import
    LATE_AIRCRAFT_DELAY VARCHAR(10), -- Temporary for import
    WEATHER_DELAY VARCHAR(10)     -- Temporary for import
);
/*                 STEPS TO LOAD DATA INFILE 
 close the sql - open services - search for sql - right click - stop 
✅ Step 1: Close Notepad first.
✅ Step 2: Open Notepad as Administrator
Type Notepad in the Windows search bar.
Right-click Notepad and select Run as Administrator.
✅ Step 3: Once Notepad opens, click File > Open, navigate to:
C:\ProgramData\MySQL\MySQL Server 8.0\my.ini
✅ Tip: If you don't see my.ini immediately, make sure you select “All files” in the File Type drop-down.
✅ Step 4: Now you should be able to edit and save my.ini.
🚀 After saving:
✅ Step 5: Restart MySQL service for the change to take effect.
➥ Open Services
➥ Find MySQL
➥ Right-click and select Restart
✅ Now you should be able to LOAD DATA INFILE from the directory you configured. 
path should be like this -- "C:/Divya/gameplay_data.csv"   make sure it is seperated by forward slash not backward slash  */ 
  
  SHOW VARIABLES LIKE 'secure_file_priv';
  SHOW GLOBAL VARIABLES LIKE 'local_infile';
  SET GLOBAL local_infile = 'ON';  

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/flights.csv"
INTO TABLE flights
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from flights
where month = 1 and day = 1 and AIRLINE = 'B6' and CANCELLED =1; 
select * from airlines;
/*-------------------------------------------------------------------------------------------------------------------------------------------------*/
-- KPI 1. Weekday Vs Weekend total flights statistics

SELECT 
    CASE 
        WHEN DAY_OF_WEEK IN (6, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS total_flights
FROM flights
GROUP BY 
    CASE 
        WHEN DAY_OF_WEEK IN (6, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END;
    
/*--------------------------------------------------------------------------------------------------------------------------------------------*/    
 -- KPI 2. Total number of cancelled flights for JetBlue Airways on first date of every month

SELECT 
    f.YEAR,
    f.MONTH,
    a.AIRLINE AS airline_name,
    COUNT(*) AS cancelled_flights
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
WHERE 
    f.AIRLINE = 'B6'
    AND f.DAY = 1
    AND f.CANCELLED = 1
GROUP BY 
    f.YEAR,
    f.MONTH,
    a.AIRLINE
ORDER BY 
    f.YEAR,
    f.MONTH;
/*--------------------------------------------------------------------------------------------------------------------------------------------*/    
-- KPI 3. Week wise, State wise and City wise statistics of delay of flights with airline details

SELECT 
    FLOOR((f.DAY - 1) / 7) + 1 AS week_number,
    ao.STATE AS origin_state,
    ao.CITY AS origin_city,
    ad.STATE AS destination_state,
    ad.CITY AS destination_city,
    a.AIRLINE AS airline_name,
    COUNT(*) AS total_flights,
    AVG(f.ARRIVAL_DELAY) AS avg_arrival_delay,
    AVG(f.DEPARTURE_DELAY) AS avg_departure_delay,
    SUM(COALESCE(f.DEPARTURE_DELAY, 0) + COALESCE(f.ARRIVAL_DELAY, 0)) AS total_delay
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
JOIN airports ao ON f.ORIGIN_AIRPORT = ao.IATA_CODE
JOIN airports ad ON f.DESTINATION_AIRPORT = ad.IATA_CODE
WHERE 
    f.ARRIVAL_DELAY IS NOT NULL
    AND f.YEAR = 2015
    AND f.MONTH = 1
GROUP BY 
    FLOOR((f.DAY - 1) / 7) + 1,
    ao.STATE,
    ao.CITY,
    ad.STATE,
    ad.CITY,
    a.AIRLINE
ORDER BY 
    week_number,
    origin_state,
    origin_city,
    destination_state,
    destination_city,
    airline_name
LIMIT 10000;

/*--------------------------------------------------------------------------------------------------------------------------------------------*/    
-- KPI 4. Number of airlines with No departure/arrival delay with distance covered between 2500 and 3000

WITH qualified_airlines AS (
    SELECT  a.AIRLINE, a.AIRLINE AS airline_name
    FROM flights f
    JOIN airlines a ON f.AIRLINE = a.IATA_CODE
    WHERE 
        f.DEPARTURE_DELAY IS NOT NULL
        AND f.ARRIVAL_DELAY IS NOT NULL
        AND f.DEPARTURE_DELAY <= 0
        AND f.ARRIVAL_DELAY <= 0
        AND f.DISTANCE BETWEEN 2500 AND 3000
	group by a.AIRLINE
)
SELECT 
    airline_name,
    (SELECT COUNT(*) FROM qualified_airlines) AS total_qualified_airlines
FROM qualified_airlines;

    
 /*--------------------------------------------------------------------------------------------------------------------------------------------*/    
-- KPI 5. On-Time Performance by Airline and Airport Pair
   
   SELECT 
    a.AIRLINE AS airline_name,
    ao.CITY AS origin_city,
    ad.CITY AS destination_city,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN f.ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time_flights,
    (SUM(CASE WHEN f.ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*) * 100) AS on_time_percentage
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
JOIN airports ao ON f.ORIGIN_AIRPORT = ao.IATA_CODE
JOIN airports ad ON f.DESTINATION_AIRPORT = ad.IATA_CODE
WHERE 
    f.ARRIVAL_DELAY IS NOT NULL
    AND f.CANCELLED = 0
    AND f.YEAR = 2015 AND f.MONTH = 1 -- Optional filter for performance
GROUP BY 
    a.AIRLINE,
    ao.CITY,
    ad.CITY
HAVING 
    total_flights >= 10 -- Filter for statistically significant routes
ORDER BY 
    on_time_percentage DESC
LIMIT 1000;


/*--------------------------------------------------------------------------------------------------------------------------------------------*/    
-- KPI 6. Average Delay by Delay Reason per Airline

SELECT 
    a.AIRLINE AS airline_name,
    AVG(CAST(f.AIR_SYSTEM_DELAY AS DECIMAL)) AS avg_air_system_delay,
    AVG(CAST(f.SECURITY_DELAY AS DECIMAL)) AS avg_security_delay,
    AVG(CAST(f.AIRLINE_DELAY AS DECIMAL)) AS avg_airline_delay,
    AVG(CAST(f.LATE_AIRCRAFT_DELAY AS DECIMAL)) AS avg_late_aircraft_delay,
    AVG(CAST(f.WEATHER_DELAY AS DECIMAL)) AS avg_weather_delay
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
WHERE 
    f.ARRIVAL_DELAY > 0
    AND (f.AIR_SYSTEM_DELAY IS NOT NULL OR f.SECURITY_DELAY IS NOT NULL OR 
         f.AIRLINE_DELAY IS NOT NULL OR f.LATE_AIRCRAFT_DELAY IS NOT NULL OR 
         f.WEATHER_DELAY IS NOT NULL)
    AND f.YEAR = 2015 AND f.MONTH = 1 -- Optional filter
GROUP BY 
    a.AIRLINE
ORDER BY 
    avg_airline_delay DESC;

/*--------------------------------------------------------------------------------------------------------------------------------------------*/    
-- KPI 7. Flight Diversion Rate by Origin Airport

SELECT 
    ao.CITY AS origin_city,
    ao.STATE AS origin_state,
    COUNT(*) AS total_flights,
    SUM(f.DIVERTED) AS diverted_flights,
    (SUM(f.DIVERTED) / COUNT(*) * 100) AS diversion_rate
FROM flights f
JOIN airports ao ON f.ORIGIN_AIRPORT = ao.IATA_CODE
WHERE 
    f.CANCELLED = 0
    AND f.YEAR = 2015 AND f.MONTH = 1 -- Optional filter
GROUP BY 
    ao.CITY,
    ao.STATE
HAVING 
    total_flights >= 50 -- Ensure sufficient sample size
ORDER BY 
    diversion_rate DESC
LIMIT 1000;

/*--------------------------------------------------------------------------------------------------------------------------------------------*/    
-- KPI 8. Average Flight Distance per Airline

SELECT 
    a.AIRLINE AS airline_name,
    COUNT(*) AS total_flights,
    AVG(f.DISTANCE) AS avg_flight_distance,
    MIN(f.DISTANCE) AS min_distance,
    MAX(f.DISTANCE) AS max_distance
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
WHERE 
    f.CANCELLED = 0
    AND f.DISTANCE IS NOT NULL
    AND f.YEAR = 2015 AND f.MONTH = 1 -- Optional filter
GROUP BY 
    a.AIRLINE
ORDER BY 
    avg_flight_distance DESC;
    
    
/*--------------------------------------------------------------------------------------------------------------------------------------------*/    
-- KPI 9. Cancellation Reason Breakdown by Airline
    
SELECT 
    a.AIRLINE AS airline_name,
    COUNT(*) AS total_cancellations,
    SUM(CASE WHEN f.CANCELLATION_REASON = 'A' THEN 1 ELSE 0 END) AS airline_cancellations,
    SUM(CASE WHEN f.CANCELLATION_REASON = 'B' THEN 1 ELSE 0 END) AS weather_cancellations,
    SUM(CASE WHEN f.CANCELLATION_REASON = 'C' THEN 1 ELSE 0 END) AS nas_cancellations,
    SUM(CASE WHEN f.CANCELLATION_REASON = 'D' THEN 1 ELSE 0 END) AS security_cancellations,
    (SUM(CASE WHEN f.CANCELLATION_REASON = 'A' THEN 1 ELSE 0 END) / COUNT(*) * 100) AS airline_cancel_pct,
    (SUM(CASE WHEN f.CANCELLATION_REASON = 'B' THEN 1 ELSE 0 END) / COUNT(*) * 100) AS weather_cancel_pct,
    (SUM(CASE WHEN f.CANCELLATION_REASON = 'C' THEN 1 ELSE 0 END) / COUNT(*) * 100) AS nas_cancel_pct,
    (SUM(CASE WHEN f.CANCELLATION_REASON = 'D' THEN 1 ELSE 0 END) / COUNT(*) * 100) AS security_cancel_pct
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
WHERE 
    f.CANCELLED = 1
    AND f.CANCELLATION_REASON IS NOT NULL
    AND f.YEAR = 2015 AND f.MONTH = 1 -- Optional filter
GROUP BY 
    a.AIRLINE
HAVING 
    total_cancellations >= 10 -- Ensure sufficient sample size
ORDER BY 
    total_cancellations DESC;