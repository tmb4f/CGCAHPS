USE [DS_HSDW_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

--ALTER PROCEDURE [Rptg].[usp_Src_Dash_PatExp_CGCAHPS_Clinic]

--AS
/*******************************************************************************************
WHAT: Produce data for Patient Experience CGCAHPS Dashboard (Clinic Tab).
WHO : Chris Mitchell
WHEN: 3/16/2017

WHY :
--------------------------------------------------------------------------------------------
INFO:
INPUTS:
	
OUTPUTS:
	
--------------------------------------------------------------------------------------------
MODS (copied from HCAHPS procs, still relevant to CGCAHPS):
	10/12/16 -- Clean variable reporting.  Don't want to include reponses that shouldn't have been answered.  Report on clean var when applicable - sk_pg_dim_question id's changed to CL version
	10/12/16 -- Removed AND resp.sk_Fact_Pt_Acct > 0 criteria - was dropping surveys
	10/13/16 -- !!!THERE IS NO UNIT FOR OUTPATIENT - THERE IS A SITE VARIABLE THOUGH, JUST ID'S - DETERMINE MAPPING!!!
	1/31/2017 - Per Patient Experience Office, include adjusted removed surveys (all in)
			- Per Patient Experience Office, send unit "No Unit" to "Other" and include in "All Units" - same for clinics until instructed otherwise
			- Per Patient Experience Office, send No Service Line to Other Service Line and include in
			  "All Service Lines"
	2/3/2017 - Added questions to selected questions
	3/20/2017 - Added Department Specialty to provide an intermediate distinction b/t clinics
	3/27/2017 - Addressed Clinics that appear in one than one service line (Genetic Counseling, Diabetes Education & Mgmt, etc...)
	11/27/2017 - CM: Added Epic Department ID support.  No longer reporting by RSS Group and Location
	01/18/2018 - CM:  changed sub service line to pull from mdm view.  bscm doesn't have a subservce line for every clinic needed, and epicsvc doesn't have sub service line
	02/12/2018 - CM:  switch to reporting epic dept name + [epic department id]
	02/12/2018 - CM:  Pull Therapies Operational Service Line Where applicable as Service Line
    09/30/2019 - TMB: changed logic that assigns targets to domains
	11/19/2019 - TMB: Remove restrictions for discharge date range
	01/16/2019 - TMB: Optimize code for better performance
*********************************************************************************************/
SET NOCOUNT ON

if OBJECT_ID('tempdb..#cgcahps_resp') is not NULL
DROP TABLE #cgcahps_resp

if OBJECT_ID('tempdb..#surveys_op') is not NULL
DROP TABLE #surveys_op

---------------------------------------------------
---Default date range is the first day of the current month 2 years ago until the last day of the current month
DECLARE @currdate AS DATE;
DECLARE @startdate AS DATE;
DECLARE @enddate AS DATE;


    SET @currdate=CAST(GETDATE() AS DATE);

    IF @startdate IS NULL
        AND @enddate IS NULL
        BEGIN
            SET @startdate = CAST(DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-24,GETDATE())),0) AS DATE); 
            SET @enddate= CAST(EOMONTH(GETDATE()) AS DATE); 
        END; 

----------------------------------------------------
DECLARE @locstartdate SMALLDATETIME,
        @locenddate SMALLDATETIME

SET @locstartdate = @startdate
SET @locenddate   = @enddate

SELECT
	SURVEY_ID
	,sk_Dim_PG_Question
	,sk_Fact_Pt_Acct
	,sk_Dim_Pt
	,Svc_Cde
	,RECDATE
	,DISDATE
	,CAST(VALUE AS NVARCHAR(500)) AS VALUE
	,sk_Dim_Clrt_DEPt
	,sk_Dim_Physcn
INTO #cgcahps_resp
FROM DS_HSDW_Prod.Rptg.vwFact_PressGaney_Responses
WHERE sk_Dim_PG_Question IN
(
	'784','707','711','715','719','721','729','731','754','776','788','790','795','797','799',
	'801','803','805','807','809','851','853','904','905','924','928','1256','1257','1259','725',
	'735','737','739','750','752','754','756','758','743','913','919','915','916','766','768','770','772','780','782','778'
)
AND RECDATE BETWEEN @locstartdate AND @locenddate
ORDER BY sk_Dim_PG_Question, RECDATE, SURVEY_ID

  -- Create index for temp table #cgcahps_resp
  CREATE CLUSTERED INDEX IX_cgcahps_resp ON #cgcahps_resp (sk_Dim_PG_Question, RECDATE, SURVEY_ID)

