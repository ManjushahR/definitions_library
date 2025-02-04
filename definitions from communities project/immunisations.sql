/**************************************************************************************************
Title: Immunisations
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[nir_event]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_immunisation]

Description:
Events when people get immunisations.

Intended purpose:
Determining who has been immunised.
Counting the number of immunisations.
 
Notes:
1) There is no data dictionary for two of the three immunisation tables
   so we have used our best judgement.
2) People who Decline an immunisation are excluded.
   People who had the immunisation overseas are recorded as Complete.
3) Most immunisations are given to babies/children, but not all.
   [moh_nir_evt_indication_desc_text] contains these details.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]

Issues:
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_immunisation]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_immunisation];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_immunisation] AS
SELECT [snz_uid]
      ,[moh_nir_evt_event_id_nbr]
      ,[moh_nir_evt_vaccine_date]
	  ,CAST([moh_nir_evt_vaccine_date] AS DATE) AS [event_vaccine_date]
      ,[moh_nir_evt_indication_text]
      ,[moh_nir_evt_indication_desc_text]
      ,[moh_nir_evt_status_desc_text]
FROM [IDI_Clean_20200120].[moh_clean].[nir_event]
WHERE [moh_nir_evt_status_desc_text] = 'Completed'
GO