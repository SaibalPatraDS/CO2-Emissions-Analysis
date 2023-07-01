-- Solution Level 1 --

-- 1. What is the total count of vehicles in the database?
SELECT COUNT(*) AS total_vehicles
FROM co2_emissions.vehicles;


-- 2. How many unique make and model combinations are there?

SELECT Make AS Company_name,
       SUM(company) AS total_cars
FROM(
	SELECT Make, 
	--        Model, 
		   COUNT(DISTINCT Make) AS company
	--        COUNT(DISTINCT Model) AS model_name
	FROM co2_emissions.vehicles
	GROUP BY Make) x
GROUP BY x.Make
ORDER BY total_cars DESC;


-- 3. What is the average motor power (in kW) of vehicles in each vehicle class?

SELECT Vehicle_Class,
	   COUNT(Vehicle_Class) AS total_vehicle,
	   ROUND(AVG(Motor_KW), 2) AS avg_motor_power
FROM co2_emissions.vehicles
GROUP BY Vehicle_Class
ORDER BY avg_motor_power DESC;


-- 4. Which make has the highest average range (in km) for all the models it offers?
SELECT Make AS company_name,
       ROUND(AVG(Range_km),2) AS avg_range
FROM co2_emissions.vehicles
GROUP BY Make
ORDER BY avg_range DESC
LIMIT 1;


-- 5. Which make has the highest average CO2 emissions (in g/km) across all its models?

SELECT Make AS company_name,
       ROUND(AVG(CO2_Emissions_gkm),2) AS avg_emissions
FROM co2_emissions.vehicles
GROUP BY Make
ORDER BY avg_emissions
LIMIT 1;


-- 6. What is the overall average consumption in the city (in kWh/100 km)?

SELECT ROUND(AVG(Consumption_City_kWh100_km), 2) AS avg_consumption
FROM co2_emissions.vehicles;

/* Extra

SELECT Make AS company,
       ROUND(AVG(Consumption_City_kWh100_km), 2) AS avg_consumption
FROM co2_emissions.vehicles
GROUP BY Make
ORDER BY avg_consumption DESC;

*/


-- 7. Which vehicle class has the highest average consumption on highways (in kWh/100 km)?

SELECT Vehicle_Class,
       ROUND(AVG(Consumption_Hwy_kWh100_km),2) AS avg_consumption_highways
FROM co2_emissions.vehicles
GROUP BY Vehicle_Class
ORDER BY avg_consumption_highways DESC
LIMIT 1;


-- 8. What is the average CO2 rating for each vehicle class?

SELECT Vehicle_Class,
       ROUND(AVG(CASE WHEN CO2_rating <> 'n/a' THEN CO2_rating::NUMERIC END), 2) AS avg_co2_ratings
FROM co2_emissions.vehicles
WHERE CO2_rating <> 'n/a'
GROUP BY Vehicle_Class
ORDER BY avg_co2_ratings DESC;


-- 9. How many unique makes have a smog rating of "10"?

SELECT DISTINCT Make AS unique_company_with_smog_rating_10
FROM co2_emissions.vehicles
WHERE Smog_rating = 10::VARCHAR;


-- 10. What is the average recharge time (in hours) for each fuel type?

SELECT Fuel_Type,
       ROUND(AVG(Recharge_time_h::NUMERIC), 2) AS avg_recharge_time_h
FROM co2_emissions.vehicles
GROUP BY Fuel_Type;


-- 11. Which make and model combination has the highest consumption in the city (in Le/100 km)?

SELECT Make, 
       Model
FROM co2_emissions.vehicles
WHERE Consumption_City_Le100_km = (SELECT MAX(Consumption_City_Le100_km)
								   FROM co2_emissions.vehicles);

/* Using JOIN 

SELECT Make, Model
FROM co2_emissions.vehicles v
JOIN (SELECT MAX(Consumption_City_Le100_km) AS max_consumption
	 FROM co2_emissions.vehicles) AS p
ON v.Consumption_City_Le100_km = p.max_consumption;

*/

-- 12. What is the rank of each make's average range (in km) within its vehicle class?

