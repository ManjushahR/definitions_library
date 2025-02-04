/***************************************************************************************************************************

# Residential Care indicator

## Purpose of the Residential Care indicator:
This code defines spells where clients are known to be in residential care.  The data sources are ACC, InterRAI and Socrates so only those people whose spell is funded by ACC, and those people who have had an InterRAI or NASC (Socrates) assessments are included.



## Key concepts

Residential Care in NZ is funded in 3 primary ways:

	- ACC.  For people with significant injuries (almost always Serious Injuries by ACC's classification), ACC may provide Residential Support Services (RSS).  This is a 
		homelike environment for clients who have sustained a physical injury (including Traumatic Brain Injury) and who are unable to live independently and require 
		placement in a residential setting (either short term or long term) due to that covered injury.
		RSS in not appropriate for clients who are medical unstable or unwell or clients who require urgent medical assistance or where the client's primary need for 
		care is due to mental health issues, housing, or their care needs are met by another funder. (see acc.co.nz/assests/contracts/rss-operational-guidelines.pdf for more info).

	- MoH (Disability Support Services) - These can be Community, Rest homes or Hospitals based Residential Care.  The vast majority is Community based.  To get Community Residential 
		Support funding clients need to:
			- be an NZ resident
			- under 65 years old
			- have a long-term intellectual, physical or sensory disability
			- meet the MoH definition of being disabled
			- have a Needs Assessment and Service Coordination (NASC) assessment to determine the type and amount of support that is required
			- have a disability that is not covered by ACC
		More information is available at:
			- health.govt.nz/your-health/services-and-support/disability-services/types-disability-support
			- health.govt.nz/your-health/services-and-support/disability-services/types-disability-support/community-residential-support-services

	- MoH (Aged Residential Care) - Aged Residential Care includes the following types of long-term care provided in a rest home or hospital:
		- rest home care
		- continuing care (hospital)
		- dementia care
		- specialised hospital care (psychogeriatric care)

		Short-term respite care and convalescent care may be provided in these facilities.  Long-term residential care does not include independent living in a retirement village. 
		More information is available at health.govt.nz/our-work/life-stages/health-older-people/long-term-residential-care/residential-care-questions-and-answers



## Practical notes

Time period over which the indicator is complete:

The overall indicator is complete after 1 July 2015.  The individual breakdown by source is:

ACC
- The ACC data appears to be complete since approximately March 2000.  There are some payments in Feb 2000 but it does not appear to be complete. 
-  At present the ACC data currently goes up to the end of 2021

Socrates
- The Socrates spells appear to be complete from the start of 2008.  There is also some data from before that and December 2007 may be complete
	but its not clear either way.
- At present the Socrates data currently goes up to 31 March 2022

InterRAI
- The InterRAI data appears to be valid for residential care since 1 July 2015.  There is some data from before that but it may not be complete.
- At present the InterRAI data currently goes up to 30 June 2021

In total around 80% of the spells come from InterRAI (Aged Residential Care), 10% from ACC and 10% from Socrates.  There are only a few percent of people which overlap between the different sources.

For InterRAI assessments there is no explicit end date.  An end date is added if the person dies.  If the person hasn't died then the end date is set to '9999-12-31'.

It is likely that entirely privately funded residential care will not be included in this indicator.



## References and contacts

ACC - acc.co.nz/assests/contracts/rss-operational-guidelines.pdf

MoH - health.govt.nz/your-health/services-and-support/disability-services/types-disability-support
	- health.govt.nz/your-health/services-and-support/disability-services/types-disability-support/community-residential-support-services
	- health.govt.nz/our-work/life-stages/health-older-people/long-term-residential-care/residential-care-questions-and-answers

FMISAccountCode values:
6640		Residential Care: Rest Homes
6650		Residential Care: Loans Adjustment
6645		Residential Care: Community.  This also includes YP-DAC (non-residential)
6675		Residential Care: Hospitals



## Module business rules

ACC:

Due to the way the ACC payment data in the IDI is summarised (quarterly) we use the following rules:
1) Where the payment is small AND short, assume that the episode only covered part of the quarter and shorten the duration 
	(the definition of small and short is that the payment amount is less than $9,100 AND the difference between the start and end date is less than 28 days):
	- subtract 14 days from the start date and add 14 days to the end date. 
	- ensure that the start date is never before the accident date and the end date is never after the date of death
2) Where the payment amount is greater than $9,100 OR the difference between the start and end date is greater than 28 days:
	- make the start date the first day of the quarter 
	- make the end date the last day of the quarter
	- ensure that the start date is never before the accident date and the end date is never after the date of death

The justification for using small AND short is that:
	- if its longer than 28 days then the logic after that will lead it covering the whole quarter anyway
	- if the spend is large its likely that payment is for the whole quarter and it just looks short because its done in one or two payments

Note that $9,100 is an average daily rate of $325 multiplied by 28 days (see Testing_ACC.sql)

More information is provided in the comments in the ACC part of the code


MoH Disability (SOCRATES):

A Residential Care spell is defined by the start and end date from the service history (payment) data.  All FMISAccountCodes that include 'Residential Care'
are included (see above for list).


MoH Aged Residential Care (InterRAI assessments):

Only assessment type = LTCF are included (LTCF = Long Term Care Facility).  See Testing_InterRAI for other alternatives.
The end date is defined by 
	- the date of death if the person has died
	- '9999-12-31' if the person is still alive

If the client seems to have died well before the assessment date then assume that the InterRAI data is correct and the date of death is wrong (likely due 
	to joining issues in the IDI).  Set the end date to 90 days after the assessment date since they may have died but the date is likely wrong.

If the client seems to have died less than 30 days prior to an assessment then assume that both are accurate but that the assessment occurred just before the
	persons death and set the end date to be the same as the assessment date.


Merging spells: Spells that have small gaps between them (30 days) are merged into continuous spells 



## Parameters
N/A



## Dependencies:

Domain specific datasets:
[IDI_Clean_202203].[acc_clean].[payments]
[IDI_Clean_202203].[acc_clean].[claims]
[IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_service_hist]
[IDI_Clean_202203].[moh_clean].[interrai]

General datasets:
[IDI_Clean_202203].[security].[concordance]
[IDI_Clean_202203].[dia_clean].[deaths]


## Outputs

[IDI_Sandpit].[DL-MAA2020-37].defn_residential_care

## Variable Descriptions

---------------------------------------------------------------------------------------------------------------------------
Column                         Description
name                       
------------------------------ --------------------------------------------------------------------------------------------
snz_uid                        The unique STATSNZ person identifier for the student 

start_date					   The start date of the Residential Care spell

end_date					   The end date of the Residential Care spell



Version and change history

-----------------------------------------------------------------------------------------------------------------------
Date                       Version Comments                       
-------------------------- --------------------------------------------------------------------------------------------
24 Jun 2022                Initial version
-----------------------------------------------------------------------------------------------------------------------


## Code

***************************************************************************************************************************/

