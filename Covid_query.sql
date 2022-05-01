
/*DATA EXPLORATION PROJECT 
THE DATA COLLECTED WAS FROM 24-02-2020 TO 26-04-2022. WEBSITE: https://ourworldindata.org/covid-deaths 
AFTER DATA EXPLORATION I WILL PROCEED TO DATA VISUALISATION BY USING TABLEAU.
SKILLS USED:
-DATA MANIPULATION
-OPERATORS
-AGGREGATE FUNCTIONS
-CTE
-MANAGING VIEWS
-CONVERSION
*/

--ODER TABLE BY LOCATION AND DATE.

SELECT * FROM Covid_deaths
ORDER BY 3, 4;

--HOW MANY DISTINCT COUNTRIES HAVE WE GOT? THE DATASET HAVE 243 COUNTRIES. 

SELECT COUNT(DISTINCT location) AS 'Total number of counties' FROM Covid_deaths;


--TOTAL CASES AND DEATHS BY COUNTRY / TOTAL POPULATION IN DISTINCT COUNTRIES

SELECT location, continent, population, MAX(total_cases) AS total_cases_by_country,  
MAX(cast(total_deaths as int)) AS total_deaths_by_country 
FROM Covid_deaths
WHERE location IS NOT NULL AND continent IS NOT NULL AND 
population IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY location, continent, population
ORDER BY location;

--TOTAL CASES AND DEATHS ONLY BY CONTINENT

WITH TEMP_TABLE AS
(
SELECT location, continent, MAX(total_cases) AS total_cases_by_continent, 
MAX(cast(total_deaths as int)) AS total_deaths_by_continent 
FROM Covid_deaths
WHERE continent IS NOT NULL AND population IS NOT NULL 
AND total_cases IS NOT NULL AND total_deaths IS NOT NULL --AND 
--continent = 'Africa'
GROUP BY continent, location) 
SELECT continent, SUM(total_cases_by_continent) AS total_cases_by_continent, 
SUM(total_deaths_by_continent) AS total_deaths_by_continent
FROM TEMP_TABLE 
GROUP BY continent;

--WORLDWIDE NUMBERS

WITH TEMP_TABLE AS
(
SELECT location, continent, MAX(total_cases) AS total_cases_worldwide, 
MAX(cast(total_deaths as int)) AS total_deaths_worlwide
FROM Covid_deaths
WHERE continent IS NOT NULL AND population IS NOT NULL 
AND total_cases IS NOT NULL AND total_deaths IS NOT NULL --AND 
--continent = 'Africa'
GROUP BY continent, location) 
SELECT SUM(total_cases_worldwide) AS total_cases_worldwide, 
SUM(total_deaths_worlwide) AS total_deaths_worlwide
FROM TEMP_TABLE;

--DAILY NEW DEATH / DAILY NEW CASES

SELECT location, cast(date as DATE) AS date, /*new_cases,*/ new_deaths,
CASE
--WHEN new_cases = 0 THEN 'NO NEW CASES'
WHEN new_deaths = 0 THEN 'NO DEATH'
--WHEN new_cases =+ new_cases THEN 'NEW CASES'
WHEN new_deaths =+ new_deaths THEN 'NEW DEATH'
ELSE 'STEADY'
END AS Status
FROM Covid_deaths
WHERE /*new_cases IS NOT NULL AND */ new_deaths IS NOT NULL;


--DEATH PERCENTAGE BY DATE (TOTAL DEATHS VS TOTAL CASES)/ INFECTION RATE OF THE POPULATION BY DATE
CREATE VIEW Deaths_percent_Infection_Rate AS
SELECT location, population, cast(date as DATE) AS date, total_cases, cast(total_deaths as float) AS total_deaths,
ROUND(((total_deaths/total_cases)*100), 2)  AS Death_Percentage_by_cases, 
ROUND(((total_cases/population)*100), 6) AS Infection_Rate_Population FROM Covid_deaths 
WHERE continent IS NOT NULL AND population IS NOT NULL 
AND new_deaths IS NOT NULL AND total_cases IS NOT NULL;


--EVOLUTION OF COVID IN THE UNITED KINGDOM IN 2020
SELECT location, population, cast(date as DATE) AS date, 
Death_Percentage_by_cases, Infection_Rate_Population
FROM Deaths_percent_Infection_Rate 
WHERE location = 'United Kingdom' AND date LIKE '%2020%'
ORDER BY date;

--EVOLUTION OF COVID IN THE UNITED KINGDOM IN 2021
SELECT location, population, cast(date as DATE) AS date, 
Death_Percentage_by_cases, Infection_Rate_Population
FROM Deaths_percent_Infection_Rate 
WHERE location = 'United Kingdom' AND date LIKE '%2021%'
ORDER BY date;

