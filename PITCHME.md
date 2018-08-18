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

---?image=presentation/assets/background/2_0_cleaning.jpg&size=cover&opacity=40

## Dirty Data

What is dirty data?

* Inconsistent data
* Invalid data
* Incomplete data
* Inaccurate data
* Duplicate data

+++?image=presentation/assets/background/2_1_philosophy.jpg&size=cover&opacity=40

### Philosophy

The ideal solution is to clean data at the nearest possible point.  In rank order:
1. Before it gets into the OLTP system
2. Once it is in the OLTP system
3. ETL process to the warehouse
4. Once it is in the warehouse
5. During data analysis

Not all systems follow OLTP => DW => Analysis, so it is valuable to know multiple techniques for data cleansing.

+++?image=presentation/assets/background/2_2_motivation.jpg&size=cover&opacity=40

### Motivation

Today's talk will focus on data cleansing within SQL Server and R, with an emphasis on R.  In SQL Server, we will focus on data structures.  In R, we will focus on the concept of tidy data.

This will necessarily be an incomplete survey of data cleansing techniques, but should serve as a starting point for further exploration.

We will not look at Data Quality Services or other data provenance tools in this talk, but these tools are important.
