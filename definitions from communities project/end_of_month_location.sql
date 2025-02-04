/**************************************************************************************************
Title: Location information for end of month
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[data].[address_notification]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_concordance_2019]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_current_higher_geography]
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_end_of_month_location]

Description:
Summary description of a person's neighbourhood including: region,
TA, urban/rural configured for end-of-month analysis.

Intended purpose:
Identifying the region, urban/rural-ness, and other characteristics of where a person lives
at a specific point in time.

Notes:
1) Address information in the IDI is not of sufficient quality to determine who shares an
   address. We would also be cautious about claiming that a person lives at a specific
   address on a specific date. However, we are confident using address information for the
   purpose of "this location has the characteristics of the place this person lives", and
   "this person has the characteristics of the people who live in this location".
2) This table is suitable for analysing people's addresses at the end of a month using
   the data assembly tool. The data assembly tool should aim to capture the whole month.
   Because we have backdated all the closing addresses by one-month-less-one-day, where
   a person changes address within a month only their new address is visable within that
   month. Therefore assembling this dataset based on months will capture only the latest
   record per month.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
   
Issues:

History (reverse order):
2020-03-03 SA v1
**************************************************************************************************/

/* Remove table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_end_of_month_location]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_end_of_month_location];
GO

SELECT *
	,DATEADD(MONTH, -1, IIF(YEAR(end_date) = 9999, end_date, DATEADD(DAY, 1, end_date))) AS modified_end_date
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_end_of_month_location]
FROM (
	SELECT a.[snz_uid]
		  ,a.[ant_notification_date]
		  ,a.[ant_replacement_date] AS end_date
		  ,a.[snz_idi_address_register_uid]
		  ,a.[ant_region_code]
		  ,a.[ant_ta_code]
		  ,b.[IUR2018_V1_00] -- urban/rural classification
		  ,b.[IUR2018_V1_00_NAME]
	FROM [IDI_Clean_20200120].[data].[address_notification] AS a
	INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_concordance_2019] AS conc
	ON conc.[MB2019_code] = a.[ant_meshblock_code]
	LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_current_higher_geography] AS b
	ON conc.[MB2018_code] = b.[MB2018_V1_00]
	WHERE a.[ant_meshblock_code] IS NOT NULL
) k
WHERE [ant_notification_date] <= DATEADD(MONTH, -1, IIF(YEAR(end_date) = 9999, end_date, DATEADD(DAY, 1, end_date)))

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_end_of_month_location] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_end_of_month_location] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO




