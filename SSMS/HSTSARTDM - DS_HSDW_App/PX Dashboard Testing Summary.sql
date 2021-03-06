USE [DS_HSDW_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

--ALTER PROCEDURE [Rptg].[usp_Src_Dash_PatExp_CGCAHPS_Clinic_Test]
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
*********************************************************************************************/
SET NOCOUNT ON

IF OBJECT_ID('tempdb..#cgcahps_resp ') IS NOT NULL
DROP TABLE #cgcahps_resp

IF OBJECT_ID('tempdb..#surveys_op ') IS NOT NULL
DROP TABLE #surveys_op

IF OBJECT_ID('tempdb..#surveys_op_sum ') IS NOT NULL
DROP TABLE #surveys_op_sum

IF OBJECT_ID('tempdb..#surveys_op2_sum ') IS NOT NULL
DROP TABLE #surveys_op2_sum

IF OBJECT_ID('tempdb..#surveys_op3 ') IS NOT NULL
DROP TABLE #surveys_op3

IF OBJECT_ID('tempdb..#CGCAHPS_Clinics ') IS NOT NULL
DROP TABLE #CGCAHPS_Clinics

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
	 ,CAST(COALESCE(dept.DEPARTMENT_ID,'Unknown') AS VARCHAR(255)) AS Survey_Department_Id
	 ,dept.Clrt_DEPt_Nme AS Survey_Department_Name
	 ,loc_master.EPIC_DEPARTMENT_ID
	 ,loc_master.epic_department_name
	 ,loc_master.SERVICE_LINE_ID
	 ,CASE WHEN loc_master.opnl_service_name = 'Therapies' AND (loc_master.service_line IS NULL OR loc_master.SERVICE_LINE = 'Unknown') THEN 'Therapies'
		   WHEN loc_master.service_line IS NULL OR loc_master.service_line = 'Unknown' THEN 'Other'
		   ELSE loc_master.service_line END AS Survey_Service_Line
	 ,CASE WHEN loc_master.opnl_service_name = 'Therapies' AND (loc_master.service_line IS NULL OR loc_master.SERVICE_LINE = 'Unknown') THEN 'Therapies'
		   WHEN loc_master.service_line IS NULL OR loc_master.service_line = 'Unknown' THEN 'Other'
		   ELSE loc_master.service_line END AS SERVICE_LINE
	 ,MDM.sub_service_line
	 ,CASE WHEN dept.Clrt_DEPt_Nme IS NULL OR dept.Clrt_DEPt_Nme = 'Unknown' THEN 'Other' ELSE dept.Clrt_DEPt_Nme + ' [' + CAST(dept.DEPARTMENT_ID AS VARCHAR(250)) + ']' END AS Survey_Clinic
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
	 ,clinictemp.month_num
	 ,clinictemp.month_short_name
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
	    ,ddte.month_num
	    ,ddte.month_short_name
		FROM #cgcahps_resp AS Resp
	    INNER JOIN DS_HSDW_Prod.Rptg.vwDim_Date ddte
	        ON ddte.day_date = Resp.RECDATE
		INNER JOIN DS_HSDW_Prod.dbo.Dim_PG_Question AS qstn
			ON Resp.sk_Dim_PG_Question = qstn.sk_Dim_PG_Question
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

--SELECT DISTINCT
--	REC_FY
--  , Domain_Goals
--FROM #surveys_op
--WHERE REC_FY IN (2019,2020)
--ORDER BY REC_FY
--       , Domain_Goals

--SELECT DISTINCT
--	GOAL_FISCAL_YR
--  , DOMAIN
--FROM DS_HSDW_App.Rptg.CGCAHPS_Goals_Test
--WHERE GOAL_FISCAL_YR IN (2019,2020)
--ORDER BY GOAL_FISCAL_YR
--       , DOMAIN

------------------------------------------------------------------------------------------
--- GENERATE SUMMARY FOR TESTING

------------------------------------------------------------------------------------------

--SELECT DISTINCT
--	REC_FY,
--	month_num,
--	month_short_name,
--    Survey_Clinic,
--    Survey_Service_Line,
--	SERVICE_LINE_ID,
--    SERVICE_LINE,
--    CLINIC,
--    Survey_Department_Id,
--    Survey_Department_Name,
--    EPIC_DEPARTMENT_ID,
--    epic_department_name,
--    VALUE,
--	TOP_BOX,
--    VAL_COUNT,
--    DOMAIN,
--    Domain_Goals
----INTO #surveys_op_sum
--FROM #surveys_op resp
--WHERE REC_FY = 2020
--AND sk_Dim_PG_Question = 803 -- Rate Provider 0-10
--AND (Domain_Goals IS NOT NULL
--AND Domain_Goals <> 'Additional Questions About Your Care')
--ORDER BY resp.REC_FY
--       , resp.month_num
--	   , resp.month_short_name
--	   , resp.Survey_Service_Line
--	   , resp.Survey_Department_Id
--	   , resp.Survey_Department_Name
--	   , resp.Domain_Goals
--	   , resp.SERVICE_LINE
--	   , resp.EPIC_DEPARTMENT_ID
--	   , resp.epic_department_name

SELECT resp.REC_FY,
       resp.month_num,
       resp.month_short_name,
       resp.Survey_Clinic,
       resp.Survey_Service_Line,
       resp.Survey_Department_Id,
       resp.Survey_Department_Name,
       resp.Domain_Goals,
       resp.CLINIC,
       resp.SERVICE_LINE_ID,
       resp.SERVICE_LINE,
       resp.EPIC_DEPARTMENT_ID,
       resp.epic_department_name,
       SUM(resp.TOP_BOX) AS TOP_BOX,
       SUM(resp.VAL_COUNT) AS VAL_COUNT,
	   CAST(CAST(SUM(resp.TOP_BOX) AS NUMERIC(6,3)) / CAST(SUM(resp.VAL_COUNT) AS NUMERIC(6,3)) AS NUMERIC(4,3)) AS SCORE,
	   COUNT(*) AS N
INTO #surveys_op_sum
FROM
(
--SELECT DISTINCT
SELECT
	REC_FY,
	month_num,
	month_short_name,
    Survey_Clinic,
    Survey_Service_Line,
	SERVICE_LINE_ID,
    SERVICE_LINE,
    CLINIC,
    Survey_Department_Id,
    Survey_Department_Name,
    EPIC_DEPARTMENT_ID,
    epic_department_name,
    VALUE,
	TOP_BOX,
    VAL_COUNT,
    DOMAIN,
    Domain_Goals
--INTO #surveys_op_sum
FROM #surveys_op
--WHERE REC_FY = 2020
WHERE REC_FY IN (2019,2020)
--AND sk_Dim_PG_Question = 17 -- Rate Hospital 0-10
AND (Domain_Goals IS NOT NULL
AND Domain_Goals NOT IN
(
'Access to Specialists'
,'Additional Questions About Your Care'
,'Between Visit Communication'
,'Health Promotion and Education'
,'Education About Medication'
,'Shared Decision Making'
,'Stewardship of Patient Resources'
))
) resp
GROUP BY 
	REC_FY,
	month_num,
	month_short_name,
    Survey_Clinic,
    Survey_Service_Line,
	SERVICE_LINE_ID,
    SERVICE_LINE,
    CLINIC,
    Survey_Department_Id,
    Survey_Department_Name,
    EPIC_DEPARTMENT_ID,
    epic_department_name,
	Domain_Goals

--SELECT
--       REC_FY,
--       Survey_Clinic,
--       Survey_Service_Line,
--       Survey_Department_Id,
--       Survey_Department_Name,
--       Domain_Goals,
--       CLINIC,
--       SERVICE_LINE_ID,
--       SERVICE_LINE,
--       EPIC_DEPARTMENT_ID,
--       epic_department_name,
--       month_num,
--       month_short_name,
--       TOP_BOX,
--       VAL_COUNT,
--	   SCORE,
--	   N
--FROM #surveys_op_sum
----WHERE Survey_Service_Line = 'Heart and Vascular'
----WHERE Goals_Service_Line = 'Heart and Vascular'
----ORDER BY REC_FY
----       , month_num
----	   , month_short_name
----	   , Survey_Unit
----	   , Survey_Service_Line
----	   , Survey_Department_Id
----	   , Survey_Department_Name
----	   , Domain_Goals
----	   , Goals_UNIT
----	   , Goals_Service_Line
----	   , DEPARTMENT_ID
----	   , Clrt_DEPt_Nme
----ORDER BY Survey_Service_Line
----	   , Domain_Goals
----       , REC_FY
----       , month_num
----	   , month_short_name
----	   , Survey_Unit
----	   , Survey_Department_Id
----	   , Survey_Department_Name
----	   , Goals_UNIT
----	   , Goals_Service_Line
----	   , DEPARTMENT_ID
----	   , Clrt_DEPt_Nme
----ORDER BY REC_FY
----       , month_num
----	   , month_short_name
----	   , Survey_Unit
----	   , Survey_Service_Line
----	   , Survey_Department_Id
----	   , Survey_Department_Name
----	   , Domain_Goals
----	   , Goals_UNIT
----	   , Goals_Service_Line
----	   , DEPARTMENT_ID
----	   , Clrt_DEPt_Nme
--ORDER BY REC_FY
--	   , Survey_Clinic
--	   , Survey_Service_Line
--	   , Survey_Department_Id
--	   , Survey_Department_Name
--	   , Domain_Goals
--	   , CLINIC
--	   , SERVICE_LINE_ID
--	   , SERVICE_LINE
--	   , EPIC_DEPARTMENT_ID
--	   , epic_department_name
--       , month_num
--	   , month_short_name

------------------------------------------------------------------------------------------
-- JOIN TO DIM_DATE

 SELECT
	'CGCAHPS' AS Event_Type
	,rec.Fyear_num AS Event_FY
	,surveys_op_sum.Survey_Clinic
	,surveys_op_sum.Survey_Service_Line
	,surveys_op_sum.Survey_Department_Id
	,surveys_op_sum.Survey_Department_Name
	,surveys_op_sum.Domain_Goals
	,surveys_op_sum.CLINIC
	,surveys_op_sum.SERVICE_LINE_ID
	,surveys_op_sum.SERVICE_LINE
	,surveys_op_sum.EPIC_DEPARTMENT_ID
	,surveys_op_sum.epic_department_name
	,surveys_op_sum.month_num
	,surveys_op_sum.month_short_name
	,surveys_op_sum.TOP_BOX
	,surveys_op_sum.VAL_COUNT
	,surveys_op_sum.SCORE
	,surveys_op_sum.N
	,surveys_op_goals.GOAL
INTO #surveys_op2_sum
FROM #surveys_op_sum surveys_op_sum
LEFT OUTER JOIN
(
SELECT DISTINCT
	GOAL_FISCAL_YR,
    SERVICE_LINE,
    UNIT,
    EPIC_DEPARTMENT_ID,
    EPIC_DEPARTMENT_NAME,
    DOMAIN,
    GOAL
FROM DS_HSDW_App.Rptg.CGCAHPS_Goals_Test
WHERE UNIT = 'All Clinics'
) surveys_op_goals -- CHANGE BASED ON GOALS FROM BUSH - CREATE NEW CGCAHPS_Goals
ON surveys_op_sum.REC_FY = surveys_op_goals.GOAL_FISCAL_YR
AND surveys_op_sum.SERVICE_LINE = surveys_op_goals.SERVICE_LINE
AND surveys_op_sum.Domain_Goals = surveys_op_goals.DOMAIN  -- THIS IS SERVICE LINE LEVEL, USE THE SERVICE-LINE SPECIFIC GOAL, DENOTED BY UNIT "ALL CLINICS" (ALL UNITS W/I SERVICE LINE GET THE GOAL)
INNER JOIN
(
SELECT DISTINCT
	Fyear_num
FROM DS_HSDW_Prod.dbo.Dim_Date
WHERE day_date >= @startdate AND day_date <= @enddate
) rec
ON rec.Fyear_num = surveys_op_sum.REC_FY

SELECT Event_Type,
       Event_FY,
       Survey_Clinic,
       Survey_Service_Line,
       Survey_Department_Id,
       Survey_Department_Name,
       Domain_Goals,
       CLINIC,
	   SERVICE_LINE_ID,
       SERVICE_LINE,
       EPIC_DEPARTMENT_ID,
       epic_department_name,
       month_num,
       month_short_name,
       TOP_BOX,
       VAL_COUNT,
       SCORE,
       N,
       GOAL
FROM #surveys_op2_sum
ORDER BY Event_FY
	   , Survey_Clinic
	   , Survey_Service_Line
	   , Survey_Department_Id
	   , Survey_Department_Name
	   , Domain_Goals
	   , CLINIC
	   , SERVICE_LINE_ID
       , SERVICE_LINE
	   , EPIC_DEPARTMENT_ID
	   , epic_department_name
       , month_num
	   , month_short_name

/*
 SELECT
	'CGCAHPS' AS Event_Type
	,SURVEY_ID
	,sk_Fact_Pt_Acct
	,LEFT(DATENAME(MM, rec.day_date), 3) + ' ' + CAST(DAY(rec.day_date) AS VARCHAR(2)) AS Rpt_Prd
	,rec.day_date AS Event_Date
	,dis.day_date AS Event_Date_Disch
	,rec.Fyear_num AS Event_FY
	,sk_Dim_PG_Question
	,VARNAME
	,QUESTION_TEXT_ALIAS
	,#surveys_op.EPIC_DEPARTMENT_ID
	,SERVICE_LINE_ID
	,#surveys_op.SERVICE_LINE
	,sub_service_line
	,#surveys_op.CLINIC
	,#surveys_op.DOMAIN
	,Domain_Goals
	,RECDATE AS Recvd_Date
	,DISDATE AS Discharge_Date
	,MRN_int AS Patient_ID
	,Pat_Name
	,Pat_Sex
	,Pat_DOB
	,Pat_Age
	,Pat_Age_Survey_Recvd
	,Pat_Age_Survey_Answer
	,CASE WHEN Pat_Age_Survey_Answer < 18 THEN 1 ELSE 0 END AS Peds
	,NPINumber
	,Phys_Name
	,Phys_Dept
	,Phys_Div
	,GOAL
	,VALUE
	,Value_Resp_Grp
	,TOP_BOX
	,VAL_COUNT
	,rec.quarter_name
	,rec.month_short_name
INTO #surveys_op2
FROM
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) rec
LEFT OUTER JOIN #surveys_op
ON rec.day_date = #surveys_op.RECDATE
FULL OUTER JOIN
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
ON dis.day_date = #surveys_op.DISDATE
LEFT OUTER JOIN
	(SELECT * FROM DS_HSDW_App.Rptg.CGCAHPS_Goals_Test WHERE UNIT = 'All Clinics') goals -- CHANGE BASED ON GOALS FROM BUSH - CREATE NEW CGCAHPS_Goals
ON #surveys_op.REC_FY = goals.GOAL_FISCAL_YR AND #surveys_op.Service_Line = goals.SERVICE_LINE AND #surveys_op.Domain_Goals = goals.DOMAIN  -- THIS IS SERVICE LINE LEVEL, USE THE SERVICE-LINE SPECIFIC GOAL, DENOTED BY UNIT "ALL CLINICS" (ALL UNITS W/I SERVICE LINE GET THE GOAL)
ORDER BY Event_Date, SURVEY_ID, sk_Dim_PG_Question

----------------------------------------------------------------------------------------------------------------------------------------------------

-- SELF UNION TO ADD AN "All Clinics" CLINIC

SELECT * INTO #surveys_op3
FROM #surveys_op2
UNION ALL

(

	 SELECT
		'CGCAHPS' AS Event_Type
		,SURVEY_ID
		,sk_Fact_Pt_Acct
		,LEFT(DATENAME(MM, rec.day_date), 3) + ' ' + CAST(DAY(rec.day_date) AS VARCHAR(2)) AS Rpt_Prd
		,rec.day_date AS Event_Date
		,dis.day_date AS Event_Date_Disch
	    ,rec.Fyear_num AS Event_FY
		,sk_Dim_PG_Question
		,VARNAME
		,QUESTION_TEXT_ALIAS
		,#surveys_op.EPIC_DEPARTMENT_ID
		,SERVICE_LINE_ID
		,#surveys_op.SERVICE_LINE
		,sub_service_line
		,CASE WHEN SURVEY_ID IS NULL THEN NULL
			ELSE 'All Clinics' END AS CLINIC
		,#surveys_op.Domain
		,Domain_Goals
		,RECDATE AS Recvd_Date
		,DISDATE AS Discharge_Date
		,MRN_int AS Patient_ID
		,Pat_Name
		,Pat_Sex
		,Pat_DOB
		,Pat_Age
		,Pat_Age_Survey_Recvd
		,Pat_Age_Survey_Answer
		,CASE WHEN Pat_Age_Survey_Answer < 18 THEN 1 ELSE 0 END AS Peds
		,NPINumber
		,Phys_Name
		,Phys_Dept
		,Phys_Div
		,GOAL
		,VALUE
		,Value_Resp_Grp
		,TOP_BOX
		,VAL_COUNT
		,rec.quarter_name
		,rec.month_short_name
	FROM
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) rec
	LEFT OUTER JOIN #surveys_op
	ON rec.day_date = #surveys_op.RECDATE
	FULL OUTER JOIN
		(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
	ON dis.day_date = #surveys_op.DISDATE
	LEFT OUTER JOIN 
		(SELECT * FROM DS_HSDW_App.Rptg.CGCAHPS_Goals_Test WHERE UNIT = 'All Clinics') goals
		ON #surveys_op.REC_FY = goals.GOAL_FISCAL_YR AND #surveys_op.Domain_Goals = goals.DOMAIN AND goals.SERVICE_LINE = #surveys_op.SERVICE_LINE 
	WHERE (dis.day_date >= @startdate AND DIS.day_date <= @enddate) AND (rec.day_date >= @startdate AND rec.day_date <= @enddate)
)																							

----------------------------------------------------------------------------------------------------------------------
-- RESULTS

SELECT
	 [Event_Type]
	,[SURVEY_ID]
	,CASE WHEN CLINIC IN
	(	SELECT CLINIC
		FROM
		(	
			SELECT CLINIC, COUNT(DISTINCT(SERVICE_LINE)) AS SVC_LINES FROM #surveys_op3 
			WHERE CLINIC <> 'All Clinics'
			GROUP BY CLINIC
			HAVING COUNT(DISTINCT(SERVICE_lINE)) > 1
		) a
	) THEN CLINIC + ' - ' + SERVICE_LINE ELSE CLINIC END AS CLINIC -- adds svc line to clinics that appear in multiple service lines
	,CASE WHEN Sub_Service_Line IS NULL THEN [Service_Line]
		ELSE
		CASE WHEN SERVICE_LINE <> 'All Service Lines' THEN SERVICE_LINE + ' - ' + Sub_Service_Line
			ELSE SERVICE_LINE
			END
		END AS SERVICE_LINE
	,Sub_Service_Line
	,epic_department_id
	,service_line_id
	,[sk_Fact_Pt_Acct]
	,[Rpt_Prd]
	,[Event_Date]
	,[Event_Date_Disch]
	,Event_FY
	,[sk_Dim_PG_Question]
	,[VARNAME]
	,[QUESTION_TEXT_ALIAS]
	,[DOMAIN]
	,[Domain_Goals]
	,[Recvd_Date]
	,[Discharge_Date]
	,[Patient_ID]
	,[Pat_Name]
	,[Pat_Sex]
	,[Pat_DOB]
	,[Pat_Age]
	,[Pat_Age_Survey_Recvd]
	,[Pat_Age_Survey_Answer]
	,[Peds]
	,[NPINumber]
	,[Phys_Name]
	,[Phys_Dept]
	,[Phys_Div]
	,[GOAL]
	,[VALUE]
	,[Value_Resp_Grp]
	,[TOP_BOX]
	,[VAL_COUNT]
	,[quarter_name]
	,[month_short_name]
FROM #surveys_op3
*/
GO


