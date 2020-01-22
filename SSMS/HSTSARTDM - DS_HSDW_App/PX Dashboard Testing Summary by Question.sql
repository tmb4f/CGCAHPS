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
*********************************************************************************************/
SET NOCOUNT ON

---------------------------------------------------
---Default date range is the first day of the current month 2 years ago until the last day of the current month
DECLARE @currdate AS DATE;
DECLARE @startdate AS DATE;
DECLARE @enddate AS DATE;


    SET @currdate=CAST(GETDATE() AS DATE);

	SET @startdate = '7/1/2018'
	SET @enddate = '1/1/2020'

    IF @startdate IS NULL
        AND @enddate IS NULL
        BEGIN
            SET @startdate = CAST(DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-24,GETDATE())),0) AS DATE); 
            SET @enddate= CAST(EOMONTH(GETDATE()) AS DATE); 
        END; 

----------------------------------------------------

IF OBJECT_ID('tempdb..#cgcahps_resp ') IS NOT NULL
DROP TABLE #cgcahps_resp

IF OBJECT_ID('tempdb..#surveys_op ') IS NOT NULL
DROP TABLE #surveys_op

IF OBJECT_ID('tempdb..#surveys_op2 ') IS NOT NULL
DROP TABLE #surveys_op2

IF OBJECT_ID('tempdb..#surveys_op3 ') IS NOT NULL
DROP TABLE #surveys_op3

IF OBJECT_ID('tempdb..#CGCAHPS_Clinics ') IS NOT NULL
DROP TABLE #CGCAHPS_Clinics

IF OBJECT_ID('tempdb..#surveys_op_sum ') IS NOT NULL
DROP TABLE #surveys_op_sum

--IF OBJECT_ID('tempdb..#surveys_op_sum2 ') IS NOT NULL
--DROP TABLE #surveys_op_sum2

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

--SELECT 
--	resp.SURVEY_ID
--	,resp.sk_Dim_PG_Question
--	,resp.sk_Dim_Clrt_DEPt
--	,qstn.QUESTION_TEXT
--	,resp.sk_Fact_Pt_Acct
--	,resp.sk_Dim_Pt
--	,resp.Svc_Cde
--	,resp.RECDATE
--	,ddte.year_num
--	,ddte.month_num
--	,ddte.month_short_name
--	,resp.DISDATE
--	,resp.VALUE
--	,resp.sk_Dim_Physcn
--FROM #cgcahps_resp resp
--		LEFT OUTER JOIN DS_HSDW_Prod.dbo.Dim_PG_Question AS qstn
--			ON Resp.sk_Dim_PG_Question = qstn.sk_Dim_PG_Question
--	    INNER JOIN DS_HSDW_Prod.Rptg.vwDim_Date ddte
--	       ON ddte.day_date = Resp.RECDATE
--WHERE RECDATE BETWEEN '12/1/2018 00:00 AM' AND '3/31/2019 11:59 PM'
--ORDER BY sk_Dim_PG_Question
--       , sk_Dim_Clrt_DEPt
--       , ddte.year_num
--	   , ddte.month_num
--	   , ddte.month_short_name
--	   , resp.RECDATE

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
	 ,dept.DEPARTMENT_ID
	 ,loc_master.EPIC_DEPARTMENT_ID
	 ,loc_master.epic_department_name
	 ,loc_master.SERVICE_LINE_ID
	 ,loc_master.service_line AS loc_master_service_line
	 ,loc_master.opnl_service_name AS loc_master_opnl_service_name
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

--SELECT DISTINCT
--	REC_FY
--  , RECDATE
--  , epic_department_id
--  , SERVICE_LINE
--  , service_line_id
--  , CLINIC
--  , SURVEY_ID
--FROM #surveys_op
--WHERE REC_FY = 2019
--AND RECDATE BETWEEN '7/1/2018 00:00 AM' AND '7/31/2018 11:59 PM'
--AND epic_department_id = 10243003
--ORDER BY REC_FY
--       , RECDATE
--	   , SURVEY_ID

