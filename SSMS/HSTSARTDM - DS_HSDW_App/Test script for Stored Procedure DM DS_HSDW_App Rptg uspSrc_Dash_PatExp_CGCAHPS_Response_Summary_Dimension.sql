USE [DS_HSDW_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

DECLARE @StartDate SMALLDATETIME
       ,@EndDate SMALLDATETIME

--SET @StartDate = NULL
--SET @EndDate = NULL
SET @StartDate = '7/1/2018'
--SET @EndDate = '12/29/2019'
--SET @StartDate = '7/1/2019'
SET @EndDate = '1/2/2020'

DECLARE @in_servLine VARCHAR(MAX)

DECLARE @ServiceLine TABLE (ServiceLine VARCHAR(50))

INSERT INTO @ServiceLine
(
    ServiceLine
)
VALUES
--(1),--Digestive Health
--(2),--Heart and Vascular
--(3),--Medical Subspecialties
--(4),--Musculoskeletal
--(5),--Neurosciences and Behavioral Health
--(6),--Oncology
--(7),--Ophthalmology
--(8),--Primary Care
--(9),--Surgical Subspecialties
--(10),--Transplant
--(11) --Womens and Childrens
--(0)  --(All)
--(1) --Digestive Health
--(1),--Digestive Health
--(2) --Heart and Vascular
--('Digestive Health'),
--('Heart and Vascular'),
--('Medical Subspecialties'),
--('Musculoskeletal'),
--('Neurosciences and Behavioral Health'),
--('Oncology'),
--('Ophthalmology'),
--('Primary Care'),
--('Surgical Subspecialties'),
--('Transplant'),
--('Womens and Childrens')
--('Digestive Health'),
--('Heart and Vascular')
('Digestive Health')

SELECT @in_servLine = COALESCE(@in_servLine+',' ,'') + CAST(ServiceLine AS VARCHAR(MAX))
FROM @ServiceLine

--SELECT @in_servLine

--CREATE PROC [Rptg].[uspSrc_Dash_PatExp_CGCAHPS_Response_Summary_Dimension]
--    (
--     @StartDate SMALLDATETIME = NULL,
--     @EndDate SMALLDATETIME = NULL,
     --@in_servLine VARCHAR(MAX),
--    )
--AS
/**********************************************************************************************************************
WHAT: Stored procedure for Patient Experience Dashboard - CGCAHPS (Outpatient) - Response Summary
WHO : Tom Burgan
WHEN: 1/3/2020
WHY : Report survey response summary for patient experience dashboard
-----------------------------------------------------------------------------------------------------------------------
INFO: 
      INPUTS:	DS_HSDW_Prod.dbo.Fact_PressGaney_Responses
				DS_HSDW_Prod.rptg.Balanced_Scorecard_Mapping
				DS_HSDW_Prod.dbo.Dim_PG_Question
				DS_HSDW_Prod.dbo.Fact_Pt_Acct
				DS_HSDW_Prod.dbo.Dim_Pt
				DS_HSDW_Prod.dbo.Dim_Physcn
				DS_HSDW_Prod.dbo.Dim_Date
				DS_HSDW_App.Rptg.[PG_Extnd_Attr]
                  
      OUTPUTS:  HCAHPS Survey Results
   
------------------------------------------------------------------------------------------------------------------------
MODS: 	1/3/2020 - Create stored procedure
***********************************************************************************************************************/

SET NOCOUNT ON

---------------------------------------------------
---Default date range is the first day of FY 19 (7/1/2018) to yesterday's date
DECLARE @currdate AS SMALLDATETIME;
--DECLARE @startdate AS DATE;
--DECLARE @enddate AS DATE;

    SET @currdate=CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME);

    IF @StartDate IS NULL
        AND @EndDate IS NULL
        BEGIN
            SET @StartDate = CAST(CAST('7/1/2018' AS DATE) AS SMALLDATETIME);
            SET @EndDate= CAST(DATEADD(DAY, -1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME); 
        END; 

----------------------------------------------------
DECLARE @locstartdate SMALLDATETIME,
        @locenddate SMALLDATETIME

SET @locstartdate = @startdate
SET @locenddate   = @enddate

DECLARE @tab_servLine TABLE
(
    Service_Line VARCHAR(50)
);
INSERT INTO @tab_servLine
SELECT Param
FROM DS_HSDW_Prod.ETL.fn_ParmParse(@in_servLine, ',');

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
AND RECDATE BETWEEN @StartDate AND @EndDate

----------------------------------------------------------------------------------------------------

SELECT DISTINCT
	  clinictemp.SURVEY_ID
	 ,clinictemp.sk_Fact_Pt_Acct
	 ,clinictemp.RECDATE
	 ,clinictemp.DISDATE
	 ,clinictemp.REC_FY
	 ,clinictemp.quarter_name
	 ,clinictemp.month_short_name
	 ,clinictemp.month_num
	 ,clinictemp.year_num
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
	    ,ddte.quarter_name
	    ,ddte.month_short_name
	    ,ddte.month_num
	    ,ddte.year_num
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

  -- Create indexes for temp table #surveys_op
  CREATE NONCLUSTERED INDEX IX_surveysop ON #surveys_op (REC_FY, SERVICE_LINE_ID, EPIC_DEPARTMENT_ID, Domain_Goals, sk_Dim_PG_Question)

--  SELECT *
--  FROM #surveys_op
--ORDER BY REC_FY
--	   , year_num
--       , month_num
--	   , month_short_name
--	   , SERVICE_LINE
--	   , CLINIC
--	   , EPIC_DEPARTMENT_ID
--	   , epic_department_name
--	   , Domain_Goals
--	   , QUESTION_TEXT_ALIAS

------------------------------------------------------------------------------------------
-- JOIN TO DIM_DATE

 SELECT DISTINCT
	'CGCAHPS' AS Event_Type
	,surveys_op.REC_FY AS Event_FY
	,sk_Dim_PG_Question
	,QUESTION_TEXT_ALIAS
	,EPIC_DEPARTMENT_ID
	,epic_department_name
	,SERVICE_LINE_ID
	,SERVICE_LINE
	,sub_service_line
	,CLINIC
	,DOMAIN
	,Domain_Goals
	,quarter_name
	,month_short_name
	,month_num
	,year_num
INTO #surveys_op2
FROM #surveys_op surveys_op
WHERE surveys_op.REC_FY >= 2019
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

--SELECT *
--FROM #surveys_op2
--ORDER BY Event_FY
--	   , year_num
--       , month_num
--	   , month_short_name
--	   , SERVICE_LINE
--	   , EPIC_DEPARTMENT_ID
--	   , epic_department_name
--	   , Domain_Goals
--	   , QUESTION_TEXT_ALIAS

SELECT Event_Type,
       Event_FY,
	   year_num AS Event_CY,
       month_num AS [Month],
       month_short_name AS Month_Name,
       SERVICE_LINE,
       EPIC_DEPARTMENT_ID,
       epic_department_name,
       Domain_Goals,
	   sk_Dim_PG_Question,
       QUESTION_TEXT_ALIAS
FROM #surveys_op2
WHERE (Service_Line IN (SELECT Service_Line FROM @tab_servLine))
ORDER BY Event_Type
       , Event_FY
	   , year_num
       , month_num
	   , month_short_name
	   , SERVICE_LINE
	   , EPIC_DEPARTMENT_ID
	   , epic_department_name
	   , Domain_Goals
	   , QUESTION_TEXT_ALIAS

--SELECT DISTINCT
--       EPIC_DEPARTMENT_ID AS DEPARTMENT_ID,
--       epic_department_name AS DEPARTMENT_NAME,
--	   SERVICE_LINE AS Service_Line
--FROM #surveys_op2
--ORDER BY SERVICE_LINE
--	   , epic_department_name

GO


