/**************************************************************************************************
Title: Chronic condition: Coronary Heart Disease (CHD)
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_event]
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_coronary_heart_disease]

Description:
Diagnosis at a hospital with Coronary Heart Disease (CHD).

Intended purpose:
Determine who has been diagnosed with the chronic condition 'coronary heart disease'
And when they were diagnosed.
 
Notes:
1) In the September 2018 refresh, Coronary Heart Disease was removed from the MoH_chronic table.
   The refresh update notes:
   "The data contained in the [moh.clean].[chronic_condition] table has changed due to some data
    sources being too outdated to provide value for researchers. COPD and CHD are no longer included
	in this table, and alternatives should be used to identify these conditions. The remaining
	conditions have been updated. Diabetes now uses data from the updated Virtual Diabetes 
	Register (VDR) methodology (v686) and contains data from the VDR 2017."
   IDI wiki Source:
   wprdtfs05/sites/DefaultProjectCollection/IDI/IDIwiki/UserWiki/Documents/September%202018%20IDI%20Refresh%20Updates.pdf
2) We have constructed this definition from the description given in the MoH IDI Data dictionary.
   This includes a list of diagnosis and proceedure codes, as well as a list of pharmaceuticals.
   According to the recommendations in the data dictionary, we omit the pharmaceuticals definition
   and focus on only hospital events.
3) Testing against Chronic condition table in the 2018-07-20 refresh suggests almost perfect consistency.
4) To reduce the amount of data written/copied during the construction of these tables, we have
   commented out non-critical fields (lines starting with "--"). Uncommenting these lines is
   recommended is validating the construction/definition.
5) The [end_date] in this table is the end of the hospital visit when diagnosis took place,
   NOT the date that the chronic condition ended.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
 
Issues:
 
History (reverse order):
2020-05-26 SA v1
**************************************************************************************************/

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags];
GO

/************************************ publically funded hospital discharages ************************************/
SELECT [moh_dia_event_id_nbr] AS [event_id]
      --,[moh_dia_clinical_sys_code]
      --,[moh_dia_submitted_system_code]
      --,[moh_dia_diagnosis_type_code]
      --,[moh_dia_clinical_code]
	  ,'pub_CHD' AS [source]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags]
FROM [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_diag]
WHERE [moh_dia_submitted_system_code] = [moh_dia_clinical_sys_code] /* higher accuracy when systems match */
AND (
/* diagnosis in ICD9 */
[moh_dia_diagnosis_type_code] IN ('A', 'B') /* diagnosies */
AND [moh_dia_clinical_sys_code] = '06' /* ICD9-CMA */
AND (   SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('410', '411', '412', '413', '414')
	 OR SUBSTRING([moh_dia_clinical_code], 1, 5) IN ('V4581', 'V4582')   )
) OR (
/* diagnosis in ICD10 */
[moh_dia_diagnosis_type_code] IN ('A', 'B') /* diagnosies */
AND [moh_dia_clinical_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM */
AND (   SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('I20', 'I21', 'I22', 'I23', 'I24', 'I25')
	 OR SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('Z951', 'Z955')   )
) OR (
/* procedure/operation in ICD9 */
[moh_dia_diagnosis_type_code] = 'O' /* operations */
AND [moh_dia_clinical_sys_code] = '06' /* ICD9-CMA */
AND SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('3601', '3602', '3603', '3604', '3605', '3606', '3607',
                                                 '3610', '3611', '3612', '3613', '3614', '3615', '3616')
) OR (
/* procedure/operation in ICD10 */
[moh_dia_diagnosis_type_code] = 'O' /* operations */
AND [moh_dia_clinical_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM */
AND [moh_dia_clinical_code] IN (
	'3530400', '3530500', '3531000', '3531001', '3531002', '3849700', '3849701', '3849702', '3849703',
	'3849704', '3849705', '3849706', '3849707', '3850000', '3850001', '3850002', '3850003', '3850004',
	'3850300', '3850301', '3850302', '3850303', '3850304', '3863700', '9020100', '9020101', '9020102', '9020103'
)
)

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags] ([event_id]);
GO

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags];
GO