--SELECT
--	REC_FY
--  , ddte.month_num
--  , ddte.month_name
--  , SERVICE_LINE
--  , epic_department_id
--  , COUNT(*) AS SURVEY_ID
--FROM #surveys_op resp
--	    INNER JOIN DS_HSDW_Prod.Rptg.vwDim_Date ddte
--	       ON ddte.day_date = Resp.RECDATE
--WHERE REC_FY = 2019
--AND RECDATE BETWEEN '7/1/2018 00:00 AM' AND '3/31/2019 11:59 PM'
--AND SERVICE_LINE IN ('Digestive Health','Oncology','Primary Care','Other','Heart and Vascular','Medical Subspecialties','Musculoskeletal','Ophthalmology','Surgical Subspecialties','Womens and Childrens - Children','Womens and Childrens - Women','Neurosciences and Behavioral Health')
--AND epic_department_id IN (10243003
--,10210001
--,10242012
--,10239004
--,10399001
--,10212016
--,10228007
--,10214011
--,10210002
--,10210035
--,10244004
--,10228012
--,10245001
--,10280001
--,10341001
--,10377001
--,10211004
--,10230004
--,10211005
--,10354084
--,10228003
--,10250001
--)
--GROUP BY 
--	REC_FY
--  , ddte.month_num
--  , ddte.month_name
--  , SERVICE_LINE
--  , epic_department_id
--ORDER BY 
--	REC_FY
--  , ddte.month_num
--  , ddte.month_name
--  , SERVICE_LINE
--  , epic_department_id

--SELECT
--	     REC_FY
--	   , ddte.year_num
--       , ddte.month_num
--	   , ddte.month_short_name
--	   , resp.sk_Dim_Clrt_DEPt
--	   , resp.DEPARTMENT_ID
--	   , resp.Domain_Goals
--	   , resp.sk_Dim_PG_Question
--	   , resp.QUESTION_TEXT_ALIAS
--	   , resp.loc_master_service_line
--	   , resp.loc_master_opnl_service_name
--	   , resp.SERVICE_LINE
--	   , resp.epic_department_id
--	   , resp.CLINIC
--	   , COUNT(DISTINCT resp.SURVEY_ID) AS N
--FROM #surveys_op resp
--INNER JOIN DS_HSDW_Prod.Rptg.vwDim_Date ddte
--ON resp.RECDATE = ddte.day_date
--WHERE REC_FY = 2019
--AND RECDATE BETWEEN '12/1/2018 00:00 AM' AND '3/31/2019 11:59 PM'
--AND resp.DEPARTMENT_ID = 10399001
--GROUP BY REC_FY
--	   , ddte.year_num
--       , ddte.month_num
--	   , ddte.month_short_name
--	   , resp.sk_Dim_Clrt_DEPt
--	   , resp.DEPARTMENT_ID
--	   , resp.Domain_Goals
--	   , resp.sk_Dim_PG_Question
--	   , resp.QUESTION_TEXT_ALIAS
--	   , resp.loc_master_service_line
--	   , resp.loc_master_opnl_service_name
--	   , resp.SERVICE_LINE
--	   , resp.epic_department_id
--	   , resp.CLINIC
--	   --, resp.SURVEY_ID
--ORDER BY REC_FY
--	   , ddte.year_num
--       , ddte.month_num
--	   , ddte.month_short_name
--	   , resp.sk_Dim_Clrt_DEPt
--	   , resp.DEPARTMENT_ID
--	   , resp.Domain_Goals
--	   , resp.sk_Dim_PG_Question
--	   , resp.QUESTION_TEXT_ALIAS
--	   , resp.loc_master_service_line
--	   , resp.loc_master_opnl_service_name
--	   , resp.SERVICE_LINE
--	   , resp.epic_department_id
--	   , resp.CLINIC

------------------------------------------------------------------------------------------

