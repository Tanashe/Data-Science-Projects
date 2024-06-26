DATA CLEANING
/**** Script to remove subsector industry codes, keeping only major sector codes ****/

SELECT [NAICS_Codes]
      ,[NAICS_Industry_Description]
  FROM [SBA].[dbo].[sba_industry_standards]
  WHERE NAICS_Codes = ''


/****** Script to delete the NAICs code column ******/

SELECT 
      [NAICS_Industry_Description] AS Industry_Sector
  FROM [SBA].[dbo].[sba_industry_standards]
  WHERE NAICS_Codes = ''


  /** Script to extract industry codes using SQL substring function and add them to a new column **/

SELECT 
      [NAICS_Industry_Description] AS Industry_Sector,
	  CASE WHEN NAICS_Industry_Description LIKE '%–%' THEN SUBSTRING(NAICS_Industry_Description, 8, 2) END AS Sector_codes
  FROM [SBA].[dbo].[sba_industry_standards]
  WHERE NAICS_Codes = ''


  /****** Subquery to drop all NUL values ******/

SELECT *
FROM (
	SELECT 
		  [NAICS_Industry_Description] AS Industry_Sector,
		  CASE WHEN NAICS_Industry_Description LIKE '%–%' THEN SUBSTRING(NAICS_Industry_Description, 8, 2) END AS Sector_codes
	  FROM [SBA].[dbo].[sba_industry_standards]
	  WHERE NAICS_Codes = ''
) MAIN
 WHERE Sector_Codes != ''


 /****** Script to extract the Industry Sector Name******/

SELECT *
FROM (
	SELECT 
		  [NAICS_Industry_Description] AS Industry_Sector,
		  CASE WHEN NAICS_Industry_Description LIKE '%–%' THEN SUBSTRING(NAICS_Industry_Description, 8, 2) END AS Sector_codes,
		  CASE WHEN NAICS_Industry_Description LIKE '%–%' THEN ltrim(SUBSTRING(NAICS_Industry_Description, CHARINDEX('–', NAICS_Industry_Description) + 1, LEN(NAICS_Industry_Description))) END AS Industry_SectorName
	  FROM [SBA].[dbo].[sba_industry_standards]
	  WHERE NAICS_Codes = ''
) MAIN
WHERE Sector_Codes != ''


/**** Script to save INTO a new table ****/

