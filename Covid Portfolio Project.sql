select *
From PortfolioProject.dbo.CovidDeaths
order by 3,4

--select *
--From PortfolioProject..CovidVaccinations
--order by 3,4

--Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%states%'
order by 1,2

--Looking at Total Cases vs Population
--shows what percentage of population got covid
Select Location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
where location like '%states%' 
order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--where location like '%states%' 
Group by Location, Population
order by PercentPopulationInfected desc

--Showing Countries with Highest Death Count per Population
Select Location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%states%' 
Group by Location, Population
order by TotalDeathCount desc

--convert the nvarchar(255) to numerical
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%states%' 
Group by Location, Population
order by TotalDeathCount desc

--Get rid of those huge scope record like "World" or "Africa" 
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%states%' 
where continent is not null
Group by Location, Population
order by TotalDeathCount desc


--Let's break things down by continent
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%states%' 
where continent is not null
Group by Continent
order by TotalDeathCount desc

--just let the scopes show up
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%states%' 
where continent is null
Group by location
order by TotalDeathCount desc

--showing continents with the highest death count per population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like '%states%' 
where continent is not null
Group by Continent
order by TotalDeathCount desc

--global numbers

select date, sum(new_cases)as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
Group by date
order by 1,2

--total cases
select sum(new_cases)as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
--Group by date
order by 1,2


--looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location)
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--but every sum per country shows exact the same number
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location Order by dea.location,
dea.Date) as RollingPeopleVaccinated--add RollingPeopleVaccinated
--but we can not use this name directly, so here is two options
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3
--Above can add up every single one 

--No.1 OPTION: USE CTE
With PopvsVac(Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location Order by dea.location,
dea.Date) as RollingPeopleVaccinated--add RollingPeopleVaccinated
--but we can not use this name directly, so here is two options
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

--No.2
--TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location Order by dea.location,
dea.Date) as RollingPeopleVaccinated--add RollingPeopleVaccinated
--but we can not use this name directly, so here is two options
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3 

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

--creating view to store data for later visulizations

create View PercentaPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location Order by dea.location,
dea.Date) as RollingPeopleVaccinated--add RollingPeopleVaccinated
--but we can not use this name directly, so here is two options
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3 

select *
from PercentaPopulationVaccinated