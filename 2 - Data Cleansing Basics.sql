USE [RaleighCrime]
GO
/*
ISNULL & COALESCE

These two functions deal with NULL values in data sets.
ISNULL accepts two parameters, whereas COALESCE accepts more.
COALESCE is the ANSI standard and is usually preferable.
*/

DECLARE
	@val1 INT = NULL,
	@val2 INT = NULL,
	@val3 INT = NULL,
	@val4 INT = 3;

SELECT
	ISNULL(@val1, @val4) AS ISNULL_3,
	ISNULL(@val1, @val2) AS ISNULL_NULL,
	COALESCE(@val1, @val4) AS COALESCE_3,
	COALESCE(@val1, @val2) AS COALESCE_NULL,
	COALESCE(@val1, @val2, @val3, @val4) As COALESCE_MULTI_3;
GO
--Keep data types in mind when using ISNULL and COALESCE.
--ISNULL takes the data type of the first parameter.
DECLARE
	@valInt1 INT = 3,
	@valInt2 INT = NULL,
	@valChar3 CHAR(4) = 'TEST';

SELECT
	ISNULL(@valInt1, @valChar3) AS ISNULL_UseVal1;
SELECT
	ISNULL(@valInt1, @valInt2) AS ISNULL_UseVal1;
SELECT
	ISNULL(@valInt2, @valInt1) AS ISNULL_UseVal1;
--ISNULL looks at the data type of the first parameter
--and uses that for the return set.  We can implicitly
--convert int(NULL) to CHAR so the first succeeds, but we
--cannot convert 'TEST' to an int and thus the second fails.
SELECT
	ISNULL(@valChar3, @valInt2) AS ISNULL_UseVal3;
SELECT
	ISNULL(@valInt2, @valChar3) AS ISNULL_Error;
GO

--Try the same tests on COALESCE and we can see
--slightly different behavior.
DECLARE
	@valInt1 INT = 3,
	@valInt2 INT = NULL,
	@valChar3 CHAR(4) = 'TEST';

SELECT
	COALESCE(@valInt1, @valChar3) AS COALESCE_UseVal1;
SELECT
	COALESCE(@valInt1, @valInt2) AS COALESCE_UseVal1;
SELECT
	COALESCE(@valInt2, @valInt1) AS COALESCE_UseVal1;
--COALESCE uses data type preference and INT takes precedence
--over CHAR.  Therefore, both of these will fail because
--we cannot convert 'TEST' to an INT data type.
SELECT
	COALESCE(@valChar3, @valInt2) AS COALESCE_Error;
SELECT
	COALESCE(@valInt2, @valChar3) AS COALESCE_Error;

--COALESCE needs a data type.
SELECT
	COALESCE(NULL, NULL);

/*
ISNUMERIC and ISDATE are functions which appear helpful
but can have odd results.
*/

--ISNUMERIC
DECLARE @IsNumericTests TABLE
(
	NumberString CHAR(10)
);
INSERT INTO @IsNumericTests
(
	NumberString
)
VALUES
('12345'),
('Not A Num'),
('NaN'),
('15.448'),
('$123.45'),
('#1'),
('1#'),
('15$'),
('1 '),
('1a'),
('1 A'),
('123,456.78'),
('123.456,78'),
('0D123'), --Scientific notation
('3E4'), --Scientific notation
('0x0a5'), --Hex
('');

SELECT
	NumberString,
	ISNUMERIC(NumberString)
FROM @IsNumericTests;
GO

--ISDATE
--Based on a post by Ginger Grant but updated to use 2012 syntax.
--http://www.desertislesql.com/wordpress1/?p=361
DECLARE @ValidDateTest AS TABLE
(
	DateString VARCHAR(15),
	IsExpectedDate BIT
);

INSERT INTO @validDateTest
(
	DateString,
	IsExpectedDate
)
VALUES
('Not a date', 0),
('4-1-2-14', 0),
('5-2-7', 0),
('2014.2.3', 1),
('08/02/10', 0),
('7/3/2015', 1),
('2014-3-14', 1),
('12-3-1', 0),
('14-3-4', 0),
('20140301', 1),
('201123', 1),
('2011204', 0),
('7/023/2015', 0),
('6/02/014', 0),
('003/02/014', 0),
('3/010/2014', 0),
('4/02/012', 0);

SELECT
	vdt.DateString,
	vdt.IsExpectedDate,
	TRY_CONVERT(DATETIME, vdt.DateString) AS ConvertedDate
FROM @ValidDateTest vdt;
GO

/*
CAST and CONVERT are the historical way of converting data types.
SQL Server 2012 introduced TRY_PARSE and TRY_CONVERT/TRY_CAST.
*/

DECLARE @Strings TABLE
(
	String VARCHAR(15)
);
INSERT INTO @Strings
(
	String
)
VALUES
('12345'),
('Not A Num'),
('NaN'),
('15.448'),
('$123.45'),
('#1'),
('1#'),
('15$'),
('1 '),
('1a'),
('1 A'),
('123,456.78'),
('123.456,78'),
('0D123'), --Scientific notation
('3E4'), --Scientific notation
('0x0a5'), --Hex
('');

SELECT
	s.String,
	TRY_CAST(s.String AS INT) AS TryCastInt,
	TRY_CAST(s.String AS DECIMAL(15,6)) AS TryCastDecimal,
	TRY_CONVERT(INT, s.String) AS TryConvertInt,
	TRY_CONVERT(DECIMAL(15,6), s.String) AS TryConvertDecimal,
	TRY_PARSE(s.String AS INT) AS TryParseInt,
	TRY_PARSE(s.String AS DECIMAL(15,6)) AS TryParseDecimal,
	TRY_PARSE(s.String AS DECIMAL(15,6) USING 'de-DE') AS TryParseDecimalDE
FROM @Strings s;

--TRY_PARSE uses the .NET runtime, so it might be slower, but
--it does give you culture information.
--Focus on dates and numbers for TRY_PARSE.
DECLARE
	@WeirdDate VARCHAR(10) = '07-2016-17';
SELECT
	TRY_CAST(@WeirdDate AS DATETIME2) AS TryCast,
	TRY_CONVERT(DATETIME2, @WeirdDate) AS TryConvert,
	TRY_PARSE(@WeirdDate AS DATETIME2) AS TryParse;
GO