/* Assign the target database to which all the components need to be created in. */
USE IDI_SANDPIT;
-- USE {targetdb};

/* Delete the database object if it already exists */
DROP TABLE IF EXISTS [DL-MAA2020-37].defn_residential_care;

GO

-- REMEMBER TO REPLACE THE PROJECT NAME WITH PARAMETER

/****************************************************************************************************************************
1. ACC
Use the ACC payments by General Ledger code to identify ACC funded residential care spells.

Note that each row represents the payments for one claim, one quarter and one payment group (IDI Data Dictionary).  It looks like 
the payment group they are referring to is acc_pay_gl_account_text.
So a single row may represent multiple payments and the start and end date look like the first and last payment date in that quarter

This means that we'll need to estimate the proportion of a quarter that a RC spell covers.  We will base it on the idea that
a small payment where the start and end dates are close together covers only part of the quarter, whereas a large payment or one that
has a large difference between the start and end dates covers the whole quarter. 

We use the following rules:
1) Where the payment amount is less than $9,100 AND the difference between the start and end date is less than 28 days:
	- subtract 14 days from the start date and add 14 days to the end date. 
	- ensure that the start date is never before the accident date (done here) and the end date is never after the date of death (done further down)
2) Where the payment amount is greater than $9,100 OR the difference between the start and end date is greater than 28 days:
	- make the start date the first day of the quarter 
	- make the end date the last day of the quarter
	- ensure that the start date is never before the accident date (done here) and the end date is never after the date of death (done further down)

Note that $9,100 is an average daily rate of $325 multiplied by 28 days (see Testing_ACC.sql)


External verification:
This query gives quarterly care costs for the second quarter of 2021 of around $23 million:

select a.acc_pay_service_year, a.acc_pay_service_quarter, sum(a.acc_pay_total_costs_amt) as total_res_care_spend
from
(select *
from [IDI_Clean_202203].[acc_clean].[payments]
WHERE acc_pay_service_year = 2021 and ([acc_pay_gl_account_text] LIKE '%Res Support one%'
	OR [acc_pay_gl_account_text] LIKE '%Res Support two%'
	OR [acc_pay_gl_account_text] LIKE '%Res Support 3%'
	OR [acc_pay_gl_account_text] LIKE '%RESIDENTIAL SUPPORT COSTS%')) as a
group by a.acc_pay_service_year, a.acc_pay_service_quarter

This is in the ballpark of publicly published spending of around ($20 million)
(acc.co.nz/assets/corporate-documents/second-quarterly-report-2021-2022.pdf says that residential care costs of $1.1 million equates to 5.7% of spending) 



Note that the query below can take about 10 minutes.  The others are much faster.
****************************************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_res_care_acc
GO

SELECT c.snz_uid
	,'ACC_RC' AS source
	,p.[snz_acc_claim_uid]
	,p.[acc_pay_gl_account_text]
	,CASE 
		WHEN p.[acc_pay_total_costs_amt] < 9100 AND DATEDIFF(DAY,p.[acc_pay_first_service_date],p.[acc_pay_last_service_date]) < 28 THEN 
			CONVERT(DATE,(SELECT MAX(v) FROM (VALUES (c.[acc_cla_accident_date]),(DATEADD(DAY,-14,p.[acc_pay_first_service_date]))) AS VALUE(v)))
		ELSE CONVERT(DATE,(SELECT MAX(v) FROM (VALUES (c.[acc_cla_accident_date]),(DATEADD(QUARTER, DATEDIFF(QUARTER, 0, p.[acc_pay_first_service_date]), 0))) AS VALUE(v)))
	END AS care_start_date
	,CASE 
		WHEN p.[acc_pay_total_costs_amt] < 9100 AND DATEDIFF(day,p.[acc_pay_first_service_date],p.[acc_pay_last_service_date]) < 28 THEN 
			CONVERT(DATE,(SELECT MAX(v) FROM (VALUES (c.[acc_cla_accident_date]),(DATEADD(DAY,14,p.[acc_pay_last_service_date]))) AS VALUE(v)))
		ELSE CONVERT(DATE,(SELECT MAX(v) FROM (VALUES (c.[acc_cla_accident_date]),(DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, p.[acc_pay_last_service_date]) + 1, 0)))) AS VALUE(v)))
	END AS care_end_date
	,p.[acc_pay_first_service_date]
	,p.[acc_pay_last_service_date]
	,p.[acc_pay_total_costs_amt]
	,c.[acc_cla_accident_date]
INTO [IDI_Sandpit].[DL-MAA2020-37].[tmp_res_care_acc]
FROM [IDI_Clean_202203].[acc_clean].[payments] AS p
INNER JOIN [IDI_Clean_202203].[acc_clean].[claims] AS c
ON p.[snz_acc_claim_uid] = c.[snz_acc_claim_uid]
WHERE [acc_pay_gl_account_text] IN ('RES SUPPORT 3 SERIOUS INJURY', 'RES SUPPORT ONE SERIOUS INJURY', 'RES SUPPORT TWO SERIOUS INJURY', 'RESIDENTIAL SUPPORT COSTS')
GO

/****************************************************************************************************************************
2. MOH SOCRATES
Use the SOCRATES service history data to identify MOH funded disability residential care spells

The spells look to be complete from 2008 onwards and may also be complete in December 2007 but it 
	cannot be guaranteed.

The vast majority of the spells come from 6645: Residential Care: Community.  This also includes YP-DAC (non-residential).


External verification:
This query gives around 6800 distinct people which matches up well with published data:

select distinct snz_uid
from [IDI_Sandpit].[DL-MAA2020-37].tmp_res_care_socrates
where year(care_start_date) = 2016 and [FMISAccountCode_Value] = 6645

The published data says 6791 (health.govt.nz/system/files/documents/publications/demographics-report-for-client-allocated-ministry-of-health-disability-support-services-2018-update14nov2019.pdf page 8)
****************************************************************************************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_res_care_socrates 
GO

SELECT b.snz_uid
	,'MOH_SOCRATES' AS source
	,a.snz_moh_uid
	,a.[startdate_value] AS care_start_date
	,a.[enddate_value] AS care_end_date
	,a.[FMISAccountCode_Value]
INTO [IDI_Sandpit].[DL-MAA2020-37].tmp_res_care_socrates
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_service_hist] AS a
INNER JOIN [IDI_Clean_202203].[security].[concordance] AS b
ON a.snz_moh_uid = b.snz_moh_uid
WHERE [FMISAccountCode_Value] in ('6640','6650','6645','6675')

GO


/****************************************************************************************************************************
3. MOH InterRAI
Use the InterRAI assessment data to identify age residential care spells

- The InterRAI data appears to be valid for residential care since 1 July 2015.  There is some data from before that but it may not be complete.  The data is currently up to date until 1 July 2021.
- The assessments are mostly LTCF (Long Term Care Facility) then HC (Home Care) then CA (Contact Assessment) and a few PC (Palliative Care)

NOTE: There are several spells per person.  These will need to be consolidated.



External Verification:
This query gives around 34,000 people which agrees well with the published data (34,646, cpb-ap-se2.wpmucdn.com/blogs.auckland.ac.nz/dist/5/361/files/2021/01/PB-2022-1-Longterm-aged-care.pdf)

select distinct snz_uid from
[IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death_raw
where [care_start_date] < '2020-03-31' and ([death_date] > '2020-03-31' or [death_date] is null) and source = 'MOH_IRAI'

This query gives around 30,000 distinct people which matches up reasonably well with published data (31,600) given the uncertainty in how the published data was calculated:

select distinct snz_uid from
[IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death_raw
where [care_start_date] < '2017-03-31' and ([death_date] > '2017-03-31' or [death_date] is null) and source = 'MOH_IRAI'

Published data is at "eldernet.co.nz/knowledge-lab/statistics-about-ageing#.~:text=According%20to%20statistics%20from%20interRAI,data%20from%20Stats%20NZ%202019)."
****************************************************************************************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_moh_irai_rc

SELECT [snz_uid]
	,'MOH_IRAI' AS source
	,'Res Care' AS type
    ,[snz_moh_uid] AS source_uid
    ,[moh_irai_care_level_text]
    ,[moh_irai_assessment_type_text]
    ,[moh_irai_assess_version_text]
    ,[moh_irai_assessment_date] AS care_start_date
    ,[moh_irai_consent_text]
    ,[moh_irai_location_text]
    ,[moh_irai_res_status_admit_code]
    ,[moh_irai_res_status_usual_code]
    ,[moh_irai_prior_living_code]
    ,[moh_irai_lives_someone_new_ind]
INTO [IDI_Sandpit].[DL-MAA2020-37].tmp_moh_irai_rc
FROM [IDI_Clean_202203].[moh_clean].[interrai]
WHERE [moh_irai_assessment_type_text] = 'LTCF'

GO

/****************************************************************************************************************************
4. Pull together the 3 sources

For now set the end date to '8999-12-31' for InterRAI assessments since they don't have an explicit end date
This will be changed at the end to '9999-12-31' but that number causes an error in the merging of spells
when it tries to add days to the date.
****************************************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells
GO

SELECT [snz_uid]
	,[source]
	,care_start_date
	,care_end_date
INTO [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells
FROM (
		SELECT [snz_uid]
			,[source]
			,care_start_date
			,care_end_date
		FROM [IDI_Sandpit].[DL-MAA2020-37].tmp_res_care_acc
		UNION ALL
		SELECT [snz_uid]
			,[source]
			,care_start_date
			,care_end_date
		FROM [IDI_Sandpit].[DL-MAA2020-37].tmp_res_care_socrates
		UNION ALL
		SELECT [snz_uid]
			,[source]
			,care_start_date
			,CAST('8999-12-31' AS DATE) AS care_end_date
		FROM [IDI_Sandpit].[DL-MAA2020-37].tmp_moh_irai_rc
) AS a
GO

/****************************************************************************************************************************
5. End Spells where the person has died

This step is critically important for Aged Residential Care Spells because there is no end date to these
spells and almost everyone who goes into Aged Residential Care with only leave when they die.

Note that, with the current logic, the death date doesnt override the end date for ACC_RC and MOH_SOCRATES.  Its included
	at this point so that its easy to change the  logic later if required.

Note that there are some inconsistencies between the residential care data and the death data.  In situations where:
- the difference between the death date and the residential care end data is greater than 30 days, residential care data is assumed to be correct. 
- where the death date is slightly before the recorded InterRAI assessment date its assumed that the assessment
	occurred and the death date is accurate. Then the small uncertainties in the assessment date caused the problem
	and the spell is set to a duration of 0 days.

Note that '8999-12-31' is used instead of '9999-12-31' here so that the spell consolidation doesnt throw up an error
Right at the end we'll replace 8999 with 9999
****************************************************************************************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_death_date
GO

-- Put the death data into the format we need to be able to do calculations and comparisons
SELECT snz_uid 
	,DATEFROMPARTS( dia_dth_death_year_nbr, dia_dth_death_month_nbr, 15) AS death_date
INTO [IDI_Sandpit].[DL-MAA2020-37].tmp_death_date
FROM [IDI_Clean_202203].[dia_clean].[deaths]

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death_raw
GO

-- Join the death data to the spells data
SELECT a.*
	,b.death_date
	,datediff(day, a.care_start_date, b.death_date) as death_diff 
INTO [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death_raw
FROM [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells AS a
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-37].tmp_death_date AS b
ON a.[snz_uid] = b.[snz_uid]

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death
GO

-- Apply some logic to work out reasonable ends dates accounting for people who are still alive and people who have died at times that are inconsistent with the rest of the data
SELECT snz_uid
		,care_start_date AS [start_date]
	,CASE
-- Logic: for InterRAI assessments, when there is no established end_date and the person is still alive then set the end date to be an indeterminant date in the future (~150K spells)
		WHEN source = 'MOH_IRAI' AND care_end_date = '8999-12-31' AND death_date is NULL THEN '8999-12-31'
-- Logic: for InterRAI assessments, when there is no established end_date and the data says that they died well in the past.  This looks like an error with the death date, 
-- so construct a reasonable end date by assuming that the duration of a spell is 90 days (see Testing_InterRAI).  (~500 spells)
		WHEN source = 'MOH_IRAI' AND care_end_date = '8999-12-31' AND death_diff < -30 THEN DATEADD(day, 90, care_start_date) 
-- Logic: for InterRAI assessments, when there is no established end_date and the data says they died recently in the past then assume that there is no real spell 
-- so set the duration to 0 days (~1800 spells)
		WHEN source = 'MOH_IRAI' AND care_end_date = '8999-12-31' AND death_diff >= -30 AND death_diff < 0 THEN care_start_date
-- Logic: for InterRAI assessments, when there is no established end_date and the data says they died after the care_start_date then the spell is care_start_date until they die
-- so set the care_end_date as the death_date (~240K spells)
		WHEN source = 'MOH_IRAI' AND care_end_date = '8999-12-31' AND death_diff > 0 THEN death_date
-- Logic: for ACC spells, we have established start and end dates for all spells so use them, even if the death data isn't consistent.  The assumption is that the ACC payment data
-- is more reliable. (~50K spells)
		WHEN source = 'ACC_RC' THEN care_end_date
-- Logic: for SOCRATES spells, we have established start and end dates for all spells so use them, even if the death data isn't consistent.  The assumption is that the SOCRATES payment data
-- is more reliable. (~170K spells)
		WHEN source = 'MOH_SOCRATES' THEN care_end_date
	END AS end_date
INTO [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death
FROM [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death_raw



/****************************************************************************************************************************
6. Consolidate Spells
Note that we drop the source of the data at this point because we are only interested in the spells.  If you are interested in the source then
work with [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death.

We consolidate any two spells that are less than 30 days apart to allow for minor date errors.
****************************************************************************************************************************/


DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].defn_residential_care;
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2020-37].tmp_residential_care;
GO

-- Consolidate spells that are near each other into a smaller number of spells
WITH
/* start dates that are not within another spell */
input_data AS (
SELECT [snz_uid]
			,[start_date]
			,dateadd(day, 30, [end_date]) AS [end_date] /* Adds a 30 day threshold between each assessment so that any consecutive assessment made within 30 day thresholds can be joined up together into a single spell. */
		FROM [IDI_Sandpit].[DL-MAA2020-37].tmp_RC_spells_w_death
		GROUP BY snz_uid, [start_date], [end_date]
		),

spell_starts AS (
	SELECT [snz_uid]
 	    ,[start_date]
		 ,[end_date]
	FROM input_data s1
	WHERE NOT EXISTS (
		SELECT 1
		FROM input_data s2
		WHERE s1.snz_uid = s2.snz_uid
		AND s2.[start_date] < s1.[start_date]
		AND s1.[start_date] <= s2.[end_date]
	)
),

/* end dates that are not within another spell */
spell_ends AS (
	SELECT [snz_uid]
		,[start_date]
		,[end_date]
	FROM input_data t1
	WHERE NOT EXISTS (
		SELECT 1
		FROM input_data t2
		WHERE t2.snz_uid = t1.snz_uid
		AND t2.[start_date] <= t1.[end_date]
		AND t1.[end_date] < t2.[end_date]
	)
)

SELECT s.snz_uid
	,s.[start_date]
	,dateadd(day, -30, min(e.[end_date])) AS [end_date]
INTO [IDI_Sandpit].[DL-MAA2020-37].tmp_residential_care
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]


SELECT snz_uid
	,[start_date]
	,CASE 
		WHEN a.[end_date] = '8999-12-31' THEN '9999-12-31'
		ELSE a.[end_date]
	END AS [end_date]
INTO [IDI_Sandpit].[DL-MAA2020-37].defn_residential_care
FROM [IDI_Sandpit].[DL-MAA2020-37].tmp_residential_care AS a


/* Clean up any temporary tables or views */
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_res_care_acc];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_RC_spells_w_death];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_res_care_socrates];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_moh_irai_rc];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_death_date];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_RC_spells];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_RC_spells_w_death_raw];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_RC_spells_w_death];
DROP TABLE IF EXISTS [DL-MAA2020-37].[tmp_residential_care];

GO










