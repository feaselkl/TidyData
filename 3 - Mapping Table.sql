USE [RaleighCrime]
GO
ALTER TABLE dbo.IncidentCode ADD IncidentTypeID INT NULL;
GO
CREATE TABLE dbo.IncidentType
(
	IncidentTypeID INT IDENTITY(1,1) NOT NULL,
	IncidentType VARCHAR(55) NOT NULL
);
ALTER TABLE dbo.IncidentType ADD CONSTRAINT [PK_IncidentType] PRIMARY KEY CLUSTERED(IncidentTypeID);
ALTER TABLE dbo.IncidentType ADD CONSTRAINT [UKC_IncidentType] UNIQUE(IncidentType);
ALTER TABLE dbo.IncidentCode ADD CONSTRAINT [FK_IncidentCode_IncidentType]
	FOREIGN KEY(IncidentTypeID)
	REFERENCES dbo.IncidentType(IncidentTypeID);
GO
/*
Create a mapping for incident types.
	Rules:
		- Get data before the first /
		- Get data before the first -
		- Get data before the first (
		- Trim spaces
		- Get distinct values
	Additional data cleansing rule:
		- [something] W/[something] should just be [something]
			- EX:  ROBBERY W/something should just be ROBBERY
			- Might want to look up other examples & build REPLACE logic
		- MURDER [etc.] should just be MURDER
		- EMBEZZLEMENT [etc.] should just be EMBEZZLEMENT
		- ASSAULT WITH [something] should just be ASSAULT
		- LARCENY FROM MOTOR VEH (NO LONGER USED) should just be LARCENY
		- RAPE BY FORCE should just be RAPE
	Hints:
		- Look up CHARINDEX and PATINDEX
		- Look up LTRIM and RTRIM
		- Think about doing this in multiple steps

NOTE:  this is not a true mapping table, as we are modifying the IncidentCode table.
If we weren't allowed to modify IncidentCode, we would create IncidentType and a
junction table between IncidentCode and IncidentType (e.g., IncidentTypeCode) and
populate that with the incident code and its relevant type.  Sometimes you need to do this
because you don't own the source system or can't modify the schema, but it's an inferior
option if you can directly modify the IncidentCode table.
*/

--Step 1:  Create a temp table.
CREATE TABLE #IncidentType
(
	IncidentCode VARCHAR(5),
	IncidentDescription VARCHAR(55),
	IncidentType VARCHAR(55),
	IncidentTypeID INT
);

--Step 2:  Run through all of our rules and cleanse the data.
INSERT INTO #IncidentType
(
	IncidentCode,
	IncidentDescription,
	IncidentType
)
SELECT
	ic.IncidentCode,
	ic.IncidentDescription,
	LTRIM(RTRIM(SUBSTRING(ic.IncidentDescription, 1, fdc.FirstDecidingCharacter - 1))) AS IncidentType
FROM dbo.IncidentCode ic
	CROSS APPLY(SELECT REPLACE(ic.IncidentDescription, ' W/', '-W/') AS IncidentDescription) idW
	CROSS APPLY(SELECT REPLACE(idW.IncidentDescription, 'MURDER ', 'MURDER/') AS IncidentDescription) idM
	CROSS APPLY(SELECT REPLACE(idM.IncidentDescription, 'EMBEZZLEMENT ', 'EMBEZZLEMENT/') AS IncidentDescription) idE
	CROSS APPLY(SELECT REPLACE(idE.IncidentDescription, 'ASSAULT ', 'ASSAULT/') AS IncidentDescription) idA
	CROSS APPLY(SELECT REPLACE(idA.IncidentDescription, 'LARCENY ', 'LARCENY/') AS IncidentDescription) idL
	CROSS APPLY(SELECT REPLACE(idL.IncidentDescription, 'RAPE ', 'RAPE/') AS IncidentDescription) idFinal
	CROSS APPLY(SELECT CHARINDEX('/', idFinal.IncidentDescription, 1) AS FirstSlash) fs
	CROSS APPLY(SELECT CHARINDEX('-', idFinal.IncidentDescription, 1) AS FirstHyphen) fh
	CROSS APPLY(SELECT CHARINDEX('(', idFinal.IncidentDescription, 1) AS FirstParens) fp
	CROSS APPLY
	(
		SELECT
			CASE WHEN fs.FirstSlash = 0 THEN 999 ELSE fs.FirstSlash END AS FirstSlash,
			CASE WHEN fh.FirstHyphen = 0 THEN 999 ELSE fh.FirstHyphen END AS FirstHyphen,
			CASE WHEN fp.FirstParens = 0 THEN 999 ELSE fp.FirstParens END AS FirstParens
	) f
	CROSS APPLY
	(
		SELECT
			CASE
				WHEN f.FirstSlash < f.FirstHyphen AND f.FirstSlash < f.FirstParens THEN f.FirstSlash
				WHEN f.FirstParens < f.FirstHyphen AND f.FirstParens < f.FirstSlash THEN f.FirstParens
				ELSE f.FirstHyphen
			END AS FirstDecidingCharacter
	) fdc;

--Step 3:  Build up the set of incident type IDs.
WITH itID AS
(
	SELECT
		i.IncidentType,
		DENSE_RANK() OVER (ORDER BY i.IncidentType) AS IncidentTypeID
	FROM #IncidentType i
)
UPDATE it
SET
	IncidentTypeID = i.IncidentTypeID
FROM #IncidentType it
	INNER JOIN (SELECT DISTINCT IncidentType, IncidentTypeID FROM itID) i
		ON it.IncidentType = i.IncidentType;

--Step 4:  Populate the IncidentType table.
SET IDENTITY_INSERT dbo.IncidentType ON;
INSERT INTO dbo.IncidentType
(
	IncidentTypeID,
	IncidentType
)
SELECT DISTINCT
	it.IncidentTypeID,
	it.IncidentType
FROM #IncidentType it;
SET IDENTITY_INSERT dbo.IncidentType OFF;

--Step 5:  Update the IncidentCode table.
UPDATE ic
SET
	IncidentTypeID = it.IncidentTypeID
FROM dbo.IncidentCode ic
	INNER JOIN #IncidentType it
		ON ic.IncidentCode = it.IncidentCode;
GO