SELECT *
INTO SBA_Sector_Codes_Descriptions2
FROM (
	SELECT 
		  [NAICS_Industry_Description] AS Industry_Sector,
		  CASE WHEN NAICS_Industry_Description LIKE '%–%' THEN SUBSTRING(NAICS_Industry_Description, 8, 2) END AS Sector_codes,
		  CASE WHEN NAICS_Industry_Description LIKE '%–%' THEN ltrim(SUBSTRING(NAICS_Industry_Description, CHARINDEX('–', NAICS_Industry_Description) + 1, LEN(NAICS_Industry_Description))) END AS Industry_SectorName
	  FROM [SBA].[dbo].[sba_industry_standards]
	  WHERE NAICS_Codes = ''



/****** Script to edit and update the table using Insert INTO ******/
Select 
	Industry_Sector,
	Sector_codes,
	Industry_SectorName
 from SBA_Sector_Codes_Descriptions
 insert  into SBA_Sector_Codes_Descriptions
 values
 ('Sector 31 - 33 - Manufacturing', 32, 'Manufacturing'),
 ('Sector 31 - 33 - Manufacturing', 33, 'Manufacturing'),
 ('Sector 44 - 45 - Retail Trade', 44, 'Retail Trade'),
 ('Sector 48 - 49 - Transportation and Warehousing, 48, 'Transportation and Warehousing'),
 ('Sector 48 - 49 - Transportation and Warehousing, 49, 'Transportation and Warehousing')

Select 
	Industry_Sector,
	Sector_codes,
update SBA_Sector_Codes_Descriptions2
 set Industry_SectorName = 'Manufacturing'
 where Sector_codes = 31



DATA EXPLORATION & ANALYSIS

 /****** What are the KPI values for the approved PPP loans? ******/
SELECT 
	COUNT(LoanNumber) AS Total_Approved_Loans,
	SUM(InitialApprovalAmount) AS Total_Approved_amount,
	AVG(InitialApprovalAmount) AS Average_Loan_Size,
	SUM(PAYROLL_PROCEED) AS Reported_As_Payroll_Proceeds
  FROM [SBA].[dbo].[SBA_Public_Data]



/****** What percentage of PPP loans were forgiven? ******/

SELECT 
	COUNT(LoanNumber) AS Total_Approved_Loans,
	SUM(InitialApprovalAmount) AS Total_Approved_amount,
	SUM(ForgivenessAmount) AS Amount_Forgiven,
	ROUND(SUM(ForgivenessAmount)/SUM(InitialApprovalAmount) * 100, 2)As Percentage_Forgiven
  FROM 
	[SBA].[dbo].[SBA_Public_Data]



/****** KPI’s Grouped by Year  ******/

SELECT 
	YEAR(DateApproved),
	COUNT(LoanNumber) AS Total_Approved_Loans,
	SUM(InitialApprovalAmount) AS Total_Approved_amount,
	AVG(InitialApprovalAmount) AS Average_Loan_Size,
	SUM(PAYROLL_PROCEED) AS Reported_As_Payroll_Proceeds
  FROM 
	[SBA].[dbo].[SBA_Public_Data]
WHERE 
	YEAR(DateApproved) = 2020
GROUP BY
	YEAR(DateApproved)
UNION
SELECT 
	YEAR(DateApproved),
	COUNT(LoanNumber) AS Total_Approved_Loans,
	SUM(InitialApprovalAmount) AS Total_Approved_amount,
	AVG(InitialApprovalAmount) AS Average_Loan_Size,
	SUM(PAYROLL_PROCEED) AS Reported_As_Payroll_Proceeds
  FROM 
	[SBA].[dbo].[SBA_Public_Data]
WHERE 
	YEAR(DateApproved) = 2021
GROUP BY
	YEAR(DateApproved)



/** Which are the top 15 lending institutions that provided the majority of PPP loans? **/

SELECT TOP 15
	OriginatingLender,
	COUNT(LoanNumber) AS Total_Approved_Loans,
	SUM(InitialApprovalAmount) AS Total_Approved_amount,
	AVG(InitialApprovalAmount) AS Average_Loan_Size,
	SUM(PAYROLL_PROCEED) AS Reported_As_Payroll_Proceeds
  FROM 
	[SBA].[dbo].[SBA_Public_Data]
GROUP BY
	OriginatingLender
ORDER BY 3 DESC



/****** Which are the top 15 Sectors that received the majority of PPP loans? ******/
 
SELECT TOP 15
	sc.Industry_SectorName,
	COUNT(LoanNumber) AS Total_Approved_Loans,
	SUM(InitialApprovalAmount) AS Total_Approved_amount,
	AVG(InitialApprovalAmount) AS Average_Loan_Size,
	SUM(PAYROLL_PROCEED) AS Reported_As_Payroll_Proceeds
  FROM 
	[SBA].[dbo].[SBA_Public_Data] pd
	join SBA_Sector_Codes_Descriptions2 sc
	ON left(pd.NAICSCode, 2) = sc.Sector_codes
GROUP BY
	sc.Industry_SectorName
ORDER BY 3 DESC




/**What is the % of approved loans by the top 15 Industry Sectors, using CTE’s **/

; with CTE AS
(
	SELECT TOP 15
		sc.Industry_SectorName,
		COUNT(LoanNumber) AS Total_Approved_Loans,
		SUM(InitialApprovalAmount) AS Total_Approved_amount,
		AVG(InitialApprovalAmount) AS Average_Loan_Size,
		SUM(PAYROLL_PROCEED) AS Reported_As_Payroll_Proceeds
	  FROM 
		[SBA].[dbo].[SBA_Public_Data] pd
		join SBA_Sector_Codes_Descriptions2 sc
		ON left(pd.NAICSCode, 2) = sc.Sector_codes
	GROUP BY
		sc.Industry_SectorName
	--ORDER BY 3 DESC
)
SELECT Industry_SectorName, Total_Approved_Loans, Total_Approved_amount, 
ROUND(Total_Approved_amount/SUM(Total_Approved_amount) OVER() * 100, 2) AS Percentage_Of_Total_Approved_Amount
from CTE
ORDER BY Total_Approved_amount desc