/* 
step 1 - calculate avg_range for each Make and Vehicle_Class 
step 2 - use on previous result ROW_NUMER() OVER(PARTITION BY Make ORDER avg_range)
*/

SELECT Make, 
   	   Vehicle_Class,
	   ROW_NUMBER() OVER(PARTITION BY Make ORDER BY avg_range DESC) AS ranking
FROM(
SELECT Make, 
       Vehicle_Class,
	   AVG(Range_km) AS avg_range
FROM co2_emissions.vehicles
GROUP BY Make, Vehicle_Class
ORDER BY Make, avg_range DESC) x;


/*
-- 13. For each make and model, what is the difference in consumption in the city (in kWh/100 km) 
compared to the average consumption in the city for that make?
*/

/*
step 1 - calculate average Consumption_City_kWh100_km for each Make and Model
step 2 - calculate difference between regula values and avg_values
*/

-- SELECT Make, 
--        Model,
-- 	   Consumption_City_kWh100_km - (SELECT avg_consumption_city 
-- 									 FROM (SELECT Make,
-- 												   Model,
-- 												   ROUND(AVG(Consumption_City_kWh100_km),2) AS avg_consumption_city
-- 										   FROM co2_emissions.vehicles
-- 										   GROUP BY Make, Model)p)
-- FROM co2_emissions.vehicles				
-- GROUP BY Make, Model,Consumption_City_kWh100_km;


SELECT p.Make, 
       p.Model, 
	   p.Consumption_City_kWh100_km - avg_city_consumption AS consumption_difference
FROM co2_emissions.vehicles p
JOIN (
    SELECT Make, AVG(Consumption_City_kWh100_km) AS avg_city_consumption
    FROM co2_emissions.vehicles
    GROUP BY Make
) AS avg_consumption
ON p.Make = avg_consumption.Make
ORDER BY p.Make;

-- SELECT Make,
--        Model,
-- 	   ROUND(AVG(Consumption_City_kWh100_km),2) AS avg_consumption_city
-- FROM co2_emissions.vehicles
-- GROUP BY Make, Model;
	   
SELECT p.Make,
       p.Model,
	   (p.Consumption_City_kWh100_km::NUMERIC - x.avg_consumption_city::NUMERIC) AS difference_consumption
FROM co2_emissions.vehicles p
JOIN (SELECT Make,
	   ROUND(AVG(Consumption_City_kWh100_km),2) AS avg_consumption_city
FROM co2_emissions.vehicles
GROUP BY Make) x
USING (Make)
-- GROUP BY p.Make, p.Model, p.Consumption_City_kWh100_km, x.avg_consumption_city
ORDER BY difference_consumption DESC;


-- SELECT Model, Consumption_City_kWh100_km
-- FROM co2_emissions.vehicles
-- WHERE Make = 'BMW';

-- SELECT Make,
--        Model,
-- 	   ROUND(AVG(Consumption_City_kWh100_km),2) AS avg_consumption_city
-- FROM co2_emissions.vehicles
-- WHERE Make = 'BMW'
-- GROUP BY Make, Model;



-- 14. Which make and model combination has the highest CO2 emissions (in g/km) within its vehicle class?

/*
step 1 - use row_number() OVER(PARTITION BY Make ORDER BY CO2_Emissions_gkm DESC)
step 2 - filter row_number = 1
*/

SELECT Make,
       Model,
	   Vehicle_Class,
	   emissions_ranking
FROM(	   
SELECT Make,
       Model,
	   Vehicle_Class,
	   ROW_NUMBER() OVER(PARTITION BY Make ORDER BY CO2_Emissions_gkm DESC) AS emissions_ranking
FROM co2_emissions.vehicles) p
WHERE p.emissions_ranking = 1;


-- 15. For each make, what is the cumulative sum of CO2 emissions (in g/km) across all its models?

/*
step 1 - calculate SUM(CO2_Emissions_gkm) OVER(ORDER BY Make, Model)
*/

SELECT Make,
       Model,
	   SUM(CO2_Emissions_gkm) OVER(ORDER BY Make, Model) AS cumulative_co2_emissions