----------------------------------------------------------------------------------------------------

SELECT DISTINCT
	  clinictemp.SURVEY_ID
	 ,clinictemp.sk_Fact_Pt_Acct
	 ,clinictemp.RECDATE
	 ,clinictemp.DISDATE
	 ,clinictemp.REC_FY
	 ,clinictemp.Phys_Name
	 ,clinictemp.Phys_Dept
	 ,clinictemp.Phys_Div
	 ,clinictemp.sk_Dim_Clrt_DEPt
	 ,loc_master.EPIC_DEPARTMENT_ID
	 ,loc_master.SERVICE_LINE_ID
	 ,CASE WHEN loc_master.opnl_service_name = 'Therapies' AND (loc_master.service_line IS NULL OR loc_master.SERVICE_LINE = 'Unknown') THEN 'Therapies'
		   WHEN loc_master.service_line IS NULL OR loc_master.service_line = 'Unknown' THEN 'Other'
		   ELSE loc_master.service_line END AS SERVICE_LINE
	 ,MDM.sub_service_line
	 ,CASE WHEN loc_master.epic_department_name IS NULL OR loc_master.epic_department_name = 'Unknown' THEN 'Other' ELSE loc_master.epic_department_name + ' [' + CAST(loc_master.epic_department_id AS VARCHAR(250)) + ']' END AS CLINIC
	 ,clinictemp.VALUE
	 ,clinictemp.VAL_COUNT
	 ,clinictemp.DOMAIN
	 ,clinictemp.Domain_Goals
	 ,clinictemp.Value_Resp_Grp
	 ,clinictemp.TOP_BOX
	 ,clinictemp.VARNAME
	 ,clinictemp.sk_Dim_PG_Question
	 ,clinictemp.QUESTION_TEXT_ALIAS
	 ,clinictemp.MRN_int
	 ,clinictemp.NPINumber
	 ,clinictemp.Pat_Name
	 ,clinictemp.Pat_DOB
	 ,clinictemp.Pat_Age
	 ,clinictemp.Pat_Age_Survey_Recvd
	 ,clinictemp.Pat_Age_Survey_Answer
	 ,clinictemp.Pat_Sex
