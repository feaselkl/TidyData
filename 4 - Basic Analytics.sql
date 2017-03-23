USE [RaleighCrime]
GO
/*
GROUPS
The GROUP BY operator has a few useful options for grouping data.
This will cover each of the options.
*/

--Basic GROUP BY:
SELECT
	COUNT(*) AS NumberOfIncidents
FROM dbo.Incident i;

--Basic GROUP BY with a field:
SELECT
	i.IncidentCode,
	COUNT(*) AS NumberOfIncidents
FROM dbo.Incident i
GROUP BY
	IncidentCode
ORDER BY
	IncidentCode ASC;

--Basic GROUP BY with two fields:
SELECT
	i.IncidentCode,
	MONTH(i.IncidentDate) as IncidentMonth,
	COUNT(*) AS NumberOfIncidents
FROM dbo.Incident i
GROUP BY
	i.IncidentCode,
	MONTH(i.IncidentDate)
ORDER BY
	IncidentCode ASC,
	IncidentMonth DESC;

--The ROLLUP command lets you roll up a hierarchy easily.
--It's easiest to understand if you have the hierarchy go
--from left to right:  an incident type has multiple incident descriptions.
--In this case, NULL means "all values"
SELECT
	it.IncidentType,
	ic.IncidentDescription,
	COUNT(*) AS NumberOfIncidents
FROM dbo.Incident i
	INNER JOIN dbo.IncidentCode ic
		ON i.IncidentCode = ic.IncidentCode
	INNER JOIN dbo.IncidentType it
		ON ic.IncidentTypeID = it.IncidentTypeID
GROUP BY
	it.IncidentType,
	ic.IncidentDescription
WITH ROLLUP;

--The CUBE command lets you build out a matrix of results.
--It's best for non-hierarchical data.
--To be honest, I rarely use CUBE.
SELECT
	it.IncidentType,
	YEAR(i.IncidentDate) AS IncidentYear,
	COUNT(*) AS NumberOfIncidents
FROM dbo.Incident i
	INNER JOIN dbo.IncidentCode ic
		ON i.IncidentCode = ic.IncidentCode
	INNER JOIN dbo.IncidentType it
		ON ic.IncidentTypeID = it.IncidentTypeID
GROUP BY
	it.IncidentType,
	YEAR(i.IncidentDate)
WITH CUBE;

--GROUPING SETS gives you fine-grained control over what aggregations you see.
SELECT
	it.IncidentType,
	ic.IncidentCode,
	YEAR(i.IncidentDate) AS IncidentYear,
	COUNT(*) AS NumberOfIncidents
FROM dbo.Incident i
	INNER JOIN dbo.IncidentCode ic
		ON i.IncidentCode = ic.IncidentCode
	INNER JOIN dbo.IncidentType it
		ON ic.IncidentTypeID = it.IncidentTypeID
GROUP BY GROUPING SETS
(
	--Classic GROUP BY
	(
		it.IncidentType,
		ic.IncidentCode,
		YEAR(i.IncidentDate)
	),
	--Breakdown of type & year (will leave IncidentCode NULL)
	(
		it.IncidentType,
		YEAR(i.IncidentDate)
	),
	--Grand total
	()
);

/*
PIVOTS
You can pivot and unpivot data in SQL Server with a few commands.

PIVOT turns rows into columns
DaysToManufacture          AverageCost
0                          5.0885
1                          223.88
2                          359.1082
4                          949.4105

becomes

Cost_Sorted_By_Production_Days    0         1         2           3       4       
AverageCost                       5.0885    223.88    359.1082    NULL    949.4105

UNPIVOT turns columns into rows, so it does the opposite of PIVOT.

Unpivoting data can be used as part of tidying, as you may have multiple
columns that you need to convert to rows of data.  Sometimes you may need to
pivot data to break out of Entity-Attribute-Value or key-value tables into
something which fits a relational structure.
*/

--Use PIVOT to get the number of incidents by incident type
--per year for the years 2011, 2012, 2013.  [2011], [2012], and [2013] will be
--the new columns.
SELECT
	IncidentType,
	[2011],
	[2012],
	[2013]
FROM
(
	SELECT
		it.IncidentType,
		i.IncidentDate,
		YEAR(i.IncidentDate) AS IncidentYear
	FROM dbo.Incident i
		INNER JOIN dbo.IncidentCode ic
			ON i.IncidentCode = ic.IncidentCode
		INNER JOIN dbo.IncidentType it
			ON ic.IncidentTypeID = it.IncidentTypeID
	WHERE
		i.IncidentDate >= '2011-01-01'
		AND i.IncidentDate < '2014-01-01'
) AS src
PIVOT
(
	COUNT(IncidentDate)
	FOR IncidentYear IN ([2011], [2012], [2013])
) AS p;