FROM co2_emissions.vehicles
GROUP BY Make, Model, CO2_Emissions_gkm;


-- 16. What is the average range (in km) for each make's top 5 models in terms of range?

/*
step 1 : calculate avg_range for each Make
step 2 : Use ROW_NUMBER() OVER(PARTITION BY Make ORDER BY avg_range DESC)
step 3 : select only top 5 for each Make
*/

SELECT *
FROM(
	SELECT *,
		   ROW_NUMBER() OVER(PARTITION BY Make ORDER BY avg_range DESC) AS avg_range_ranking
	FROM(	   
		SELECT Make, 
			   Model,
			   ROUND(AVG(Range_km::NUMERIC), 2) AS avg_range
		FROM co2_emissions.vehicles
		GROUP BY Make, Model) x ) p
WHERE p.avg_range_ranking <=5;


/* Alternative Method

WITH temp AS(
	SELECT Make,
	       Model,
		   ROUND(AVG(Range_km::NUMERIC), 2) AS avg_range,
		   ROW_NUMBER() OVER(PARTITION BY Make ORDER BY AVG(Range_km::NUMERIC) DESC) AS avg_range_ranking
	FROM co2_emissions.vehicles
	GROUP BY Make,Model
)

SELECT Make,
       Model,
	   avg_range_ranking
FROM temp
WHERE avg_range_ranking <= 5;

*/


-- 17. What is the average consumption in the city (in kWh/100 km) for the top 10 models with the highest range?

/*
step 1 - filter out top 10 models wrt highest range
step 2 - for each model find out average consumption in the city(kWh/100 km)
*/

SELECT Model,
       ROUND(AVG(Consumption_City_kWh100_km),2) AS avg_consumption_city
FROM(	   
	SELECT *,
		   DENSE_RANK() OVER(PARTITION BY Model ORDER BY Range_km DESC) AS ranking
	FROM co2_emissions.vehicles
	ORDER BY ranking) x
WHERE x.ranking <= 10
GROUP BY Model;

-- SELECT Make, Model, Range_km, 
-- 	   DENSE_RANK() OVER(PARTITION BY Vehicle_Class ORDER BY Range_km DESC) AS ranking
-- FROM co2_emissions.vehicles
-- ORDER BY ranking;


-- SELECT DISTINCT Vehicle_Class
-- FROM co2_emissions.vehicles;


/*
-- 18. For each vehicle class, what is the running total of consumption on highways (in kWh/100 km) 
ordered by the make and model?
*/

-- SELECT Vehicle_Class,
--        p.running_total
-- FROM(	   
-- SELECT Make,
-- 	   Model,
-- 	   Vehicle_Class,
-- 	   SUM(Consumption_Hwy_kWh100_km) OVER(PARTITION BY Vehicle_Class ORDER BY Make, Model) AS running_total
-- FROM co2_emissions.vehicles) p
-- GROUP BY Vehicle_Class, p.running_total;

SELECT DISTINCT Vehicle_Class, Make, Model, 
       SUM(Consumption_Hwy_kWh100_km) OVER (ORDER BY Make, Model) AS running_total
FROM co2_emissions.vehicles
ORDER BY Vehicle_Class, Make, Model;


/* 
-- 19. What is the average recharge time (in hours) for each make's models in descending order of their average smog rating?
*/

/*
step 1 - calculate average smog_rating for each make's model 
-- step 2 - use row number function to have some order no
step 3 - average recharge time for each make's model
step 4 - order by avg_smog_rating
*/

SELECT Make, Model,
       ROUND(AVG(Recharge_time_h), 2) AS avg_recharge_time,
	   ROUND(AVG(CASE WHEN Smog_rating <> 'n/a' THEN Smog_rating::NUMERIC END), 2) AS avg_smog_rating
FROM co2_emissions.vehicles
GROUP BY Make, Model
ORDER BY avg_smog_rating DESC;


/*
-- 20. Which make has the highest difference in average CO2 emissions (in g/km) 
between its models and the average CO2 emissions across all makes?
*/




























































































































