-- JOIN TO DIM_DATE

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
	,#surveys_op.epic_department_name
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
	,rec.month_num
	,rec.year_num
INTO #surveys_op2
FROM
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) rec
LEFT OUTER JOIN #surveys_op
ON rec.day_date = #surveys_op.RECDATE
--FULL OUTER JOIN
--	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
--ON dis.day_date = #surveys_op.DISDATE
FULL OUTER JOIN
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date <= @enddate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
ON dis.day_date = #surveys_op.DISDATE
LEFT OUTER JOIN
	(SELECT * FROM DS_HSDW_App.Rptg.CGCAHPS_Goals WHERE UNIT = 'All Clinics') goals -- CHANGE BASED ON GOALS FROM BUSH - CREATE NEW CGCAHPS_Goals
ON #surveys_op.REC_FY = goals.GOAL_FISCAL_YR AND #surveys_op.Service_Line = goals.SERVICE_LINE AND #surveys_op.Domain_Goals = goals.DOMAIN  -- THIS IS SERVICE LINE LEVEL, USE THE SERVICE-LINE SPECIFIC GOAL, DENOTED BY UNIT "ALL CLINICS" (ALL UNITS W/I SERVICE LINE GET THE GOAL)
ORDER BY Event_Date, SURVEY_ID, sk_Dim_PG_Question

--SELECT DISTINCT
--	Event_FY
--  , Event_Date
--  , epic_department_id
--  , SERVICE_LINE
--  , service_line_id
--  , CLINIC
--  , SURVEY_ID
--  , Discharge_Date
--FROM #surveys_op2
--WHERE Event_FY = 2019
--AND Event_Date BETWEEN '7/1/2018 00:00 AM' AND '7/31/2018 11:59 PM'
--AND epic_department_id = 10243003
----ORDER BY Event_FY
----       , Event_Date
----	   , SURVEY_ID
--ORDER BY Discharge_Date

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
		,#surveys_op.epic_department_name
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
		,rec.month_num
		,rec.year_num
	FROM
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) rec
	LEFT OUTER JOIN #surveys_op
	ON rec.day_date = #surveys_op.RECDATE
	--FULL OUTER JOIN
	--	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @startdate AND day_date <= @enddate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
	--ON dis.day_date = #surveys_op.DISDATE
	FULL OUTER JOIN
		(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date <= @enddate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
	ON dis.day_date = #surveys_op.DISDATE
	LEFT OUTER JOIN 
		(SELECT * FROM DS_HSDW_App.Rptg.CGCAHPS_Goals WHERE UNIT = 'All Clinics') goals
		ON #surveys_op.REC_FY = goals.GOAL_FISCAL_YR AND #surveys_op.Domain_Goals = goals.DOMAIN AND goals.SERVICE_LINE = #surveys_op.SERVICE_LINE
	--WHERE (dis.day_date >= @startdate AND DIS.day_date <= @enddate) AND (rec.day_date >= @startdate AND rec.day_date <= @enddate)
	WHERE (rec.day_date >= @startdate AND rec.day_date <= @enddate)
)

--SELECT DISTINCT
--	CLINIC
--  , Event_FY
--  , Event_Date
--  , SURVEY_ID
--  , epic_department_id
--  , epic_department_name
--  , service_line_id
--  , SERVICE_LINE
--FROM #surveys_op3
--WHERE Event_FY = 2019
--AND Event_Date BETWEEN '7/1/2018 00:00 AM' AND '7/31/2018 11:59 PM'
--AND epic_department_id = 10243003
--ORDER BY CLINIC
--       , Event_FY
--       , Event_Date
--	   , SURVEY_ID																					

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
	,epic_department_name
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
	,month_num
	,year_num
INTO #CGCAHPS_Clinics
FROM #surveys_op3

