<style>
.reveal section img { background:none; border:none; box-shadow:none; }
</style>

## Data Cleansing with SQL and R

<a href="http://www.catallaxyservices.com">Kevin Feasel</a> (<a href="https://twitter.com/feaselkl">@feaselkl</a>)
<a href="http://csmore.info/on/cleansing">http://CSmore.info/on/cleansing</a>

---

@title[Who Am I?]

@snap[west splitscreen]
<table>
	<tr>
		<td><a href="https://csmore.info"><img src="https://www.catallaxyservices.com/media/Logo.png" height="133" width="119" /></a></td>
		<td><a href="https://csmore.info">Catallaxy Services</a></td>
	</tr>
	<tr>
		<td><a href="https://curatedsql.com"><img src="https://www.catallaxyservices.com/media/CuratedSQLLogo.png" height="133" width="119" /></a></td>
		<td><a href="https://curatedsql.com">Curated SQL</a></td>
	</tr>
	<tr>
		<td><a href="https://wespeaklinux.com"><img src="https://www.catallaxyservices.com/media/WeSpeakLinux.jpg" height="133" width="119" /></a></td>
		<td><a href="https://wespeaklinux.com">We Speak Linux</a></td>
	</tr>
</table>
@snapend

@snap[east splitscreen]
<div>
	<a href="http://www.twitter.com/feaselkl"><img src="https://www.catallaxyservices.com/media/HeadShot.jpg" height="358" width="315" /></a>
	<br />
	<a href="http://www.twitter.com/feaselkl">@feaselkl</a>
</div>
@snapend

---?image=presentation/assets/background/2_0_cleaning.jpg&size=cover&opacity=20

### Dirty Data

What is dirty data?

* Inconsistent data
* Invalid data
* Incomplete data
* Inaccurate data
* Duplicate data

---?image=presentation/assets/background/2_1_philosophy.jpg&size=cover&opacity=20

### Philosophy

The ideal solution is to clean data at the nearest possible point.  In rank order:
1. Before it gets into the OLTP system
2. Once it is in the OLTP system
3. ETL process to the warehouse
4. Once it is in the warehouse
5. During data analysis

Not all systems follow OLTP => DW => Analysis, so it is valuable to know multiple techniques for data cleansing.

---?image=presentation/assets/background/2_2_motivation.jpg&size=cover&opacity=20

### Motivation

Today's talk will focus on data cleansing within SQL Server and R, with an emphasis on R.  In SQL Server, we will focus on data structures.  In R, we will focus on the concept of tidy data.

This will necessarily be an incomplete survey of data cleansing techniques, but should serve as a starting point for further exploration.

We will not look at Data Quality Services or other data provenance tools in this talk, but these tools are important.

---

@title[High-Level Concepts]

## Agenda
1. **High-Level Concepts**
2. SQL Server - Constraints
3. SQL Server - Mapping Tables
4. R - tidyr
5. R - dplyr
6. R - Data and Outlier Analysis

---

@title[Data Quality Issues]

| Type | Sample Issues |
| ---- | :------------ |
| Consistency | Misspellings? Data stored in multiple places out of sync? |
| Validity | Physically or logically impossible answers? |
| Completeness | Missing values (NULL, NA, etc.)? |
| Accuracy | Absurd-looking answers?  Multiple sources with conflicting results?  Suspicious sources? |
| Duplication | Can I tell if data is duplicated? |

---?image=presentation/assets/background/3_6_rules.jpg&size=cover&opacity=20

### Rules of Thumb

1. Impossible measurements (e.g., count of people over 500 years old) should go. Don't waste the space storing that.
2. "Missing" data (e.g., records with some NULL values) should stay, although might not be viable for all analyses.
3. Fixable bad data (e.g., misspellings, errors where intention is known) should be fixed and stay.
4. Unfixable bad data is a tougher call.  Could set to default, make a "best guess" change(!!), set to {NA, NULL, Unknown}, or drop from the analysis.

---

@title[SQL Server - Constraints]

## Agenda
1. High-Level Concepts
2. **SQL Server - Constraints**
3. SQL Server - Mapping Tables
4. R - tidyr
5. R - dplyr
6. R - Data and Outlier Analysis

---?image=presentation/assets/background/4_1_dataquality.jpg&size=cover&opacity=20

### Relational Data Quality Tools

Relational databases have several concepts to promote data quality:

* Normalization
* Data types
* Primary key constraints
* Unique key constraints
* Foreign key constraints
* Check constraints
* Default constraints

---

### Normalization

When in doubt, go with Boyce-Codd Normal Form.

<p>**First Normal Form** - consistent shape + unique entities + atomic attributes</p>

@div[left-40]
<br />
![Database-Normalization](presentation/assets/background/4_1_normalization.png)
@divend

