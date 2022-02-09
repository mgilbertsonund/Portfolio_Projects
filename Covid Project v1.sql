select *
from PortfolioOne..covid_deaths
order by 3,4

--select *
--from PortfolioOne..covid_vaccinations
--order by 3,4

-- select data we will be using

select 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
from PortfolioOne..covid_deaths
order by 1,2


-- looking at total case vs total deaths
-- shows the likelihood of dying if you contract covid in a country

select 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases)*100 as death_percenatge
from PortfolioOne..covid_deaths
where location like '%states%'
order by 1,2


-- looking at total cases vs population for any country

select 
	location,
	date,
	population,
	total_cases,
	(total_cases / population)*100 as covid_positive_percentage
from PortfolioOne..covid_deaths
-- where location like '%states%'
order by 1,2


-- looking at countries with highest infection rate compared to population

select
	location,
	population,
	max(total_cases) as highest_infection_count,
	max((total_cases / population))*100 as covid_positive_percentage
from PortfolioOne..covid_deaths
group by location, population
order by covid_positive_percentage desc


-- looking at countries with the highest death count by population

select
	location,
	max(cast(total_deaths as int)) as total_deaths
from PortfolioOne..covid_deaths
where continent is not null
group by location
order by total_deaths desc


-- breaking things down by continent
-- need to filter out income classes, world and EU categories
-- because those are repeated cases that are just re-classified

select
	location,
	max(cast(total_deaths as int)) as total_deaths
from PortfolioOne..covid_deaths
where continent is null
	and location <> 'Upper middle income'
	and location <> 'High income'
	and location <> 'Lower middle income'
	and location <> 'Low income'
	and location <> 'World'
	and location <> 'European Union'
group by location
order by total_deaths desc



-- global numbers by date

select
	date,
	sum(new_cases) as total_cases,
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int)) / sum(new_cases)*100 as death_percentage
from PortfolioOne..covid_deaths
where continent is not null
group by date
order by 1,2

-- global numbers overall

select
	sum(new_cases) as total_cases,
	sum(cast(new_deaths as int)) as total_deaths,
	sum(cast(new_deaths as int)) / sum(new_cases)*100 as death_percentage
from PortfolioOne..covid_deaths
where continent is not null
order by 1,2


-- total population vs vaccinations

select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(cast(v.new_vaccinations as bigint)) over (partition by d.location 
	order by d.location, d.date) as rolling_vax_count
	-- (rolling_vax_count/d.population)*100 as percentage_population_vaccinated 
from PortfolioOne..covid_deaths d
join PortfolioOne..covid_vaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3;



-- use CTE

with PopvsVac (continent, location, date, population, new_vaccinations, rolling_vax_count)
as 
(
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(cast(v.new_vaccinations as bigint)) over (partition by d.location 
	order by d.location, d.date) as rolling_vax_count
	-- (rolling_vax_count/d.population)*100 as percentage_population_vaccinated 
from PortfolioOne..covid_deaths d
join PortfolioOne..covid_vaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
-- order by 2,3;
)
select *, (rolling_vax_count/population)*100 as percentage_population_vaccinated 
from PopvsVac



-- temp table

drop table is exists #percent_population_vaccinated
create table #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vax_count numeric
)

insert into #percent_population_vaccinated
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(cast(v.new_vaccinations as bigint)) over (partition by d.location 
	order by d.location, d.date) as rolling_vax_count
	-- (rolling_vax_count/d.population)*100 as percentage_population_vaccinated 
from PortfolioOne..covid_deaths d
join PortfolioOne..covid_vaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
-- order by 2,3;

select  *, (rolling_vax_count/population)*100 as percentage_population_vaccinated 
from #percent_population_vaccinated



-- create view for later visualizations

create view percent_population_vaccinated as
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(cast(v.new_vaccinations as bigint)) over (partition by d.location 
	order by d.location, d.date) as rolling_vax_count
	-- (rolling_vax_count/d.population)*100 as percentage_population_vaccinated 
from PortfolioOne..covid_deaths d
join PortfolioOne..covid_vaccinations v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
-- order by 2,3;

select *
from percent_population_vaccinated