--SELECT DISTINCT
----SELECT
--	Event_Type,
--	Event_FY,
--	year_num,
--	month_num,
--	month_short_name,
--    CLINIC,
--    SERVICE_LINE,
--    EPIC_DEPARTMENT_ID,
--    epic_department_name,
--    --VALUE,
--	--TOP_BOX,
--    --VAL_COUNT,
--    --DOMAIN,
--    --Domain_Goals,
--	--QUESTION_TEXT_ALIAS,
--	SURVEY_ID--,
--	--GOAL
----INTO #surveys_op_sum
----FROM #surveys_op
--FROM #CGCAHPS_Clinics
----FROM #surveys_op_sum
----WHERE REC_FY = 2020
--WHERE Event_FY IN (2019,2020)
----AND sk_Dim_PG_Question = 17 -- Rate Hospital 0-10
--AND (Domain_Goals IS NOT NULL
--AND Domain_Goals NOT IN
--(
--'Access to Specialists'
--,'Additional Questions About Your Care'
--,'Between Visit Communication'
--,'Health Promotion and Education'
--,'Education About Medication'
--,'Shared Decision Making'
--,'Stewardship of Patient Resources'
--))
--ORDER BY 
--	Event_Type,
--	Event_FY,
--	year_num,
--	month_num,
--	month_short_name,
--    CLINIC,
--    SERVICE_LINE,
--	--Domain_Goals,
--    EPIC_DEPARTMENT_ID,
--    epic_department_name

------------------------------------------------------------------------------------------
--- GENERATE SUMMARY FOR TESTING

------------------------------------------------------------------------------------------

SELECT resp.Event_Type,
       resp.Event_FY,
	   resp.year_num,
       resp.month_num,
       resp.month_short_name,
       resp.CLINIC,
       resp.SERVICE_LINE,
       resp.Domain_Goals,
	   resp.QUESTION_TEXT_ALIAS,
       resp.EPIC_DEPARTMENT_ID,
       resp.epic_department_name,
	   resp.GOAL,
       SUM(resp.TOP_BOX) AS TOP_BOX,
       SUM(resp.VAL_COUNT) AS VAL_COUNT,
	   --CAST(CAST(SUM(resp.TOP_BOX) AS NUMERIC(6,3)) / CAST(SUM(resp.VAL_COUNT) AS NUMERIC(6,3)) AS NUMERIC(4,3)) AS SCORE,
	   --COUNT(*) AS N
	   COUNT(DISTINCT resp.SURVEY_ID) AS SURVEY_ID_COUNT
