DROP TABLE IF EXISTS covid_raw;

--creating a table to store raw data
CREATE TABLE covid_raw (
	iso_code VARCHAR(128),
	continent VARCHAR(128),
	location VARCHAR(128),
	date date,
	population BIGINT,
	total_cases BIGINT,
	new_cases INTEGER,
	total_deaths BIGINT,
	new_deaths INTEGER,
	new_tests INTEGER,
	total_tests BIGINT,
	total_vaccinations BIGINT,
	people_vaccinated BIGINT,
	people_fully_vaccinated BIGINT,
	new_vaccinations INTEGER
);

--importing data into the table from a CSV file
--command " "\\copy public.covid_raw (iso_code, continent, location, date, populataion, total_cases, new_cases, total_deaths, new_deaths, new_tests, total_tests, total_vaccinations, people_vaccinated, people_fully_vaccinated, new_vaccinations) FROM 'C:/Users/tech/Desktop/PROTOF~1/OWID-C~1.CSV' DELIMITER ',' CSV HEADER ENCODING 'UTF8' QUOTE '\"' ESCAPE '''';""

--inspecting the data
SELECT * FROM covid_raw WHERE location IN (SELECT location.name FROM location);

--Normalizaing the database: There are three columns with repeated string values. These columns are iso_code, continent, and location
--creating separate tables for iso_code, continent, and location
DROP TABLE IF EXISTS iso_code;
CREATE TABLE iso_code (
	id SERIAL,
	name VARCHAR(128),
	PRIMARY KEY(id)
);

DROP TABLE IF EXISTS continent;
CREATE TABLE continent (
	id SERIAL,
	name VARCHAR(128) UNIQUE,
	PRIMARY KEY(id)
);

DROP TABLE IF EXISTS location;
CREATE TABLE location (
	id SERIAL,
	name VARCHAR(128) UNIQUE,
	PRIMARY KEY(id)
);

-- We now have 4 tables in our database
-- inserting data from covid_raw to our newly created tables
INSERT INTO iso_code (name) 
SELECT DISTINCT covid_raw.iso_code 
FROM covid_raw;
--check to see if the data is properly inserted into iso_code table
SELECT * FROM iso_code;

--inserting data into continent table
INSERT INTO continent (name)
SELECT DISTINCT covid_raw.continent
FROM covid_raw
WHERE continent IS NOT NULL;
--check to see if the data is properly inserted into continent table
SELECT * FROM continent;

--inserting data into location table
INSERT INTO location (name)
SELECT DISTINCT covid_raw.location
FROM covid_raw
WHERE location NOT IN (SELECT continent.name FROM continent);
--check to see if the data is properly inserted into location table
SELECT * FROM location;

--creating a final table that will contain data without repeating strings
DROP TABLE IF EXISTS covid_data;
CREATE TABLE covid_data (
	iso_code_id INTEGER,
	continent_id INTEGER,
	location_id INTEGER,
	iso_code VARCHAR(128),
	continent VARCHAR(128),
	location VARCHAR(128),
	date date,
	population BIGINT,
	total_cases BIGINT,
	new_cases INTEGER,
	total_deaths BIGINT,
	new_deaths INTEGER,
	new_tests INTEGER,
	total_tests BIGINT,
	total_vaccinations BIGINT,
	people_vaccinated BIGINT,
	people_fully_vaccinated BIGINT,
	new_vaccinations INTEGER
);
--inserting data into covid_data table
INSERT INTO covid_data (iso_code,continent,location,date,population,total_cases,new_cases,total_deaths,new_deaths,new_tests,total_tests,total_vaccinations,people_vaccinated,people_fully_vaccinated,new_vaccinations)
SELECT iso_code,continent,location,date,population,total_cases,new_cases,total_deaths,new_deaths,new_tests,total_tests,total_vaccinations,people_vaccinated,people_fully_vaccinated,new_vaccinations
FROM covid_raw;
--inspection
SELECT * FROM covid_data;

--updating the iso_code_is, continent_id, and location_id in the covid_data table
UPDATE covid_data SET iso_code_id = (SELECT iso_code.id FROM iso_code WHERE covid_data.iso_code = iso_code.name);
UPDATE covid_data SET continent_id = (SELECT continent.id FROM continent WHERE covid_data.continent = continent.name);
UPDATE covid_data SET location_id = (SELECT location.id FROM location WHERE covid_data.location = location.name);

--at this stage, we have a normalized database, and we can drop iso_code,location, and continent columns from covid_data table
ALTER TABLE covid_data DROP COLUMN iso_code;
ALTER TABLE covid_data DROP COLUMN continent;
ALTER TABLE covid_data DROP COLUMN location;

--Now that we have our tables set up, we can go ahead and delete the covid_raw table
DROP TABLE IF EXISTS covid_raw;

--now we only have numbers in out main table.i.e covid_data table. this will make our database very efficient
SELECT iso_code.name AS iso_code,continent.name AS continent,location.name AS location, date,covid_data.population, total_cases, new_cases, total_deaths
FROM covid_data 
	JOIN iso_code ON covid_data.iso_code_id = iso_code.id 
	JOIN continent ON covid_data.continent_id = continent.id 
	JOIN location ON covid_data.location_id = location.id
ORDER BY 3;

-- ANALYSIS
--Select the dates we are going to work
SELECT location.name AS location,date,total_cases, new_cases, total_deaths,population
FROM covid_data 
	JOIN location ON covid_data.location_id = location.id
ORDER BY 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location.name, date, total_cases,total_deaths, (CAST(total_deaths AS float)/total_cases)*100 as DeathPercentage
From covid_data
	JOIN location ON covid_data.location_id = location.id
ORDER BY 1,2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location.name, date, population, total_cases,  (CAST(total_cases AS float)/population)*100 as PercentPopulationInfected
FROM covid_data
	JOIN location ON covid_data.location_id = location.id
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population
Select location.name, population, MAX(total_cases) as HighestInfectionCount,  Max((CAST(total_cases AS float)/population))*100 as PercentPopulationInfected
From covid_data
	JOIN location ON covid_data.location_id = location.id
WHERE total_cases IS NOT NULL AND population IS NOT NULL
Group by location.name, population
order by PercentPopulationInfected desc;

--Countries with the Highest Death Count per population
SELECT location.name, population, MAX(total_deaths) AS HighestDeathCOunt, MAX((CAST(total_deaths AS float)/population))*100 AS percent_population_deaths
FROM covid_data
	JOIN location ON covid_data.location_id = location.id
WHERE total_deaths IS NOT NULL AND population IS NOT NULL AND continent_id IS NOT NULL
GROUP BY location.name, population 
ORDER BY 3 DESC;

-- Breaking things up by continent
SELECT continent.name, SUM(population) AS population_worldwide, SUM(total_deaths) AS total_death_count_worldwide, SUM(total_cases) as total_cases_worldwide,(SUM(total_deaths)/SUM(total_cases))*100 AS death_rate
FROM covid_data
	JOIN continent ON covid_data.continent_id = continent.id
GROUP BY continent.name
ORDER BY 2 DESC;

-- GLOBAL NUMBERS
SELECT  SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, ((SUM(new_deaths))/SUM((CAST(new_cases AS FLOAT)))) * 100 AS death_percentage
FROM covid_data 
WHERE continent_id IS NOT NULL
ORDER BY 1,2;

-- Total population vs vaccination
SELECT continent.name,location.name, date, population, new_vaccinations,
SUM(new_vaccinations) OVER (PARTITION BY location.name ORDER BY location.name, date) AS rolling_vaccinations
FROM covid_data
	JOIN continent ON covid_data.continent_id = continent.id 
	JOIN location ON covid_data.location_id = location.id
WHERE continent_id IS NOT NULL
ORDER BY 2,3;

--calculating rolling vaccinations percentage using CTE
WITH pop_vs_vac (continent,location,date,populataion,new_vaccinations,rolling_vaccinations)
AS
(
	SELECT continent.name,location.name, date, population, new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS rolling_vaccinations
	FROM covid_data
		JOIN continent ON covid_data.continent_id = continent.id 
		JOIN location ON covid_data.location_id = location.id
	WHERE continent_id IS NOT NULL
)
SELECT *, (CAST(rolling_vaccinations AS float)/populataion)*100 AS rolling_vacc_percentage FROM pop_vs_vac;

--calculating rolling vaccinations percentage using temp tables
CREATE TEMPORARY TABLE pop_vs_vac (
	continent VARCHAR(128),
	location VARCHAR(128),
	date date,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_vaccinations NUMERIC
);
INSERT INTO pop_vs_vac (continent,location,date,population,new_vaccinations,rolling_vaccinations) 
SELECT continent.name,location.name, date, population, new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY location.name ORDER BY location.name, date) AS rolling_vaccinations
FROM covid_data
	JOIN continent ON covid_data.continent_id = continent.id 
	JOIN location ON covid_data.location_id = location.id
WHERE continent_id IS NOT NULL;

SELECT *, (CAST(rolling_vaccinations AS float)/population)*100 AS rolling_vacc_percentage 
FROM pop_vs_vac;

--creating view for later visualization
CREATE VIEW percent_pop_vac AS
SELECT continent.name AS continent,location.name AS location, date, population, new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY location.name ORDER BY location.name, date) AS rolling_vaccinations
FROM covid_data
	JOIN continent ON covid_data.continent_id = continent.id 
	JOIN location ON covid_data.location_id = location.id
WHERE continent_id IS NOT NULL;