INTO #surveys_op
FROM
(
	SELECT DISTINCT
		 Resp.SURVEY_ID
		,Resp.sk_Fact_Pt_Acct
		,fpa.MRN_int
		,phys.NPINumber
		,ISNULL(pat.PT_LNAME + ', ' + pat.PT_FNAME_MI, NULL) AS Pat_Name
		,phys.DisplayName AS Phys_Name
		,phys.DEPT AS Phys_Dept
		,phys.Division AS Phys_Div
		,Resp.sk_Dim_Clrt_DEPt
		,Resp.RECDATE
		,Resp.DISDATE
	    ,ddte.Fyear_num AS REC_FY
		,CAST(Resp.VALUE AS NVARCHAR(500)) AS VALUE -- prevents Tableau from erroring out on import data source
		,CASE WHEN Resp.VALUE IS NOT NULL THEN 1 ELSE 0 END AS VAL_COUNT
		,extd.DOMAIN
		,CASE WHEN Resp.sk_Dim_PG_Question = '803' THEN 'Overall Doctor Rating 0-10'
				WHEN Resp.sk_Dim_PG_Question = '805' THEN 'Recommend Provider'
				ELSE extd.DOMAIN END AS Domain_Goals -- MAY REQUIRE AN UPDATE IF PATIENT EXPERIENCE HAS RESTATED DOMAINS FOR THEIR GOALS, SPLITTING FOR OVERALL ASSESSMENT B/C GOALS PROVIDED FOR RATING AND RECOMMEND QUESTIONS.
		,CASE WHEN Resp.sk_Dim_PG_Question = '803' THEN -- Rate Provider 0-10
			CASE WHEN Resp.VALUE IN ('10-Best provider','9') THEN 'Very Good'
				WHEN Resp.VALUE IN ('7','8') THEN 'Good'
				WHEN Resp.VALUE IN ('5','6') THEN 'Average'
				WHEN Resp.VALUE IN ('3','4') THEN 'Poor'
				WHEN Resp.VALUE IN ('0-Worst provider','1','2') THEN 'Very Poor'
			END
			ELSE
			CASE WHEN resp.sk_Dim_PG_Question <> '784' THEN -- Age
				CASE WHEN Resp.VALUE = '5' THEN 'Very Good'
					WHEN Resp.VALUE = '4' THEN 'Good'
					WHEN Resp.VALUE = '3' THEN 'Average'
					WHEN Resp.VALUE = '2' THEN 'Poor'
					WHEN Resp.VALUE = '1' THEN 'Very Poor'
					ELSE CAST(Resp.VALUE AS NVARCHAR(500))
				END
			ELSE CAST(Resp.VALUE AS NVARCHAR(500))
			END
			END AS Value_Resp_Grp
		,CASE WHEN Resp.sk_Dim_PG_Question IN ('851','853','904','905','924','928','1256','1257','1259')
		AND Resp.VALUE = '5' THEN 1 -- 1-5 scale questions
			ELSE
			CASE WHEN resp.sk_Dim_PG_Question = '803' AND resp.VALUE IN ('10-Best provider','9') THEN 1 -- Rate Provider 0-10
			ELSE
				CASE WHEN resp.sk_Dim_PG_Question IN ('715','719','729','776','915','916') AND Resp.VALUE = 'Always' THEN 1 -- Always, Usually, Sometimes, Never scale questions
				ELSE
					CASE WHEN resp.sk_Dim_PG_Question IN ('788','790','795','797','799','801','805','807','809') AND Resp.VALUE = 'Yes, definitely' THEN 1 -- Yes definitely, Yes somewhat, No scale questions
					ELSE
						CASE WHEN Resp.sk_Dim_PG_Question IN ('707','711','721','731','754','725','735','737','739','750','752','754','756','758','743','913',
						'919','766','768','770','772','780','782','778') AND Resp.VALUE = 'Yes' THEN 1 -- Yes/No scale questions
						ELSE 0
						END
					END
				END
			END
			END AS TOP_BOX
		,qstn.VARNAME
		,qstn.sk_Dim_PG_Question
		,extd.QUESTION_TEXT_ALIAS -- Short form of a question text
		,age.AGE AS Pat_Age_Survey_Answer
		,pat.BIRTH_DT AS PAT_DOB
		,FLOOR((CAST(GETDATE() AS INTEGER) - CAST(pat.BIRTH_DT AS INTEGER)) / 365.25) AS Pat_Age -- actual age today
		,FLOOR((CAST(Resp.RECDATE AS INTEGER) - CAST(pat.BIRTH_DT AS INTEGER)) / 365.25) AS Pat_Age_Survey_Recvd -- Age when survey received
		,CASE WHEN pat.PT_SEX = 'F' THEN 'Female' WHEN pat.PT_SEX = 'M' THEN 'Male' ELSE 'Not Specified' END AS Pat_Sex
		FROM #cgcahps_resp AS Resp
		INNER JOIN DS_HSDW_Prod.dbo.Dim_PG_Question AS qstn
			ON Resp.sk_Dim_PG_Question = qstn.sk_Dim_PG_Question
	    INNER JOIN DS_HSDW_Prod.Rptg.vwDim_Date ddte
	       ON ddte.day_date = Resp.RECDATE
		LEFT OUTER JOIN
		(
			SELECT DISTINCT
				SURVEY_ID, CAST(MAX(VALUE) AS NVARCHAR(500)) AS AGE FROM DS_HSDW_Prod.Rptg.vwFact_PressGaney_Responses
				WHERE Svc_Cde = 'MD' AND sk_Dim_PG_Question = '784'
				GROUP BY SURVEY_ID
		) age
			ON Resp.SURVEY_ID = age.SURVEY_ID
		LEFT OUTER JOIN DS_HSDW_Prod.dbo.Fact_Pt_Acct AS fpa
			ON Resp.sk_Fact_Pt_Acct = fpa.sk_Fact_Pt_Acct
		LEFT OUTER JOIN DS_HSDW_Prod.dbo.Dim_Pt AS pat
			ON Resp.sk_dim_pt = pat.sk_Dim_Pt
		LEFT OUTER JOIN DS_HSDW_Prod.dbo.Dim_Physcn AS phys
			ON Resp.sk_Dim_Physcn = phys.sk_Dim_Physcn
		LEFT OUTER JOIN
			(
				SELECT DISTINCT sk_Dim_PG_Question, DOMAIN, QUESTION_TEXT_ALIAS FROM DS_HSDW_App.Rptg.PG_Extnd_Attr
			) extd
			ON RESP.sk_Dim_PG_Question = extd.sk_Dim_PG_Question
) AS clinictemp
LEFT OUTER JOIN DS_HSDW_Prod.Rptg.vwDim_Clrt_DEPt dept
	ON clinictemp.sk_Dim_Clrt_DEPt = dept.sk_Dim_Clrt_DEPt