INTO #surveys_op_sum
FROM
(
--SELECT DISTINCT
SELECT
	Event_Type,
	Event_FY,
	year_num,
	month_num,
	month_short_name,
    CLINIC,
    SERVICE_LINE,
    EPIC_DEPARTMENT_ID,
    epic_department_name,
    VALUE,
	TOP_BOX,
    VAL_COUNT,
    DOMAIN,
    Domain_Goals,
	QUESTION_TEXT_ALIAS,
	SURVEY_ID,
	GOAL
--INTO #surveys_op_sum
--FROM #surveys_op
FROM #CGCAHPS_Clinics
--WHERE REC_FY = 2020
WHERE Event_FY IN (2019,2020)
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
	Event_Type,
	Event_FY,
	year_num,
	month_num,
	month_short_name,
    CLINIC,
    SERVICE_LINE,
	Domain_Goals,
	QUESTION_TEXT_ALIAS,
    EPIC_DEPARTMENT_ID,
    epic_department_name,
	GOAL

--SELECT [sum].Event_Type,
--       [sum].Event_FY,
--       [sum].year_num,
--       [sum].month_num,
--       [sum].month_short_name,
--       [sum].CLINIC,
--       [sum].SERVICE_LINE,
--       [sum].Domain_Goals,
--       [sum].QUESTION_TEXT_ALIAS,
--       [sum].epic_department_id,
--       [sum].epic_department_name,
--       [sum].GOAL,
--       [sum].TOP_BOX,
--       [sum].VAL_COUNT,
--       [sum].SURVEY_ID_COUNT AS Question_N
--     , sum2.SURVEY_ID_COUNT AS Survey_N
--INTO #surveys_op_sum2
--FROM #surveys_op_sum [sum]
--LEFT OUTER JOIN
--(SELECT resp.Event_Type,
--       resp.Event_FY,
--	   resp.year_num,
--       resp.month_num,
--       resp.month_short_name,
--       resp.CLINIC,
--       resp.SERVICE_LINE,
--       --resp.Domain_Goals,
--	   --resp.QUESTION_TEXT_ALIAS,
--       resp.EPIC_DEPARTMENT_ID,
--       resp.epic_department_name,
--	   --resp.GOAL,
--       --SUM(resp.TOP_BOX) AS TOP_BOX,
--       --SUM(resp.VAL_COUNT) AS VAL_COUNT,
--	   COUNT(DISTINCT resp.SURVEY_ID) AS SURVEY_ID_COUNT
----INTO #surveys_op_sum
--FROM
--(
--SELECT DISTINCT
----SELECT
--	Event_Type,
--	Event_FY,
--	year_num,
--	month_num,
--	month_short_name,
--    CLINIC,
--    SERVICE_LINE,
--    EPIC_DEPARTMENT_ID,
--    epic_department_name,
--    --VALUE,
--	--TOP_BOX,
--    --VAL_COUNT,
--    --DOMAIN,
--    --Domain_Goals,
--	--QUESTION_TEXT_ALIAS,
--	SURVEY_ID--,
--	--GOAL
----INTO #surveys_op_sum
----FROM #surveys_op
--FROM #CGCAHPS_Clinics
----FROM #surveys_op_sum
----WHERE REC_FY = 2020
--WHERE Event_FY IN (2019,2020)
----AND sk_Dim_PG_Question = 17 -- Rate Hospital 0-10
----AND (Domain_Goals IS NOT NULL
----AND Domain_Goals NOT IN
----(
----'Access to Specialists'
----,'Additional Questions About Your Care'
----,'Between Visit Communication'
----,'Health Promotion and Education'
----,'Education About Medication'
----,'Shared Decision Making'
----,'Stewardship of Patient Resources'
----))
--) resp
--GROUP BY 
--	Event_Type,
--	Event_FY,
--	year_num,
--	month_num,
--	month_short_name,
--    CLINIC,
--    SERVICE_LINE,
--	--Domain_Goals,
--	--QUESTION_TEXT_ALIAS,
--    EPIC_DEPARTMENT_ID,
--    epic_department_name--,
--	--GOAL
--) sum2
--ON sum2.Event_Type = sum.Event_Type
--AND sum2.Event_FY = sum.Event_FY
--AND sum2.year_num = sum.year_num
--AND sum2.month_num = sum.month_num
--AND sum2.month_short_name = sum.month_short_name
--AND sum2.CLINIC = sum.CLINIC
--AND sum2.SERVICE_LINE = sum.SERVICE_LINE
----AND sum2.Domain_Goals = sum.Domain_Goals
--AND sum2.epic_department_id = sum.epic_department_id
--AND sum2.epic_department_name = sum.epic_department_name


SELECT Event_Type,
       Event_FY,
       month_num AS [Month],
       month_short_name AS Month_Name,
       Service_Line,
       epic_department_id AS DEPARTMENT_ID,
       epic_department_name AS DEPARTMENT_NAME,
       CLINIC,
       Domain_Goals,
       QUESTION_TEXT_ALIAS,
       TOP_BOX,
       VAL_COUNT,
       SURVEY_ID_COUNT AS N,
    --   Question_N,
	   --Survey_N,
       GOAL
FROM #surveys_op_sum
--FROM #surveys_op_sum2
ORDER BY Event_Type
       , Event_FY
	   , year_num
       , month_num
	   , month_short_name
	   , Service_Line
	   , epic_department_id
	   , epic_department_name
	   , CLINIC
	   , Domain_Goals
	   , QUESTION_TEXT_ALIAS

GO


