#This is a demo to walk through dplyr.
#dplyr is another of the tidyverse packages, and we've already seen a little bit of it.
#This demo is based on a blog post by Gerald Belton, with my additions.
#https://www.r-bloggers.com/more-tidyverse-using-dplyr-functions/

install.packages('tidyverse', repos = "http://cran.us.r-project.org")
install.packages('gapminder', repos = "http://cran.us.r-project.org")

library(tidyverse)
library(gapminder)

#Basic filter
filter(gapminder, lifeExp < 30)
filter(gapminder, lifeExp > 81.5)

#Filter two variables using an AND clause
#Desired:  get countries with a population of at least 200 million
#and a GDP per capita of at least $36,000.
filter(gapminder, pop > 20000000, gdpPercap > 36000)

#Filter two variables using an OR clause
#Desired:  get countries with a population of at least 1.2 billion
#or a GDP per capita of at least $100,000.
filter(gapminder, pop > 1200000000 | gdpPercap > 100000)

#Selecting rows
select(gapminder, year, lifeExp)

#Using the pipe to combine operations
gapminder %>%
  filter(pop > 1200000000) %>%
  select(country, year, lifeExp)

#Mutate data
#We are now going to use a new data set called new_gap
#for the rest of our analysis.
new_gap <- gapminder %>%
  mutate(gdp = pop * gdpPercap)
head(new_gap)

#Sort data ascending
new_gap %>%
  arrange(gdp, year) %>%
  head(10)

#Sort data descending
#Desired:  retrieve the top 10 records sorted by GDP descending
#and then continent ascending.
new_gap %>%
  arrange(desc(gdp), continent) %>%
  head(10)

#Grouping and summarizing
new_gap %>%
  group_by(continent) %>%
  summarize(n = n())

#Average life expectancy for the entire data series
new_gap %>%
  group_by(continent) %>%
  summarize(avg_lifeExp = mean(lifeExp))

#Desired:  Average life expectancy by continent in 1952
new_gap %>%
  filter(year == 1952) %>%
  group_by(continent) %>%
  summarize(avg_lifeExp = mean(lifeExp))

#Desired:  Average life expectancy by continent in 2007
new_gap %>%
  filter(year == 2007) %>%
  group_by(continent) %>%
  summarize(avg_lifeExp = mean(lifeExp))

#Putting it all together
#Biggest single-period life expectancy drops
new_gap %>%
  select(country, year, continent, lifeExp) %>%
  group_by(continent, country) %>%
  ## within country, take (lifeExp in year i) - (lifeExp in year i - 1)
  ## positive means lifeExp went up, negative means it went down
  mutate(le_delta = lifeExp - lag(lifeExp)) %>% 
  ## within country, retain the worst lifeExp change = smallest or most negative
  summarize(worst_le_delta = min(le_delta, na.rm = TRUE)) %>% 
  ## within continent, retain the row with the lowest worst_le_delta
  top_n(-1, wt = worst_le_delta) %>% 
  arrange(worst_le_delta)

#Desired: Biggest single-period life expectancy gains
new_gap %>%
  select(country, year, continent, lifeExp) %>%
  group_by(continent, country) %>%
  mutate(le_delta = lifeExp - lag(lifeExp)) %>% 
  summarize(best_le_delta = max(le_delta, na.rm = TRUE)) %>% 
  top_n(1, wt = best_le_delta) %>% 
  arrange(best_le_delta)

#Desired:  Biggest single-period GDP per capita increases
new_gap %>%
  select(country, year, continent, gdpPercap) %>%
  group_by(continent, country) %>%
  mutate(gdp_delta = gdpPercap - lag(gdpPercap)) %>% 
  summarize(best_gdp_delta = max(gdp_delta, na.rm = TRUE)) %>% 
  top_n(1, wt = best_gdp_delta) %>% 
  arrange(best_gdp_delta)