--EVOLUTION OF COVID IN THE UNITED KINGDOM IN 2022
SELECT location, population, cast(date as DATE) AS date, 
Death_Percentage_by_cases, Infection_Rate_Population
FROM Deaths_percent_Infection_Rate 
WHERE location = 'United Kingdom' AND date LIKE '%2022%'
ORDER BY date;

----TABLE UK CASES IN 2020

CREATE VIEW UK_Total_cases_2020 AS
SELECT location, MAX(total_cases) AS Total_Cases_2020 FROM Deaths_percent_Infection_Rate 
WHERE location = 'United Kingdom' AND date LIKE '%2020%'
GROUP BY location;

----TABLE UK CASES IN 2020-2021

CREATE VIEW UK_cases_2020_2021 AS
SELECT location, MAX(total_cases) AS Total_Cases_2020_2021 FROM Deaths_percent_Infection_Rate 
WHERE location = 'United Kingdom' AND date LIKE '%2021%'
GROUP BY location;

----TABLE UK CASES IN 2021-2022

CREATE VIEW UK_cases_2021_2022 AS
SELECT location, MAX(total_cases) AS Total_Cases_2021_2022 FROM Deaths_percent_Infection_Rate 
WHERE location = 'United Kingdom' AND date LIKE '%2022%'
GROUP BY location;

--TOTAL CASES BY YEAR IN THE UK

SELECT UK_Total_cases_2020.location, Total_Cases_2020 AS Cases_2020, (Total_Cases_2020_2021-Total_Cases_2020) AS Cases_2021,
(Total_Cases_2021_2022-Total_Cases_2020_2021) AS Cases_2022, (Total_Cases_2021_2022+Total_Cases_2020_2021+Total_Cases_2020) AS Total_Cases_UK
FROM UK_cases_2020_2021, UK_cases_2021_2022, UK_Total_cases_2020;


--MAXIMUM DEATH PERCENTAGE, INFECTION RATE, CASES, DEATHS BY COUNTRY REACHED DURING THE PANDEMIC.
SELECT location, MAX(population) AS population, 
MAX(total_cases) AS total_cases_by_country, MAX(total_deaths) AS total_deaths_by_country,
MAX(Death_Percentage_by_cases) AS MAX_Death_Percentage_by_cases, MAX(Infection_Rate_Population) AS MAX_Infection_Rate_Population
FROM Deaths_percent_Infection_Rate
GROUP BY location
ORDER BY location;

--VACCINATION TABLE
SELECT * FROM Covid_vaccination
ORDER BY location, date;

--TOTAL FULLY VACCINATED BY COUNTRY (ACCURATE DATA, IT CAN BE VERIFIED ON GOOGLE)

CREATE VIEW VAccinatedbyCountry 
AS
SELECT location, MAX(cast(people_fully_vaccinated as float)) AS Total_People_Vac
FROM Covid_vaccination
WHERE continent IS NOT NULL
GROUP BY location;

--FULLY VACCINATED PEOPLE IN THE TOP 10 COUNTRIES IN THE WORLD
SELECT TOP(10) location, Total_People_Vac
FROM VAccinatedbyCountry
ORDER BY Total_People_Vac DESC;

--10 LEAST VACCINATED COUNTRIES
SELECT TOP(10) location, Total_People_Vac
FROM VAccinatedbyCountry
WHERE Total_People_Vac IS NOT NULL
ORDER BY Total_People_Vac ASC;


--NEW TABLE CONTAINING DEATH PERCENTAGE, INFECTION RATE AND TOTAL VACCINATED PEOPLE BY COUNTRY
CREATE VIEW [dbo].[Deaths_infection_Vac] AS
SELECT VAccinatedbyCountry.location, population, total_cases, total_deaths, 
Death_Percentage_by_cases, Infection_Rate_Population, Total_People_Vac
FROM Deaths_percent_Infection_Rate
LEFT JOIN VAccinatedbyCountry
ON Deaths_percent_Infection_Rate.location = VAccinatedbyCountry.location; 

--LET'S WORK OUT THE VACCINATION PERCENTAGE OF EACH COUNTRY
SELECT DISTINCT location, MAX(population) AS population, MAX(total_cases) AS MAX_total_cases, MAX(CAST(total_deaths as int)) AS MAX_total_deaths,
MAX(Death_Percentage_by_cases) AS MAX_Death_Percentage_by_cases,
ROUND(MAX(Infection_Rate_Population), 2) AS MAX_Infection_Rate_Population, MAX(Total_People_Vac) AS Fully_Vaccinated, 
ROUND(((Total_People_Vac/population) * 100), 2) AS Vaccination_Population_Percentage   
FROM Deaths_infection_Vac
WHERE total_cases IS NOT NULL AND total_deaths IS NOT NULL AND 
Death_Percentage_by_cases IS NOT NULL AND Infection_Rate_Population IS NOT NULL AND 
Total_People_Vac IS NOT NULL AND location IS NOT NULL
GROUP BY location, ((Total_People_Vac/population) * 100)
ORDER BY location;