@div[right-60]
<p>**Boyce-Codd Normal Form** - 1NF + all attributes fully dependent upon a candidate key + every determinant is a key.</p>
@divend

---?image=presentation/assets/background/4_3_datatypes.jpg&size=cover&opacity=20

### Data Types

Think through your data type choices.

* Use the best data type (int/decimal for numeric, date/datetime/datetime2/time for date data, etc.)
* Use the smallest data type which solves the problem (Ex: date instead of datetime, varchar(10) instead of varchar(max))

---?image=presentation/assets/background/4_4_constraints.jpg&size=cover&opacity=20

### Constraints

Use constraints liberally.
* Primary key to describe the primary set of attributes which describes an entity.
* Unique keys to describe alternate sets of attributes which describe an entity.
* Foreign keys to describe how entities relate.
* Check constraints to explain valid domains for attributes and attribute combinations.
* Default constraints when there is a reasonable alternative to NULL.

---?image=presentation/assets/background/4_5_demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[SQL Server - Mapping Tables]

## Agenda
1. High-Level Concepts
2. SQL Server - Constraints
3. **SQL Server - Mapping Tables**
4. R - tidyr
5. R - dplyr
6. R - Data and Outlier Analysis

---?image=presentation/assets/background/6_1_mapping_table.jpg&opacity=20

### Mapping Tables

One technique for creating higher-level categories for items in transactional data is to use a mapping table:  an external relationship made without directly modifying the primary data.
This can be a new (nullable) column on an existing table or a foreign key to a new table with the mapping relationhship.

---?image=presentation/assets/background/4_5_demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[R - tidyr]

## Agenda
1. High-Level Concepts
2. SQL Server - Constraints
3. SQL Server - Mapping Tables
4. **R - tidyr**
5. R - dplyr
6. R - Data and Outlier Analysis

---?image=presentation/assets/background/7_1_tidy.jpg&size=cover&opacity=20

### What is Tidy Data?

Notes from Hadley Wickham's **Structuring Datasets to Facilitate Analysis**

1. Data sets are made of variables & observations (attributes & entities)
2. Variables contain all values that measure the same underlying attribute (e.g., height, temperature, duration) across units
3. Observations contain all values measured on the same unit (a person, a day, a hospital stay) across attributes

---?image=presentation/assets/background/7_2_tidy.jpg&size=cover&opacity=20

### More on Tidy Data

Notes from Hadley Wickham's **Structuring Datasets to Facilitate Analysis**

4. It is easier to describe relationships between variables (age is a function of birthdate and current date)
5. It is easier to make comparisons between groups of attributes (how many people are using this phone number?)
6. Tidy data IS third normal form (or, preferably, Boyce-Codd Normal Form)!

---

### tidyr

@div[left-50]
![tidyr Logo](presentation/assets/image/hex-tidyr.png)
@divend

@div[right-50]
tidyr is a library whose purpose is to use simple functions to make data frames tidy.  It includes functions like gather (unpivot), separate (split apart a variable), and spread (pivot).
@divend

---?image=presentation/assets/background/4_5_demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[R - dplyr]

## Agenda
1. High-Level Concepts
2. SQL Server - Constraints
3. SQL Server - Mapping Tables
4. R - tidyr
5. **R - dplyr**
6. R - Data and Outlier Analysis

---

### dplyr

@div[left-50]
![dplyr Logo](presentation/assets/image/hex-dplyr.png)
@divend

@div[right-50]
tidyr is just one part of the tidyverse.  Other tidyverse packages include dplyr, lubridate, and readr.
We will take a closer look at dplyr with the next example.
@divend

---?image=presentation/assets/background/4_5_demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[R - Data and Outlier Analysis]

## Agenda
1. High-Level Concepts
2. SQL Server - Constraints
3. SQL Server - Mapping Tables
4. R - tidyr
5. R - dplyr
6. **R - Data and Outlier Analysis**

---?image=presentation/assets/background/8_1_outlier.jpg&size=cover&opacity=20

### Data and Outliers

Using tidyr, dplyr, and some basic visualization techniques, we can perform univariate and multivariate analysis to determine whether the data is clean.  We will focus mostly on univariate and visual analysis in the following example.

---?image=presentation/assets/background/4_5_demo.jpg&size=cover&opacity=20

### Demo Time

---

@title[Additional Ideas]

### Wrapping Up

This has been a quick survey of data cleansing techniques.  For next steps, look at:
* SQL Server Data Quality Services
* Integration with external data sources (APIs to look up UPCs, postal addresses, etc.)
* Value distribution analysis (ex: Benford's Law)

---

### Wrapping Up

To learn more, go here:  <a href="http://csmore.info/on/cleansing">http://CSmore.info/on/cleansing</a>
And for help, contact me:  <a href="mailto:feasel@catallaxyservices.com">feasel@catallaxyservices.com</a>