--You can also use MAX(CASE) to perform pivoting without the PIVOT operator.
--There are advantages and disadvantages to this; I tend to find the syntax
--easier to remember.
SELECT
	it.IncidentType,
	SUM(CASE WHEN i.IncidentDate >= '2011-01-01' AND i.IncidentDate < '2012-01-01' THEN 1 ELSE 0 END) AS [2011],
	SUM(CASE WHEN i.IncidentDate >= '2012-01-01' AND i.IncidentDate < '2013-01-01' THEN 1 ELSE 0 END) AS [2012],
	SUM(CASE WHEN i.IncidentDate >= '2013-01-01' AND i.IncidentDate < '2014-01-01' THEN 1 ELSE 0 END) AS [2013]
FROM dbo.Incident i
	INNER JOIN dbo.IncidentCode ic
		ON i.IncidentCode = ic.IncidentCode
	INNER JOIN dbo.IncidentType it
		ON ic.IncidentTypeID = it.IncidentTypeID
WHERE
	i.IncidentDate >= '2011-01-01'
	AND i.IncidentDate < '2014-01-01'
GROUP BY
	it.IncidentType;

--Similarly, you can unpivot data using the UNPIVOT command.  I leave
--that as an exercise to the reader.

/*
WINDOW FUNCTIONS
Window functions are extremely useful SQL functions which
allow you to look at "windows" of data, like specific timeframes.
*/

--Running totals using ROW_NUMBER().
--We want to track the count of each incident by type throughout March 2013.
SELECT
	it.IncidentType,
	i.IncidentDate,
	ROW_NUMBER() OVER (PARTITION BY it.IncidentType ORDER BY i.IncidentDate ASC) AS NumIncidents
FROM dbo.Incident i
	INNER JOIN dbo.IncidentCode ic
		ON i.IncidentCode = ic.IncidentCode
	INNER JOIN dbo.IncidentType it
		ON ic.IncidentTypeID = it.IncidentTypeID
WHERE
	i.IncidentDate >= '2013-03-01'
	AND i.IncidentDate < '2013-04-01'
ORDER BY
	i.IncidentDate,
	it.IncidentType;

--Suppose an anti-crime initiative started in July 2013.  We want to see
--if there is a positive effect per incident type over the next three months
--(July, August, September).  We can use the LAG function to look back and the LEAD
--function to look forward.
WITH monthlyResults AS
(
	SELECT
		it.IncidentType,
		MONTH(i.IncidentDate) AS IncidentMonth,
		COUNT(1) AS NumberOfIncidents
	FROM dbo.Incident i
		INNER JOIN dbo.IncidentCode ic
			ON i.IncidentCode = ic.IncidentCode
		INNER JOIN dbo.IncidentType it
			ON ic.IncidentTypeID = it.IncidentTypeID
	WHERE
		i.IncidentDate >= '2013-07-01'
		AND i.IncidentDate < '2013-10-01'
	GROUP BY
		it.IncidentType,
		MONTH(i.IncidentDate)
),
comparison AS
(
	SELECT
		mr.IncidentType,
		mr.IncidentMonth,
		LAG(mr.NumberOfIncidents) OVER (PARTITION BY mr.IncidentType ORDER BY mr.IncidentMonth) AS LastMonthIncidents,
		mr.NumberOfIncidents AS ThisMonthIncidents,
		LEAD(mr.NumberOfIncidents) OVER (PARTITION BY mr.IncidentType ORDER BY mr.IncidentMonth) AS NextMonthIncidents
	FROM monthlyResults mr
)
SELECT
	c.IncidentType,
	c.LastMonthIncidents AS JulyIncidents,
	c.ThisMonthIncidents AS AugustIncidents,
	c.NextMonthIncidents AS SeptemberIncidents
FROM comparison c
WHERE
	c.IncidentMonth = 8
ORDER BY
	c.IncidentType;

--We want to rank incident types in order of prevelance in the year 2013.
WITH incidentTypes AS
(
	SELECT
		it.IncidentType,
		COUNT(1) AS NumberOfIncidents
	FROM dbo.Incident i
		INNER JOIN dbo.IncidentCode ic
			ON i.IncidentCode = ic.IncidentCode
		INNER JOIN dbo.IncidentType it
			ON ic.IncidentTypeID = it.IncidentTypeID
	WHERE
		i.IncidentDate >= '2013-01-01'
		AND i.IncidentDate < '2014-01-01'
	GROUP BY
		it.IncidentType
)
SELECT
	it.IncidentType,
	it.NumberOfIncidents,
	DENSE_RANK() OVER (ORDER BY NumberOfIncidents DESC) AS IncidentRank
FROM incidentTypes it;
