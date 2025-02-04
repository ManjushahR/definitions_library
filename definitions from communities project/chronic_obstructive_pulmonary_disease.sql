/**************************************************************************************************
Title: Chronic condition: Chronic Obstructive Pulmonary Disease (COPD)
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code]
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_obstructive_pulmonary_disease]

Description:
Diagnosis at a hospital with Chronic Obstructive Pulmonary Disease (COPD)
or dispensing of drugs to treat COPD.

Intended purpose:
Determine who has been diagnoses with the chronic condition COPD
And when they were diagnosed.
 
Notes:
1) In the September 2018 refresh, Chronic Obstructive Pulmonary Disease was removed from the
   MoH_chronic table. The refresh update notes:
   "The data contained in the [moh.clean].[chronic_condition] table has changed due to some data
    sources being too outdated to provide value for researchers. COPD and CHD are no longer included
	in this table, and alternatives should be used to identify these conditions. The remaining
	conditions have been updated. Diabetes now uses data from the updated Virtual Diabetes 
	Register (VDR) methodology (v686) and contains data from the VDR 2017."
   IDI wiki Source:
   wprdtfs05/sites/DefaultProjectCollection/IDI/IDIwiki/UserWiki/Documents/September%202018%20IDI%20Refresh%20Updates.pdf
2) We have constructed this definition from the description given in the MoH IDI Data dictionary.
   This includes a list of diagnosis and proceedure codes, as well as a list of pharmaceuticals.
   For simplicity we have excluded two pharmaceuticals (Aninophylline and Theophylline) as these
   are conditional on no diagnosis for asthma (and we are yet to establish a definition for asthma).
   The data dictionary also makes reference to Mental Health information (incl. PRIMHD) but as
   we could find no diagnosis information in these sources (where they are available in the IDI)
   these have also been excluded.
3) Testing against Chronic condition table in the 2018-07-20 refresh suggests very high consistency.
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
	  ,'pub_COPD' AS [source]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags]
FROM [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_diag]
WHERE [moh_dia_submitted_system_code] = [moh_dia_clinical_sys_code] /* higher accuracy when systems match */
AND [moh_dia_diagnosis_type_code] IN ('A', 'B') /* diagnosies */
AND (
/* ICD9 codes */
[moh_dia_clinical_sys_code] = '06' /* ICD9-CMA */
AND (
	SUBSTRING([moh_dia_clinical_code], 1, 3) IN (
		 '490' /* Bronchitis, not specified as acute or chronic */
		,'496' /* Chronic airway obstruction, not elsewhere classified */
	) OR
	SUBSTRING([moh_dia_clinical_code], 1, 4) IN (
		 '4910' /* Simple chronic bronchitis */
		,'4911' /* Mucopurulent chronic bronchitis */
		,'4918' /* Other chronic bronchitis */
		,'4919' /* Unspecified chronic bronchitis */
		,'4920' /* Emphysematous bleb */
		,'4928' /* Other emphysema */
	) OR
	SUBSTRING([moh_dia_clinical_code], 1, 5) IN (
		 '49120' /* Obstructive chronic bronchitis without mention of acute exacerbation */
		,'49121' /* Obstructive chronic bronchitis with acute exacerbation */
	)
)
) OR (
/* ICD10 codes */
[moh_dia_clinical_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM */
AND (
	SUBSTRING([moh_dia_clinical_code], 1, 3) IN (
		 'J40' /* Bronchitis, not specified as acute or chronic */
		,'J42' /* Unspecified chronic bronchitis */
	) OR
	SUBSTRING([moh_dia_clinical_code], 1, 4) IN (
		 'J410' /* Simple chronic bronchitis */
		,'J411' /* Mucopurulent chronic bronchitis */
		,'J418' /* Mixed simple and mucopurulent chronic bronchitis */
		,'J430' /* MacLeod's syndrome */
		,'J431' /* Panlobular emphysema */
		,'J432' /* Centrilobular emphysema */
		,'J438' /* Other emphysema */
		,'J439' /* Emphysema, unspecified */
		,'J440' /* Chronic obstructive pulmonary disease with acute lower respiratory infection */
		,'J441' /* Chronic obstructive pulmonary disease with acute exacerbation, unspecified */
		,'J448' /* Other specified chronic obstructive pulmonary disease */
		,'J449' /* Chronic obstructive pulmonary disease, unspecified */
	)
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
      ,[moh_pri_diag_clinic_sys_code]
      ,[moh_pri_diag_sub_sys_code]
      ,[moh_pri_diag_diag_type_code]
      ,[moh_pri_diag_clinic_code]
	  ,'priv_COPD' AS [source]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags]
FROM [IDI_Clean_20200120].[moh_clean].[priv_fund_hosp_discharges_diag]
WHERE [moh_pri_diag_sub_sys_code] = [moh_pri_diag_clinic_sys_code] /* higher accuracy when systems match */
AND [moh_pri_diag_diag_type_code] IN ('A', 'B') /* diagnosies */
AND (
/* ICD9 codes */
[moh_pri_diag_clinic_sys_code] = '06' /* ICD9-CMA */
AND (
	SUBSTRING([moh_pri_diag_clinic_code], 1, 3) IN (
		 '490' /* Bronchitis, not specified as acute or chronic */
		,'496' /* Chronic airway obstruction, not elsewhere classified */
	) OR
	SUBSTRING([moh_pri_diag_clinic_code], 1, 4) IN (
		 '4910' /* Simple chronic bronchitis */
		,'4911' /* Mucopurulent chronic bronchitis */
		,'4918' /* Other chronic bronchitis */
		,'4919' /* Unspecified chronic bronchitis */
		,'4920' /* Emphysematous bleb */
		,'4928' /* Other emphysema */
	) OR
	SUBSTRING([moh_pri_diag_clinic_code], 1, 5) IN (
		 '49120' /* Obstructive chronic bronchitis without mention of acute exacerbation */
		,'49121' /* Obstructive chronic bronchitis with acute exacerbation */
	)
)
) OR (
/* ICD10 codes */
[moh_pri_diag_clinic_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM */
AND (
	SUBSTRING([moh_pri_diag_clinic_code], 1, 3) IN (
		 'J40' /* Bronchitis, not specified as acute or chronic */
		,'J42' /* Unspecified chronic bronchitis */
	) OR
	SUBSTRING([moh_pri_diag_clinic_code], 1, 4) IN (
		 'J410' /* Simple chronic bronchitis */
		,'J411' /* Mucopurulent chronic bronchitis */
		,'J418' /* Mixed simple and mucopurulent chronic bronchitis */
		,'J430' /* MacLeod's syndrome */
		,'J431' /* Panlobular emphysema */
		,'J432' /* Centrilobular emphysema */
		,'J438' /* Other emphysema */
		,'J439' /* Emphysema, unspecified */
		,'J440' /* Chronic obstructive pulmonary disease with acute lower respiratory infection */
		,'J441' /* Chronic obstructive pulmonary disease with acute exacerbation, unspecified */
		,'J448' /* Other specified chronic obstructive pulmonary disease */
		,'J449' /* Chronic obstructive pulmonary disease, unspecified */
	)
)
)

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags] ([event_id]);
GO

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pharm_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pharm_chronic_diags];
GO

/************************************ pharmaceuticals ************************************/
/* Ignores two chemical IDs. The chronic table also includes:
1056 - Aminophylline
1580 - Theophylline
Only if no previous diagnosis of asthma:
*/

SELECT [snz_uid]
      ,MIN([moh_pha_dispensed_date]) AS [moh_pha_dispensed_date]
	  --,[moh_pha_dim_form_pack_code]
	  --,[DIM_FORM_PACK_SUBSIDY_KEY]
      --,[CHEMICAL_ID]
      --,[CHEMICAL_NAME]
      --,[FORMULATION_ID]
      --,[FORMULATION_NAME]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pharm_chronic_diags]
