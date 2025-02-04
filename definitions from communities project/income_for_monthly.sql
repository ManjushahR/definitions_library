/**************************************************************************************************
Title: Income suitable for monthly income summary
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[data].[income_tax_yr_summary]
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_annual_income_non_WAS_BEN_PEN]
- [IDI_UserCode].[DL-MAA2016-15].[defn_monthly_income_WAS]
- [IDI_UserCode].[DL-MAA2016-15].[defn_monthly_income_BEN]
- [IDI_UserCode].[DL-MAA2016-15].[defn_monthly_income_PEN]

Description:
Tables from which monthly income can be determined. Using monthly values where available,
and pro rate values where only annual records are available.

Intended purpose:
Calculating monthly income from different sources and in grand total.
 
Notes:
1) Following a conversation with a staff member from IRD we were advised to use
   - IR3 data where possible.
   - PTS data where IR3 is not available
   - EMS date where IR3 and PTS are not available.
2) A comparison of total incomes from these three sources showed excellent consistency
   between [ir_ir3_gross_earnings_407_amt], [ir_pts_tot_gross_earnings_amt], [ir_ems_gross_earnings_amt]
   with the vast majority of our sample of records having identical values across all three.
3) To produce incomes at a resolution less than yearly, and use of the annual values
   recorded in [defn_annual_income_non_WAS_BEN_PEN] needs to be proportional/pro rate.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
 
Issues:
- IR3 records in the IDI do not capture all income reported to IRD via IR3 records. As per the data
  dictionary only "active items that have non-zero partnership, self-employment, or shareholder salary
  income" are included. So people with IR3 income that is of a different type (e.g. rental income)
  may not appear in the data.
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Annual income by tax year */
IF OBJECT_ID('[DL-MAA2016-15].[defn_annual_income_non_WAS_BEN_PEN]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_annual_income_non_WAS_BEN_PEN];
GO

CREATE VIEW [DL-MAA2016-15].[defn_annual_income_non_WAS_BEN_PEN] AS
SELECT [snz_uid]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr]  ,  3, 31) AS [event_date]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr]-1,  4,  1) AS [start_date]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr],    3, 31) AS [end_date]

	  /* components */
      ,[inc_tax_yr_sum_WHP_tot_amt]
      ,[inc_tax_yr_sum_ACC_tot_amt]
      ,[inc_tax_yr_sum_PPL_tot_amt]
      ,[inc_tax_yr_sum_STU_tot_amt]
      ,[inc_tax_yr_sum_C00_tot_amt]
      ,[inc_tax_yr_sum_C01_tot_amt]
      ,[inc_tax_yr_sum_C02_tot_amt]
      ,[inc_tax_yr_sum_P00_tot_amt]
      ,[inc_tax_yr_sum_P01_tot_amt]
      ,[inc_tax_yr_sum_P02_tot_amt]
      ,[inc_tax_yr_sum_S00_tot_amt]
      ,[inc_tax_yr_sum_S01_tot_amt]
      ,[inc_tax_yr_sum_S02_tot_amt]
      ,[inc_tax_yr_sum_S03_tot_amt]

	  /* total annual amounts */
	  ,[inc_tax_yr_sum_WHP_tot_amt]
      +[inc_tax_yr_sum_ACC_tot_amt]
      +[inc_tax_yr_sum_PPL_tot_amt]
      +[inc_tax_yr_sum_STU_tot_amt]
      +[inc_tax_yr_sum_C00_tot_amt]
      +[inc_tax_yr_sum_C01_tot_amt]
      +[inc_tax_yr_sum_C02_tot_amt]
      +[inc_tax_yr_sum_P00_tot_amt]
      +[inc_tax_yr_sum_P01_tot_amt]
      +[inc_tax_yr_sum_P02_tot_amt]
      +[inc_tax_yr_sum_S00_tot_amt]
      +[inc_tax_yr_sum_S01_tot_amt]
      +[inc_tax_yr_sum_S02_tot_amt]
      +[inc_tax_yr_sum_S03_tot_amt] AS [total_income_excl_WAS_BEN_PEN]
      
	  /* excluded as available at monthly level from EMS */
	  --,[inc_tax_yr_sum_WAS_tot_amt]
      --,[inc_tax_yr_sum_BEN_tot_amt]
      --,[inc_tax_yr_sum_PEN_tot_amt]
      
FROM [IDI_Clean_20200120].[data].[income_tax_yr_summary]
WHERE snz_uid > 0
GO

/* Wages and Salaries */
IF OBJECT_ID('[DL-MAA2016-15].[defn_monthly_income_WAS]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_monthly_income_WAS];
GO

CREATE VIEW [DL-MAA2016-15].[defn_monthly_income_WAS] AS
SELECT [snz_uid]
      ,[ir_ems_return_period_date]
      ,[ir_ems_gross_earnings_amt]
      ,[ir_ems_income_source_code]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code] = 'W&S'
AND snz_uid > 0;
GO

/* Benefits */
IF OBJECT_ID('[DL-MAA2016-15].[defn_monthly_income_BEN]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_monthly_income_BEN];
GO

CREATE VIEW [DL-MAA2016-15].[defn_monthly_income_BEN] AS
SELECT [snz_uid]
      ,[ir_ems_return_period_date]
      ,[ir_ems_gross_earnings_amt]
      ,[ir_ems_income_source_code]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code] = 'BEN'
AND snz_uid > 0;
GO

/* Pensions */
IF OBJECT_ID('[DL-MAA2016-15].[defn_monthly_income_PEN]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_monthly_income_PEN];
GO

CREATE VIEW [DL-MAA2016-15].[defn_monthly_income_PEN] AS
SELECT [snz_uid]
      ,[ir_ems_return_period_date]
      ,[ir_ems_gross_earnings_amt]
      ,[ir_ems_income_source_code]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code] = 'PEN'
AND snz_uid > 0;
GO
