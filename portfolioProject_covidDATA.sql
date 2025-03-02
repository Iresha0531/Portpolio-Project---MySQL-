select * 
from coviddeaths
;

select * from covidvaccinations;

#select columns we are going to be using in the project

select continent, location, `date`,population, total_cases, new_cases, total_deaths, new_deaths
from coviddeaths
;

select continent, location, `date`, total_vaccinations, new_vaccinations
from covidvaccinations;

#countries with no covida cases at the time 

with cte_no_covidcases_countries as 
(
select location, sum(new_cases) as tot_case
from coviddeaths
where continent is not null
group by location
order by 2 desc
)
select location
from cte_no_covidcases_countries
where tot_case is null
;

#looking at total cases vs total deaths
#likelihood of dyning if anyone gets contact with covid 

select location, `date`, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from coviddeaths
where total_deaths is not null 
and continent is not null
and location like '%states%'
order by 3 desc
;

#find out if there any country without ant covid death so far

select location, `date`, total_cases, total_deaths
from coviddeaths
where total_deaths is null and total_cases is not null
and continent is not null
#order by 3 desc
;

#sohw what percentage of populaltion got covid in the USA

select location, population, `date`, total_cases, (total_cases/population)*100 as CovidCasesPerCountry
from coviddeaths
where continent is not null
and location like '%states%'
order by 4 desc
;

#countries that has highest infection rate compare to population
 
select location, population, max(total_cases) ,(max(total_cases)/population)*100 as maxCovidCasesPerCountry
from coviddeaths
where continent is not null
group by location, population
order by 4 desc
;

select location, population, max(total_cases) , (max(total_cases)/population)*100 as maxCovidCasesPerContinent
from coviddeaths
where continent is null
group by location, population
;

#looking countries with highest death count per population
# highest per day

select location, population, max(cast(new_deaths as signed)) as maxDeathCount,
(max(cast(new_deaths as signed))/population)*100 as maxCovidDeathsPerCountry
from coviddeaths
where continent is not null
#and location like '%states%'
group by location, population
order by 1 desc
;   
    
#total deaths percentage of a countries population

select continent,population, sum(cast(new_deaths as signed)) as sumDeathCount,
(sum(cast(new_deaths as signed))/population)*100 as CovidDeathsPerCountry
from coviddeaths
where continent is not null
group by continent, population
order by 2 desc
;  
    
#total deaths of a continent    

select continent, sum(cast(new_deaths as signed)) as sumDeathCount
from coviddeaths
where continent is not null
group by continent
order by 2 desc
; 

#death percantage by cases, by day

select `date`, sum(new_cases) as cases, sum(cast(new_deaths as signed)) as deaths,
(sum(cast(new_deaths as signed))/sum(new_cases))*100 as deathPercentage
from coviddeaths
where continent is not null
group by `date`
order by 4 desc
;

#global deaths 

select sum(new_cases) as cases, sum(cast(new_deaths as signed)) as deaths,
(sum(cast(new_deaths as signed))/sum(new_cases))*100 as deathPercentage
from coviddeaths
where continent is not null;

# looking data of vaccinations

# highest number of people vaccinated by a country

select location, sum(cast(new_vaccinations as signed))
from covidvaccinations
where continent is not null
group by location
order by 2 desc
;

#countries that has not yet started vaccination

with cte_no_vaccination_countries as 
(
select location, sum(cast(new_vaccinations as signed)) as total_vaccin
from covidvaccinations
where continent is not null
group by location
order by 2 desc
)
select location
from cte_no_vaccination_countries
where total_vaccin is null
;

#JOIN tables

select de.continent, de.location, de.`date`, de.population, de.new_cases, va.new_vaccinations
from coviddeaths as de
join covidvaccinations as va
	on de.`date` = va.`date` and de.location = va.location
;

#looking data of total population vs vaccination

select  de.`date`, de.population, sum(cast(va.new_vaccinations as signed)) as vaccinated
from coviddeaths as de
join covidvaccinations as va
	on de.`date` = va.`date` and de.location = va.location
group by de.`date`, de.population
;

select de.location,  de.`date`, de.population,cast(va.new_vaccinations as signed) as _new_vaccinations,
sum(cast(va.new_vaccinations as signed)) over (partition by de.location order by va.location, va.`date`) as rolling_sum
from coviddeaths as de
join covidvaccinations as va
	on de.`date` = va.`date` and de.location = va.location
where de.continent is not null
order by 1 desc
;

with cte_total_vaccinate_population as
(
select de.location,  de.`date`, de.population, cast(va.new_vaccinations as signed) as _new_vaccinations,
sum(cast(va.new_vaccinations as signed)) over (partition by de.location order by va.location, va.`date`) as rolling_sum
from coviddeaths as de
join covidvaccinations as va
	on de.`date` = va.`date` and de.location = va.location
where de.continent is not null
order by 1 
)
select *, (rolling_sum/ population)*100 as vaccination_percentage
from cte_total_vaccinate_population
where _new_vaccinations is not null and location like '%state%'
;

#creat a TEMPORARY table

create temporary table vaccination_count
(
continent varchar (225),
location varchar (225),
`date` date ,
population int,
new_vaccination numeric,
rolling_vaccination_total numeric
);

insert vaccination_count
select de.continent, de.location, de.`date`, de.population, cast(va.new_vaccinations as signed),
sum(cast(va.new_vaccinations as signed)) over (partition by de.location order by va.location, va.`date`)
from coviddeaths as de
join covidvaccinations as va
	on de.`date` = va.`date` and de.location = va.location
;

select * , (rolling_vaccination_total/population)*100 as percentage_vaccinated
from vaccination_count
where continent is not null and new_vaccination is not null
;



