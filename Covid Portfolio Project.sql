--SELECT *
--FROM [Portfolio Project].dbo.CovidDeaths
--ORDER BY 3,4;

--SELECT *
--FROM [Portfolio Project]..CovidVaccinations
--ORDER BY 3,4;

-- Select Data we are going to be using

--SELECT Location, date, CONVERT(date, date, 101) dated, total_cases, new_cases, total_deaths, population
--FROM [Portfolio Project].dbo.CovidDeaths
--ORDER BY 1,dated;

--SELECT Location, date, total_cases, new_cases, total_deaths, population
--FROM [Portfolio Project].dbo.CovidDeaths
--ORDER BY 1,2;


SELECT *
INTO Deaths_working
FROM CovidDeaths
WHERE 1=0

INSERT INTO Deaths_working SELECT * FROM CovidDeaths;

UPDATE Deaths_working
SET date = CONVERT(date, date, 101);

UPDATE Deaths_working
SET total_cases = CONVERT(float, total_cases);

UPDATE Deaths_working
SET total_deaths = CONVERT(float, total_deaths);

ALTER TABLE Deaths_working
ALTER COLUMN total_cases FLOAT;

ALTER TABLE Deaths_working
ALTER COLUMN total_deaths FLOAT;

ALTER TABLE Deaths_working
ALTER COLUMN new_deaths FLOAT;



SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Deaths_working
ORDER BY 1,2;


-- Looking at Total Cases vs. Total Deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths / NULLIF(total_cases,0)*100) AS DeathPercentage
FROM Deaths_working
WHERE location LIKE '%Fiji%'
ORDER BY 1,2;


-- Looking at total cases vs. population

ALTER TABLE Deaths_working
ALTER COLUMN population FLOAT;

-- Shows what percentage of population got covid

SELECT Location, date, population, total_cases, (total_cases / NULLIF(population,0)*100) AS PercentPopulationInfected
FROM Deaths_working
 --WHERE location LIKE '%Fiji%'
ORDER BY 1,2;


-- Looking at Countries with highest infection rate compared to population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / NULLIF(population,0)*100)) AS PercentPopulationInfected
FROM Deaths_working
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

--SELECT location, date, total_deaths
--FROM Deaths_working
--WHERE location = 'Fiji'
--ORDER BY location;


-- Showing Countries with Highest Death Count per Population

SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM Deaths_working
GROUP BY Location
ORDER BY TotalDeathCount DESC;

SELECT *
FROM CovidDeaths
WHERE continent =''
Order by 3,4;

SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM Deaths_working
--WHERE continent != ''
GROUP BY Location
ORDER BY Location;

-- Break things down by Continent

SELECT continent, location, MAX(total_deaths) AS TotalDeathCount
FROM Deaths_working
WHERE continent = ''
GROUP BY continent, location
ORDER BY TotalDeathCount DESC;

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM Deaths_working
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM Deaths_working
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;
-- North America is only getting US and not CA data, will have to look at where continent is ''
SELECT location, MAX(total_deaths)
FROM Deaths_working
WHERE location LIKE '%states%'
GROUP BY location

-- Showing continents with highest death count per population
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM Deaths_working
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers

SELECT date, SUM(new_cases), MAX(total_cases) --, total_deaths, (total_cases / NULLIF(total_deaths,0)*100) AS DeathPercentage
FROM Deaths_working
 --WHERE location LIKE '%Fiji%'
WHERE continent !=''
GROUP BY date
ORDER BY 1,2;


SELECT * --, total_deaths, (total_cases / NULLIF(total_deaths,0)*100) AS DeathPercentage
FROM Deaths_working
 --WHERE location LIKE '%Fiji%'
WHERE continent !=''
--GROUP BY date
ORDER BY date;


SET ARITHABORT OFF;
SET ANSI_WARNINGS OFF;


SELECT SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/SUM(new_cases) *100 AS DeathPercentage --, total_deaths, (total_cases / NULLIF(total_deaths,0)*100) AS DeathPercentage
FROM Deaths_working
 --WHERE location LIKE '%Fiji%'
WHERE continent !=''
--GROUP BY date
ORDER BY 1,2;


SELECT *
FROM CovidVaccinations

UPDATE CovidVaccinations
SET date = CONVERT(date, date, 101);


UPDATE CovidVaccinations
SET new_vaccinations = CONVERT(float, new_vaccinations);

ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations FLOAT;

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, dea.date) RollingCount
-- , RollingCount/ population * 100  (can't use a variable just declared, need a CTE)
FROM Deaths_working dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent !=''
ORDER BY 2,3

-- Use CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, dea.date) RollingCount
-- , RollingCount/ population * 100  (can't use a variable just declared, need a CTE)
FROM Deaths_working dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent !=''
--ORDER BY 2,3
)
SELECT *, RollingCount/population *100
FROM PopvsVac

-- Temp table

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCount numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, dea.date) RollingCount
-- , RollingCount/ population * 100  (can't use a variable just declared, need a CTE)
FROM Deaths_working dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent !=''
--ORDER BY 2,3

SELECT *, (RollingCount/Population)*100
FROM #PercentPopulationVaccinated

-- Create View to store data for later visualizations

Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, dea.date) RollingCount
-- , RollingCount/ population * 100  (can't use a variable just declared, need a CTE)
FROM Deaths_working dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent !=''


SELECT *
FROM PercentPopulationVaccinated



CREATE VIEW Max_deaths As
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM Deaths_working
WHERE continent != ''
GROUP BY continent


