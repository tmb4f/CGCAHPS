USE [DS_HSDW_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

--ALTER PROCEDURE [Rptg].[usp_Src_Dash_PatExp_CGCAHPS_Locations]
--AS
/*******************************************************************************************
WHAT: Distinct list of clinics and service lines to allow comparison in Tableau.
WHO : Chris Mitchell
WHEN: 6/29/2017

WHY :
--------------------------------------------------------------------------------------------
INFO:
INPUTS:
	
OUTPUTS:
	
--------------------------------------------------------------------------------------------
MODS:  CM - 02/12/18 Use Epic Department name + [Epic Department ID] instead of external name
       CM - 02/12/18 Exclude Transplant clinics and service line
	  TMB - 10/21/10 Alter stored procedure
	  TMB - 12/18/19 Include Transplant Service Line Clinics
*********************************************************************************************/
SET NOCOUNT ON

----------------------------------------------
  ---BDD 2/21/2018 changed table drop and creation to permanent table with a truncate.
--EXEC dbo.usp_TruncateTable @schema = 'Rptg',@Table = 'CGCAHPS_Locations'

  ---BDD 2/21/2018 added column specifications to insert
--INSERT INTO Rptg.CGCAHPS_Locations (SERVICE_LINE,
--                                    CLINIC,
--								    EPIC_DEPARTMENT_ID
--                                   )
SELECT SERVICE_LINE, CLINIC, locations.EPIC_DEPARTMENT_ID
FROM
(
	SELECT
			CASE WHEN COUNT(CASE WHEN SERVICE_LINE IS NULL OR SERVICE_LINE = 'Unknown' THEN 'Other' ELSE SERVICE_LINE END) OVER (PARTITION BY CLINIC) > 1 THEN CLINIC + ' - ' + SERVICE_LINE ELSE CLINIC END AS CLINIC
			,responses.EPIC_DEPARTMENT_ID
			,CASE WHEN SERVICE_LINE IS NULL OR SERVICE_LINE = 'Unknown' THEN 'Other'
				ELSE
					CASE WHEN responses.SUB_SERVICE_LINE IS NOT NULL AND SUB_SERVICE_LINE <> 'Unknown' THEN SERVICE_LINE + ' - ' + responses.SUB_SERVICE_LINE
					ELSE SERVICE_LINE
					END
				END AS SERVICE_LINE
	FROM
	(
		SELECT DISTINCT
		 mdm.EPIC_DEPT_NAME + ' [' + CAST(mdm.EPIC_DEPARTMENT_ID AS VARCHAR(250)) + ']' AS CLINIC
	    ,CASE WHEN mdm.opnl_service_name = 'Therapies' AND (mdm.service_line IS NULL OR mdm.SERVICE_LINE = 'Unknown') THEN 'Therapies'
		   WHEN mdm.service_line IS NULL OR mdm.service_line = 'Unknown' THEN 'Other'
		   ELSE mdm.service_line END AS SERVICE_LINE
		,mdm.EPIC_DEPARTMENT_ID
		,mdm.Sub_Service_Line AS SUB_SERVICE_LINE
		FROM DS_HSDW_Prod.Rptg.vwFact_PressGaney_Responses resp
		LEFT OUTER JOIN DS_HSDW_Prod.dbo.Dim_Clrt_DEPt AS dep
		ON resp.sk_Dim_Clrt_DEPt = dep.sk_Dim_Clrt_DEPt
		LEFT OUTER JOIN DS_HSDW_Prod.Rptg.vwRef_MDM_Location_Master mdm
		ON dep.DEPARTMENT_ID = mdm.EPIC_DEPARTMENT_ID
				WHERE resp.sk_Dim_PG_Question IN
		(
			'784','707','711','715','719','721','729','731','754','776','788','790','795','797','799',
			'801','803','805','807','809','851','853','904','905','924','928','1256','1257','1259','725',
			'735','737','739','750','752','754','756','758','743','913','919','915','916','766','768','770','772','780','782','778'
		)
		AND resp.Svc_Cde = 'MD'
		AND (resp.RECDATE >= CAST(DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-24,GETDATE())),0) AS DATE) OR resp.DISDATE >= CAST(DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-24,GETDATE())),0) AS DATE))
	) responses
) locations
--WHERE locations.CLINIC IS NOT NULL AND SERVICE_LINE <> 'Transplant'
WHERE locations.CLINIC IS NOT NULL

ORDER BY locations.SERVICE_LINE
       , locations.EPIC_DEPARTMENT_ID

GO


