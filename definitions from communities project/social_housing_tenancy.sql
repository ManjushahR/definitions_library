/**************************************************************************************************
Title: Spell living in social housing
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[hnz_clean].[tenancy_household_snapshot]
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy]

Description:
A spell for a person living in social housing provided by central government.

Intended purpose:
Creating indicators of when/whether a person has lived in social housing.
Identifying spells when a person is living in social housing.
Counting the number of days a person spends in social housing.
 
Notes:
1) The snapshot table identifies who was in a house at given points of time. Where the 
   same person appears in consecutive snapshots we infer they are in the house duing the
   intervening time.
2) Condensing is used to avoid double counting where different tenancies overlap.
   If condensing is slow, pre-filtering the input tables may improve speed.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
  Earliest start date = '2016-01-01'
  Latest end date = '2020-12-31'
 
Issues:
 
History (reverse order):
2020-03-03 SA v1
**************************************************************************************************/

/* Condensed spells */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging];
GO

/* Create staging table */
SELECT a.[snz_uid]
      ,a.[hnz_ths_snapshot_date] AS [start_date]
	  ,b.[hnz_ths_snapshot_date] AS [end_date]
      ,a.[hnz_ths_app_relship_text]
      ,a.[hnz_ths_signatory_flg_ind]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging]
FROM [IDI_Clean_20200120].[hnz_clean].[tenancy_household_snapshot] a
INNER JOIN [IDI_Clean_20200120].[hnz_clean].[tenancy_household_snapshot] b
ON a.snz_uid = b.snz_uid
WHERE DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) BETWEEN 20 AND 40 -- adjacent months
AND (a.[snz_household_uid] = b.[snz_household_uid]
OR a.[snz_legacy_household_uid] = b.[snz_legacy_household_uid])
AND a.[hnz_ths_snapshot_date] BETWEEN '2016-01-01' AND '2020-12-31'
AND b.[hnz_ths_snapshot_date] BETWEEN '2016-01-01' AND '2020-12-31';
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging] (snz_uid);
GO

/* Condensed spells */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy];
GO

/* create table with condensed spells */
WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging] s1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid, s.[start_date], MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Clear staging table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_hnz_tenancy_staging];
GO
