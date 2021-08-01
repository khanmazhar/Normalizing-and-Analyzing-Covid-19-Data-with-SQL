Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(CAST(new_deaths AS float))/SUM(New_Cases)*100 as DeathPercentage
From covid_data
where continent_id is not null 
order by 1,2


-- 2. 

Select continent.name, SUM(new_deaths) as TotalDeathCount
From covid_data
	JOIN continent ON continent.id = covid_data.continent_id
--Where continent_id is null 
--and location.name not in ('World', 'European Union', 'International')
Group by continent.name
order by TotalDeathCount desc


-- 3.

Select location.name, population, MAX(total_cases) as HighestInfectionCount,  Max((CAST(total_cases AS float)/population))*100 as PercentPopulationInfected
From covid_data
		JOIN location ON location.id = covid_data.location_id
Group by location.name, population
order by PercentPopulationInfected desc


-- 4.


Select location.name, population,date, MAX(total_cases) as HighestInfectionCount,  Max((CAST(total_cases AS float)/population))*100 as PercentPopulationInfected
From covid_data
		JOIN location ON location.id = covid_data.location_id 
WHERE location.name NOT IN ('International', 'World','European Union')
Group by location.name, population, date
order by PercentPopulationInfected desc
