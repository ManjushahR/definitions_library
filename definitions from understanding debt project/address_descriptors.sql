/**************************************************************************************************
Title: Neighbourhood descriptors
Author: Simon Anastasiadis
Reviewer: Marianna Pekar

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
- [IDI_Clean].[data].[snz_res_pop]
- [IDI_Clean].[data].[address_notification]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_concordance_2019]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_current_higher_geography]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[DepIndex2013]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2g_address_descriptors]

Description:
Summary description of a person's neighbourhood including: region,
deprivation, urban/rural, and whether a person lives in a household
with dependent children.

Intended purpose:
Identifying the region, urban/rural-ness, and other characteristics of where a person lives
at a specific point in time.

Notes:
1) Address information in the IDI is not of sufficient quality to determine who shares an
   address. We would also be cautious about claiming that a person lives at a specific
   address on a specific date. However, we are confident using address information for the
   purpose of "this location has the characteristics of the place this person lives", and
   "this person has the characteristics of the people who live in this location".
2) Despite the limitations of address, it is the best source for determining whether a person
   lives in a household with dependent children. Hence we use it for this purpose. However
   we note that this is a low quality measure.
3) The year of the meshblock codes used for the address notification could not be found in
   data documentation. A quality of range of different years/joins were tried the final
   choice represents the best join available at time of creation.
   Another cause for this join being imperfect is not every meshblock contains residential
   addresses (e.g. some CBD areas may contain hotels but not residential addresses, and
   some meshblocks are uninhabited - such as mountains or ocean areas).
   Re-assessment of which meshblock code to use for joining to address_notifications
   is recommended each refresh.
4) For simplicity this table considers address at a specific date.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]
  Current 'as-at' date = 2018-12-31
   
Issues:

History (reverse order):
2020-07-15 MP QA
2020-03-03 SA v1
**************************************************************************************************/

/* Remove table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2g_address_descriptors]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2g_address_descriptors];
GO

SELECT a.[snz_uid]
      ,a.[ant_notification_date]
      ,a.[ant_replacement_date]
      ,a.[snz_idi_address_register_uid]
	  ,a.[ant_region_code]
	  ,b.[IUR2018_V1_00] -- urban/rural classification
      ,b.[IUR2018_V1_00_NAME]
	  ,CAST(b.[SA22018_V1_00] AS INT) AS [SA22018_V1_00] -- Statistical Area 2 (neighbourhood)
	  ,b.[SA22018_V1_00_NAME]
	  ,c.[DepIndex2013]
      ,c.[DepScore2013]
	  ,IIF(d.[child_indicator] IS NULL OR d.[child_indicator] = 0, 0, 1) AS [child_indicator]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2g_address_descriptors]
FROM [IDI_Clean_20200120].[data].[address_notification] AS a
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_concordance_2019] AS conc
ON conc.[MB2019_code] = a.[ant_meshblock_code]
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[meshblock_current_higher_geography] AS b
ON conc.[MB2018_code] = b.[MB2018_V1_00]
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[DepIndex2013] AS c
ON conc.[MB2013_code] = c.[Meshblock2013]
LEFT JOIN (
	/* Get number of children below age 15 at each address at end of 2018 */
	SELECT [snz_idi_address_register_uid]
		,COUNT(*) AS child_indicator
	FROM (
		SELECT a.[snz_uid]
			  ,[ant_notification_date]
			  ,[ant_replacement_date]
			  ,[snz_idi_address_register_uid]
			  ,b.snz_birth_date_proxy
		FROM [IDI_Clean_20200120].[data].[address_notification] a
		INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] b
		ON a.snz_uid = b.snz_uid
		WHERE '2018-12-31' BETWEEN [ant_notification_date] AND [ant_replacement_date] -- at end of 2018
		AND [snz_idi_address_register_uid] IS NOT NULL -- must have address code
		AND (b.snz_deceased_year_nbr IS NULL OR b.snz_deceased_year_nbr > 2018) -- must be alive
		AND DATEDIFF(MONTH, b.[snz_birth_date_proxy], '2018-12-31') <= 12*15 -- dependant child, age less than 15 years
		AND EXISTS (
			SELECT 1
			FROM [IDI_Clean_20200120].[data].[snz_res_pop] c -- must be in residential population
			WHERE a.snz_uid = c.snz_uid
		)
	) k
	GROUP BY [snz_idi_address_register_uid] -- count per address
) AS d
ON a.[snz_idi_address_register_uid] = d.[snz_idi_address_register_uid]
WHERE '2018-12-31' BETWEEN [ant_notification_date] AND [ant_replacement_date] -- at end of 2018
AND a.[ant_meshblock_code] IS NOT NULL

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2g_address_descriptors] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2g_address_descriptors] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO





