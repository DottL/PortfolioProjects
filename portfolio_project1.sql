--SELECT * FROM CovidDeaths cd
--
--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM CovidDeaths cd 
--ORDER BY 1, 2
--
---- rates by COUNTRY
--SELECT location,
--	SUM(total_cases) as total_cases, 
--	MAX(CAST(total_deaths AS INT)) as total_deaths,
--	ROUND(AVG(new_cases)) as avg_cases_per_day,
--	ROUND((CAST(MAX(total_cases) AS FLOAT)/population) * 100,2) as country_infection_rate,
--	COALESCE(ROUND(MAX(CAST(total_deaths AS FLOAT))/NULLIF(MAX(total_cases),0) * 100,2),0) as disease_death_chance --after contraction
--FROM CovidDeaths cd
--WHERE continent <> ''
--GROUP BY location;
--
--
--
---- detailed death rates from case BY DATE
--SELECT location, date, population, total_deaths, total_cases, 
--	(CAST(total_cases AS FLOAT)/population) * 100 as covid_percentage,
--	ROUND(COALESCE(CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0) * 100, 0),2) as death_percentage
--FROM CovidDeaths cd
--WHERE continent IS NOT NULL
--ORDER BY location ASC;
--
---- rates by continent, included in "location" already
--SELECT continent, location,
--	SUM(total_cases) as total_cases, 
--	MAX(CAST(total_deaths AS INT)) as total_deaths,
--	ROUND(AVG(new_cases)) as avg_cases_per_day,
--	ROUND((CAST(MAX(total_cases) AS FLOAT)/population) * 100,2) as country_infection_rate,
--	COALESCE(ROUND(MAX(CAST(total_deaths AS FLOAT))/NULLIF(MAX(total_cases),0) * 100,2),0) as disease_death_chance --after contraction
--FROM CovidDeaths cd
--WHERE continent = ''
--GROUP BY location;
--
---- Global Numbers
--SELECT date, population, SUM(new_cases) as total_cases , SUM(new_deaths) as total_deaths, 
--	SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases) * 100 as death_perc
--FROM CovidDeaths cd
--WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY 1,2
--
--
---- Joins w/ vaccinations
--WITH PopvsVac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
--as(
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
--	SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinatted
--FROM CovidDeaths dea JOIN CovidVaccinations vac
--ON dea.location = vac.location and dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--)SELECT * FROM PopvsVac
--
---- Temp Table
--DROP TABLE IF exists #PercentPopulationVaccinated
--CREATE TABLE #PercentPopulationVaccinated
--(
--Continent NVARCHAR(255),
--Location NVARCHAR(255),
--Date datetime,
--Population numeric,
--RollingPeopleVaccinated numeric
--)
--
-------------------------------------------------------------------- 
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From CovidDeaths 
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths 
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths 
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths 
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths 
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths 
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths 
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths 
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths  dea JOIN CovidVaccinations vac
	on dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as INT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths  dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS )) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths  dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