FROM [IDI_Clean_20200120].[moh_clean].[pharmaceutical] a
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] b
ON a.[moh_pha_dim_form_pack_code] = b.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE snz_uid <> -1 /* remove non-personal identities */
AND (
	/* Ipratroprium Bromide, excluding formulation IDs 5 and 6. */
	([CHEMICAL_ID] = 1492 AND [FORMULATION_ID] NOT IN (5, 6))
	OR
	/* Salbutamol with Ipratroprium Bromide */
	[CHEMICAL_ID] = 6311 
	OR
	/* Tiotroprium Bromide */
	[CHEMICAL_ID] = 3805
)
GROUP BY [snz_uid]
	  --,[moh_pha_dim_form_pack_code]
	  --,[DIM_FORM_PACK_SUBSIDY_KEY]
      --,[CHEMICAL_ID]
      --,[CHEMICAL_NAME]
      --,[FORMULATION_ID]
      --,[FORMULATION_NAME]

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_obstructive_pulmonary_disease]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_obstructive_pulmonary_disease];
GO

/************************************ combined final table ************************************/

SELECT *
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_obstructive_pulmonary_disease]
FROM (
/* public */
SELECT [snz_uid]
	  --,[event_id]
      ,[source]
	  ,[moh_evt_evst_date] AS [start_date]
	  ,[moh_evt_even_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags] a
INNER JOIN [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_event] b
ON a.[event_id] = b.[moh_evt_event_id_nbr]

UNION ALL

/* private */
SELECT [snz_uid]
	  --,[event_id]
	  ,[source]
	  ,[moh_pri_evt_start_date] AS [start_date]
      ,[moh_pri_evt_end_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags] a
INNER JOIN [IDI_Clean_20200120].[moh_clean].[priv_fund_hosp_discharges_event] b
ON a.[event_id] = b.[moh_pri_evt_event_id_nbr]

UNION ALL

/* pharmaceuticals */
SELECT [snz_uid]
      --,NULL AS [event_id]
	  ,'pha_COPD' AS [source]
	  ,[moh_pha_dispensed_date] AS [start_date]
	  ,[moh_pha_dispensed_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pharm_chronic_diags]

) k

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_obstructive_pulmonary_disease] ([snz_uid]);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_chronic_obstructive_pulmonary_disease] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/************************************ tidy tempoary tables away ************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pfhd_chronic_diags];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_vfhd_chronic_diags];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pharm_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_pharm_chronic_diags];
GO