/************************************ privately funded hospital discharages ************************************/
SELECT [moh_pri_diag_event_id_nbr] AS [event_id]
      --,[moh_pri_diag_clinic_sys_code]
      --,[moh_pri_diag_sub_sys_code]
      --,[moh_pri_diag_diag_type_code]
      --,[moh_pri_diag_clinic_code]
	  ,'priv_CHD' AS [source]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags]
FROM [IDI_Clean_20200120].[moh_clean].[priv_fund_hosp_discharges_diag]
WHERE [moh_pri_diag_sub_sys_code] = [moh_pri_diag_clinic_sys_code] /* higher accuracy when systems match */
AND (
/* diagnosis in ICD9 */
[moh_pri_diag_diag_type_code] IN ('A', 'B') /* diagnosies */
AND [moh_pri_diag_clinic_sys_code] = '06' /* ICD9-CMA */
AND (   SUBSTRING([moh_pri_diag_clinic_code], 1, 3) IN ('410', '411', '412', '413', '414')
	 OR SUBSTRING([moh_pri_diag_clinic_code], 1, 5) IN ('V4581', 'V4582')   )
) OR (
/* diagnosis in ICD10 */
[moh_pri_diag_diag_type_code] IN ('A', 'B') /* diagnosies */
AND [moh_pri_diag_clinic_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM */
AND (   SUBSTRING([moh_pri_diag_clinic_code], 1, 3) IN ('I20', 'I21', 'I22', 'I23', 'I24', 'I25')
	 OR SUBSTRING([moh_pri_diag_clinic_code], 1, 4) IN ('Z951', 'Z955')   )
) OR (
/* procedure/operation in ICD9 */
[moh_pri_diag_diag_type_code] = 'O' /* operations */
AND [moh_pri_diag_clinic_sys_code] = '06' /* ICD9-CMA */
AND SUBSTRING([moh_pri_diag_clinic_code], 1, 4) IN ('3601', '3602', '3603', '3604', '3605', '3606', '3607',
                                                 '3610', '3611', '3612', '3613', '3614', '3615', '3616')
) OR (
/* procedure/operation in ICD10 */
[moh_pri_diag_diag_type_code] = 'O' /* operations */
AND [moh_pri_diag_clinic_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM */
AND [moh_pri_diag_clinic_code] IN (
	'3530400', '3530500', '3531000', '3531001', '3531002', '3849700', '3849701', '3849702', '3849703',
	'3849704', '3849705', '3849706', '3849707', '3850000', '3850001', '3850002', '3850003', '3850004',
	'3850300', '3850301', '3850302', '3850303', '3850304', '3863700', '9020100', '9020101', '9020102', '9020103'
)
)

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags] ([event_id]);
GO

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_coronary_heart_disease]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_coronary_heart_disease];
GO

/************************************ combined final table ************************************/

SELECT *
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_coronary_heart_disease]
FROM (
/* public */
SELECT [snz_uid]
	  ,[event_id]
      ,[source]
	  ,[moh_evt_evst_date] AS [start_date]
	  ,[moh_evt_even_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags] a
INNER JOIN [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_event] b
ON a.[event_id] = b.[moh_evt_event_id_nbr]

UNION ALL

/* private */
SELECT [snz_uid]
	  ,[event_id]
	  ,[source]
	  ,[moh_pri_evt_start_date] AS [start_date]
      ,[moh_pri_evt_end_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags] a
INNER JOIN [IDI_Clean_20200120].[moh_clean].[priv_fund_hosp_discharges_event] b
ON a.[event_id] = b.[moh_pri_evt_event_id_nbr]

) k

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_coronary_heart_disease] ([snz_uid]);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_coronary_heart_disease] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/************************************ tidy tempoary tables away ************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags];
GO
