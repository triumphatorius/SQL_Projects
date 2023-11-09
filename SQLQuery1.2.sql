-- Select all columns from AlexProjects..CovidDeaths
SELECT *
FROM AlexProjects..CovidDeaths;

-- Select specific columns with a filter
SELECT
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM AlexProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Calculate death percentage for Moldova
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS DeathPercentage
FROM AlexProjects..CovidDeaths
WHERE location LIKE 'MOLDOVA' AND continent IS NOT NULL
ORDER BY 1, 2;

-- Calculate percentage of population infected with Covid in Moldova
SELECT
    location,
    date,
    population,
    total_cases,
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM AlexProjects..CovidDeaths
WHERE location LIKE 'MOLDOVA'
ORDER BY 1, 2;

-- Countries with the highest infection rate compared to population
SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    CAST((MAX(total_cases) / Population) * 100 AS DECIMAL(10, 2)) AS PercentPopulationInfected
FROM AlexProjects..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with the highest death count per population
SELECT
    Location,
    MAX(CAST(total_deaths AS INT)) AS Total_Deaths_Count
FROM AlexProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY Total_Deaths_Count DESC;

-- Breakdown by continent: continents with the highest death count per population
SELECT
    continent,
    MAX(CAST(total_deaths AS INT)) AS Total_Deaths_Count
FROM AlexProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Deaths_Count DESC;

-- Global numbers: total cases, total deaths, and death percentage
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM AlexProjects..CovidDeaths
WHERE continent IS NOT NULL;

-- Total Population vs Vaccinations
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM AlexProjects..CovidDeaths dea
JOIN AlexProjects..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- Using CTE to perform calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS
(
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM AlexProjects..CovidDeaths dea
    JOIN AlexProjects..CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac;

-- Temporary table to store data
USE AlexProjects; -- Specify the database

DROP TABLE IF EXISTS #TempPercentPopulationVaccinated;

CREATE TABLE #TempPercentPopulationVaccinated (
    continent NVARCHAR(250),
    location NVARCHAR(250),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #TempPercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM AlexProjects..CovidDeaths dea
JOIN AlexProjects..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated / population) * 100
FROM #TempPercentPopulationVaccinated;

-- Creating a view to store data for later visualizations
IF OBJECT_ID('PercentPopulationVaccinated', 'V') IS NOT NULL
DROP VIEW PercentPopulationVaccinated;

EXEC ('
CREATE VIEW PercentPopulationVaccinated AS  
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM 
    AlexProjects..CovidDeaths dea
JOIN 
    AlexProjects..CovidVaccinations vac
ON  
    dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
');
