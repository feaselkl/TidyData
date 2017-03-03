IF NOT EXISTS
(
	SELECT 1
	FROM sys.databases
	WHERE
		name = N'RaleighCrime'
)
BEGIN
	CREATE DATABASE RaleighCrime;
END
GO
/*
Next:  run the Police import package.  It is called RaleighCrimeLoad.dtsx.
Double-click the package to get a prompt.  Go to the Connection Managers tab
	and make sure that the SourceConnectionFlatFile points to your Police.csv
	file.  You may need to unzip Police.zip to get to Police.csv.
Then hit Execute and the package should load.
NOTE:  if you already have a table called Police, you should drop it before running the package.
NOTE:  in the event the package does not load, you can import data via SSMS using the
Import Data wizard.  The settings you want to change are:
	- The text qualifier should be "
	- LCR DESC should have a length of 500
*/