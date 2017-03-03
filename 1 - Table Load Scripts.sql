USE [RaleighCrime]
GO
/*
Goals:
	1)  Normalize the tables.  This means breaking out Incident Code (LCR)
		and Incident Description (LCR DESC) into their own table because LCR --> LCR DESC
	2)  Create primary and unique keys to guarantee uniqueness on tables
		and prevent duplicate rows from interfering with analysis.
	3)  Fix names and data types to make analysis easier.
	4)  Create foreign key constraints to give people an idea of how to link data together.
	5)  Create check constraints to ensure that invalid data cannot sneak in.
*/
CREATE TABLE dbo.IncidentCode
(
	IncidentCode VARCHAR(5) NOT NULL,
	IncidentDescription VARCHAR(55) NOT NULL
);
ALTER TABLE dbo.IncidentCode ADD CONSTRAINT [PK_IncidentCode]
	PRIMARY KEY CLUSTERED(IncidentCode);
GO
INSERT INTO dbo.IncidentCode
(
	IncidentCode,
	IncidentDescription
)
SELECT DISTINCT
	LCR,
	[LCR DESC]
FROM dbo.Police;
GO

CREATE TABLE dbo.Incident
(
	IncidentID INT IDENTITY(1,1) NOT NULL,
	IncidentCode VARCHAR(5) NOT NULL,
	IncidentDate DATETIME,
	BeatID INT NOT NULL,
	IncidentNumber VARCHAR(19) NOT NULL,
	IncidentLocation GEOGRAPHY NULL
);
ALTER TABLE dbo.Incident ADD CONSTRAINT [PK_Incident]
	PRIMARY KEY CLUSTERED(IncidentID);
ALTER TABLE dbo.Incident ADD CONSTRAINT [FK_Incident_IncidentCode]
	FOREIGN KEY(IncidentCode)
	REFERENCES dbo.IncidentCode(IncidentCode);
ALTER TABLE dbo.Incident ADD CONSTRAINT [UKC_Incident]
	UNIQUE(IncidentNumber);
ALTER TABLE dbo.Incident ADD CONSTRAINT [CK_Incident_BeatID]
	CHECK(BeatID >= 0);
ALTER TABLE dbo.Incident ADD CONSTRAINT [CK_Incident_IncidentDate]
	CHECK(IncidentDate >= '2005-01-01' AND IncidentDate < '2015-01-01');

INSERT INTO dbo.Incident
(
	IncidentCode,
	IncidentDate,
	BeatID,
	IncidentNumber,
	IncidentLocation
)
SELECT
	p.LCR,
	TRY_PARSE(p.[INC DATETIME] AS DATETIME USING 'en-us') AS IncidentDate,
	p.BEAT,
	p.[INC NO],
	CASE
		WHEN NULLIF(p.[LOCATION], '') IS NULL THEN NULL
		ELSE GEOGRAPHY::STPointFromText('POINT' + REPLACE(p.[LOCATION], ',', ''), 4326)
	END AS IncidentLocation
FROM dbo.Police p;
GO