LEFT OUTER JOIN DS_HSDW_Prod.Rptg.vwRef_MDM_Location_Master_EpicSvc AS loc_master
	ON dept.DEPARTMENT_ID = loc_master.EPIC_DEPARTMENT_ID
LEFT OUTER JOIN
	(SELECT
		 EPIC_DEPARTMENT_ID
		,MAX(CASE WHEN Sub_Service_Line = 'Unknown' OR SUB_SERVICE_LINE IS NULL THEN NULL ELSE SUB_SERVICE_LINE END) AS SUB_SERVICE_LINE
	 FROM DS_HSDW_Prod.Rptg.vwRef_MDM_Location_Master
	 GROUP BY EPIC_DEPARTMENT_ID
	) MDM -- MDM_epicsvc view doesn't include sub service line
	ON loc_master.epic_department_id = MDM.[EPIC_DEPARTMENT_ID]
WHERE clinictemp.RECDATE >= '7/1/2019 00:00 AM'

------------------------------------------------------------------------------------------

SELECT DISTINCT
    SERVICE_LINE,
    UNIT,
    DOMAIN
FROM DS_HSDW_App.Rptg.PX_Goal_Setting
WHERE Service = 'CGCAHPS'
AND SERVICE_LINE =  'All Service Lines - All Sites'
AND UNIT = 'All Service Lines'
ORDER BY SERVICE_LINE
       , UNIT
	   , DOMAIN

SELECT DISTINCT
	resp.Domain_Goals
FROM #surveys_op resp
WHERE resp.Domain_Goals IS NOT NULL
ORDER BY resp.Domain_Goals

------------------------------------------------------------------------------------------

SELECT DISTINCT
    SERVICE_LINE
FROM DS_HSDW_App.Rptg.PX_Goal_Setting
WHERE Service = 'CGCAHPS'
ORDER BY SERVICE_LINE

SELECT DISTINCT
	resp.SERVICE_LINE
FROM #surveys_op resp
ORDER BY resp.SERVICE_LINE

------------------------------------------------------------------------------------------

SELECT DISTINCT
    SERVICE_LINE
  , UNIT
FROM DS_HSDW_App.Rptg.PX_Goal_Setting
WHERE Service = 'CGCAHPS'
ORDER BY SERVICE_LINE
       , UNIT

SELECT DISTINCT
	resp.SERVICE_LINE
FROM #surveys_op resp
ORDER BY resp.SERVICE_LINE

--SELECT SURVEY_ID
--      ,RECDATE
--	  ,DISDATE
--	  ,resp.epic_department_id
--	  ,resp.SERVICE_LINE
--	  ,CLINIC
--	  ,sk_Dim_PG_Question
--	  ,Domain_Goals
--	  ,resp.DOMAIN AS resp_DOMAIN
--	  ,goals.DOMAIN AS goals_DOMAIN
--	  ,QUESTION_TEXT_ALIAS
--	  ,goals.GOAL
--SELECT DISTINCT
--       resp.epic_department_id
--	  ,resp.SERVICE_LINE
--	  ,CLINIC
--	  ,sk_Dim_PG_Question
--	  ,Domain_Goals
--	  ,resp.DOMAIN AS resp_DOMAIN
--	  ,goals.DOMAIN AS goals_DOMAIN
--	  ,QUESTION_TEXT_ALIAS
--	  ,goals.GOAL
--SELECT DISTINCT
--       Domain_Goals
--	  ,resp.DOMAIN AS resp_DOMAIN
--	  ,goals.DOMAIN AS goals_DOMAIN
--	  ,goals.GOAL
--FROM #surveys_op resp
--LEFT OUTER JOIN
--(
--SELECT *
--FROM DS_HSDW_App.Rptg.PX_Goal_Setting
--WHERE Service = 'CGCAHPS'
--AND SERVICE_LINE =  'All Service Lines - All Sites'
--AND UNIT = 'All Service Lines'
--) goals
--ON goals.DOMAIN = resp.Domain_Goals
--ORDER BY goals.GOAL DESC

GO


