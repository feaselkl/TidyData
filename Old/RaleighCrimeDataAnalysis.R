#This is a demo to perform basic analysis on our Raleigh Crime dataset in R.
#In this demo, we will perform basic analysis, particularly around quick visualization.
install.packages('tidyverse', repos = "http://cran.us.r-project.org")
install.packages('RODBC', repos = "http://cran.us.r-project.org")
install.packages('ggplot2', repos = "http://cran.us.r-project.org")

library(tidyverse)
library(RODBC)
library(ggplot2)
library(scales)


conn <- odbcDriverConnect("driver={SQL Server};server=LOCALHOST;database=RaleighCrime;trusted_connection=true")
raleighcrime <- sqlQuery(conn,
  "SELECT
	i.BeatID,
	i.IncidentCode,
	ic.IncidentDescription,
	it.IncidentType,
	i.IncidentDate,
	i.IncidentNumber
FROM dbo.Incident i
	INNER JOIN dbo.IncidentCode ic
		ON i.IncidentCode = ic.IncidentCode
	INNER JOIN dbo.IncidentType it
		ON ic.IncidentTypeID = it.IncidentTypeID;"
)

#Following are common techniques for visualizing data to help find outliers.
str(raleighcrime)
#First let's do a little bit of cleanup.
raleighcrime$IncidentNumber <- as.character(raleighcrime$IncidentNumber)
raleighcrime$IncidentCode <- as.character(raleighcrime$IncidentCode)
raleighcrime$IncidentType <- as.character(raleighcrime$IncidentType)
raleighcrime$IncidentDescription <- as.character(raleighcrime$IncidentDescription)
raleighcrime$IncidentYear <- as.integer(format(raleighcrime$IncidentDate, format="%Y"))
raleighcrime$IncidentMonth <- as.integer(format(raleighcrime$IncidentDate, format="%m"))
raleighcrime$IncidentDay <- as.integer(format(raleighcrime$IncidentDate, format="%d"))

#Next, let's remove any NA/bad values using the built-in complete.cases function.
raleighcrime <- raleighcrime[complete.cases(raleighcrime), ]
#We didn't lose any records, which tells us we aren't missing any data points.
str(raleighcrime)

#Then let's create a couple groups of data.
raleigh.crime.by.year <- raleighcrime %>% group_by(IncidentYear) %>% summarize(n = n())
raleigh.crime.by.incident.type <- raleighcrime %>% group_by(IncidentType) %>% summarize(n = n())

#Scatter plot shows that we don't have much data for 2014.  Probably an incomplete year...
plot(raleigh.crime.by.year)

#Histogram shows that most of the categories have 10K or fewer entries,
#but a couple show up very frequently.
hist(raleigh.crime.by.incident.type$n)
#We can dig into which incident types are very "popular."
raleigh.crime.by.incident.type %>% filter(n >= 80000) %>% arrange(n)
#The result:  Larceny and Miscellaneous.
#What about mid-range incidents?
raleigh.crime.by.incident.type %>% filter(n >= 20000, n < 80000) %>% arrange(n)
#This shows the four next most-popular types.

#Box and whisker plot
raleigh.crime.by.type.and.month <- raleighcrime %>% 
                                    filter(IncidentYear < 2014) %>% 
                                    group_by(IncidentType, IncidentYear, IncidentMonth) %>% 
                                    summarize(n = n())
popular.crimes <- raleigh.crime.by.incident.type %>% filter(n >= 20000)
#Join to the popular crimes list to filter out less common incidents.
popular.crimes.by.type.and.month <- merge(x = raleigh.crime.by.type.and.month, 
                                          y = popular.crimes,
                                          by = "IncidentType")

#Are there radical differences in police write-ups for these incidents?
boxplot(n.x ~ IncidentType, data = popular.crimes.by.type.and.month,
        xlab="Incident Type", ylab="Number of incidents per month")
#Not really.  We see two outliers (n outside 1.5 * IQR) in the data set.

#What about by beat?
incidents.by.beat <- raleighcrime %>%
  group_by(IncidentType, BeatID) %>%
  summarize(n = n())
popular.incidents.by.beat <- merge(x = incidents.by.beat, 
                                   y = popular.crimes,
                                   by = "IncidentType")
boxplot(n.x ~ IncidentType, data = popular.incidents.by.beat,
        xlab="Incident Type", ylab="Number of incidents by beat")
#Interesting result:  some major outliers for certain incident types.
#Might be worth further investigation.

#Let's focus down to a particular incident type.
prostitution.by.beat <- raleighcrime %>%
                      filter(IncidentType == "PROSTITUTION") %>% 
                      group_by(BeatID) %>%
                      summarize(n = n())
plot(prostitution.by.beat)


#The QQ (Quantile-Quantile) plot tells how far our data is off the expected distribution.
#The closer the plot is to a straight line with a 45 degree angle, the closer the distributional fit.
#Let's suppose we think the number of incidents by month follows a normal distribution.
raleigh.crime.by.month <- raleighcrime %>% 
  filter(IncidentYear < 2014) %>% 
  group_by(IncidentYear, IncidentMonth) %>% 
  summarize(n = n())

#qqnorm is a version of qqplot which compares against a normal distribution.
#qqline draws a line which passes through the 1st and 3rd quartiles.
sdres <- sd(raleigh.crime.by.month$n)
m <- mean(raleigh.crime.by.month$n)
raleigh.crime.by.month$sd <- ((as.double(raleigh.crime.by.month$n) - m)/sdres)

qqnorm(raleigh.crime.by.month$sd)
qqline(raleigh.crime.by.month$sd)
#The assumption that the number of incidents follows a normal distribution isn't a terrible
#assumption, but it's not very good:  far too many months have too few incidents.

#We can look at incidents by month with a simple time-series analysis.
raleighcrime.timeseries <- raleighcrime %>% filter(IncidentYear < 2014)
raleighcrime.timeseries$IncidentCount <- 1
raleighcrime.timeseries$Month <- as.Date(cut(raleighcrime.timeseries$IncidentDate, breaks = "month"))
ggplot(data = raleighcrime.timeseries, aes(x = Month, y = IncidentCount)) +
  stat_summary(fun.y = sum, geom = "line") +
  scale_x_date(labels = date_format("%Y-%m"), breaks = date_breaks("year"))
#It seems that the number of incidents drops sharply each year...but that coincides with February.

