USE DS_HSDW_Prod

DECLARE @domain_translation TABLE
(
    Goals_Domain VARCHAR(100)
  , DOMAIN VARCHAR(100)
);
INSERT INTO @domain_translation
(
    Goals_Domain,
    DOMAIN
)
VALUES
(	'Overall Doctor Rating', -- Goals_Domain - varchar(100): Value docmented in Goals file
	'Overall Doctor Rating 0-10'  -- DOMAIN - varchar(100)
),
(	'Physician Comm',
	'Physician Communication Quality'
),
(	'Recommend This Office',
	'Recommend Provider'
);	
DECLARE @unit_translation TABLE
(
    Goals_Unit NVARCHAR(500) NULL
  , Unit NVARCHAR(500)
);
INSERT INTO @unit_translation
(
    Goals_Unit,
    Unit
)
VALUES
(   NULL, -- Goals_Unit - nvarchar(500): Value documented in Goals file
    'All Clinics'  -- Unit - nvarchar(500)
),
(   'All Units',
    'All Clinics'
);
DECLARE @serviceline_translation TABLE
(
    Goals_ServiceLine NVARCHAR(500) NULL
  , ServiceLine NVARCHAR(500)
);
INSERT INTO @serviceline_translation
(
    Goals_ServiceLine,
    ServiceLine
)
VALUES
(   'All Service Lines - MC Owned', -- Goals_ServiceLine - nvarchar(500): Value documented in Goals file
    'All Service Lines'  -- ServiceLine - nvarchar(500)
),
(   'Neuro', -- Goals_ServiceLine - nvarchar(500): Value documented in Goals file
    'Neurosciences and Behavioral Health'  -- ServiceLine - nvarchar(500)
),
(   'Women''s and Children''s', -- Goals_ServiceLine - nvarchar(500): Value documented in Goals file
    'Womens and Childrens'  -- ServiceLine - nvarchar(500)
);
DECLARE @CGCAHPS_PX_Goal_Setting TABLE
(
    GOAL_YR INTEGER
  , SERVICE_LINE VARCHAR(150)
  , ServiceLine_Goals VARCHAR(150)
  , Epic_Department_Id VARCHAR(8)
  , Epic_Department_Name VARCHAR(30)
  , UNIT VARCHAR(150)
  , Unit_Goals VARCHAR(150)
  , DOMAIN VARCHAR(150)
  , Domain_Goals VARCHAR(150)
  , GOAL DECIMAL(4,3)
);
INSERT INTO @CGCAHPS_PX_Goal_Setting
SELECT
	[GOAL_YR]
	,Goal.SERVICE_LINE
	,COALESCE([@serviceline_translation].ServiceLine, Goal.SERVICE_LINE) AS ServiceLine_Goals
	,NULL AS Epic_Department_Id
	,NULL AS Epic_Department_Name
    ,Goal.[UNIT]
    ,COALESCE([@unit_translation].Unit, Goal.UNIT) AS Unit_Goals
    ,Goal.[DOMAIN]
    ,COALESCE([@domain_translation].DOMAIN, Goal.DOMAIN) AS Domain_Goals
    ,Goal.[GOAL]
FROM [DS_HSDW_App].[Rptg].[PX_Goal_Setting] Goal
LEFT OUTER JOIN @domain_translation
    ON [@domain_translation].Goals_Domain = Goal.DOMAIN
LEFT OUTER JOIN @unit_translation
    ON (COALESCE([@unit_translation].Goals_Unit,'NULL') = COALESCE(Goal.UNIT,'NULL'))
LEFT OUTER JOIN @serviceline_translation
    ON [@serviceline_translation].Goals_ServiceLine = Goal.SERVICE_LINE
WHERE Goal.Service = 'CGCAHPS'
AND (Goal.SERVICE_LINE NOT IN ('All Service Lines - All Sites','MC/UPG','NRDG Community Med','Radiology','UPG - Non MC'));

--SELECT *
--FROM @CGCAHPS_PX_Goal_Setting
--ORDER BY SERVICE_LINE
--       , UNIT
--	   , DOMAIN

DECLARE @CGCAHPS_PX_Goal_Setting_epic_id TABLE
(
    GOAL_YR INTEGER
  , SERVICE_LINE VARCHAR(150)
  , ServiceLine_Goals VARCHAR(150)
  , UNIT VARCHAR(150)
  , Unit_Goals VARCHAR(150)
  , DOMAIN VARCHAR(150)
  , Domain_Goals VARCHAR(150)
  , GOAL DECIMAL(4,3)
  , [Epic DEPARTMENT_ID] VARCHAR(50)
  , INDEX IX_CGCAHPS_PX_Goal_Setting_epic_id NONCLUSTERED(GOAL_YR, UNIT, Domain_Goals)
);
INSERT INTO @CGCAHPS_PX_Goal_Setting_epic_id
SELECT
     goals.GOAL_YR
    ,goals.SERVICE_LINE
	,goals.ServiceLine_Goals
    ,goals.UNIT
    ,goals.Unit_Goals
    ,goals.DOMAIN
    ,goals.Domain_Goals
    ,goals.GOAL
	,goals.Epic_Department_Id AS [Epic DEPARTMENT_ID]
FROM @CGCAHPS_PX_Goal_Setting goals
ORDER BY goals.GOAL_YR, goals.UNIT, goals.Domain_Goals;

--SELECT *
--FROM @CGCAHPS_PX_Goal_Setting_epic_id

DECLARE @RptgTbl TABLE
(
    SVC_CDE CHAR(2)
  , GOAL_YR INTEGER
  , SERVICE_LINE VARCHAR(150)
  , UNIT VARCHAR(150)
  , DOMAIN VARCHAR(150)
  , GOAL DECIMAL(4,3)
  , Load_Dtm SMALLDATETIME
);

INSERT INTO @RptgTbl
(
    SVC_CDE,
    GOAL_YR,
    SERVICE_LINE,
    UNIT,
    DOMAIN,
    GOAL,
    Load_Dtm
)
SELECT all_goals.SVC_CDE
     , all_goals.GOAL_YR
	 , all_goals.SERVICE_LINE
	 , all_goals.UNIT
	 , all_goals.DOMAIN
	 , all_goals.GOAL
	 , all_goals.Load_Dtm
FROM
(
-- 2020
SELECT DISTINCT
    'MD' AS SVC_CDE
  , CAST(2020 AS INT) AS GOAL_YR
  , CAST(goals.ServiceLine_Goals AS VARCHAR(150)) AS SERVICE_LINE
  , CAST(goals.Unit_Goals AS VARCHAR(150)) AS UNIT
  , CAST(goals.Domain_Goals AS VARCHAR(150)) AS DOMAIN
  , CAST(goals.GOAL AS DECIMAL(4,3)) AS GOAL
  , CAST(GETDATE() AS SMALLDATETIME) AS Load_Dtm
FROM @CGCAHPS_PX_Goal_Setting_epic_id goals
WHERE goals.GOAL_YR = 2020
AND ((goals.Unit_Goals IS NOT NULL) AND (goals.Unit_Goals <> 'All Service Lines'))
AND goals.DOMAIN IS NOT NULL
AND goals.GOAL IS NOT NULL
UNION ALL
SELECT DISTINCT
    'MD' AS SVC_CDE
  , CAST(2020 AS INT) AS GOAL_YR
  , CAST('Womens and Childrens - Children' AS VARCHAR(150)) AS SERVICE_LINE
  , CAST(goals.Unit_Goals AS VARCHAR(150)) AS UNIT
  , CAST(goals.Domain_Goals AS VARCHAR(150)) AS DOMAIN
  , CAST(goals.GOAL AS DECIMAL(4,3)) AS GOAL
  , CAST(GETDATE() AS SMALLDATETIME) AS Load_Dtm
FROM @CGCAHPS_PX_Goal_Setting_epic_id goals
WHERE goals.GOAL_YR = 2020
AND ((goals.ServiceLine_Goals IS NOT NULL) AND (goals.ServiceLine_Goals = 'Womens and Childrens'))
AND ((goals.Unit_Goals IS NOT NULL) AND (goals.Unit_Goals <> 'All Service Lines'))
AND goals.DOMAIN IS NOT NULL
AND goals.GOAL IS NOT NULL
UNION ALL
SELECT DISTINCT
    'MD' AS SVC_CDE
  , CAST(2020 AS INT) AS GOAL_YR
  , CAST('Womens and Childrens - Women' AS VARCHAR(150)) AS SERVICE_LINE
  , CAST(goals.Unit_Goals AS VARCHAR(150)) AS UNIT
  , CAST(goals.Domain_Goals AS VARCHAR(150)) AS DOMAIN
  , CAST(goals.GOAL AS DECIMAL(4,3)) AS GOAL
  , CAST(GETDATE() AS SMALLDATETIME) AS Load_Dtm
FROM @CGCAHPS_PX_Goal_Setting_epic_id goals
WHERE goals.GOAL_YR = 2020
AND ((goals.ServiceLine_Goals IS NOT NULL) AND (goals.ServiceLine_Goals = 'Womens and Childrens'))
AND ((goals.Unit_Goals IS NOT NULL) AND (goals.Unit_Goals <> 'All Service Lines'))
AND goals.DOMAIN IS NOT NULL
AND goals.GOAL IS NOT NULL
UNION ALL
SELECT DISTINCT
    'MD' AS SVC_CDE
  , CAST(2020 AS INT) AS GOAL_YR
  , CAST(goals.ServiceLine_Goals AS VARCHAR(150)) AS SERVICE_LINE
  , CAST(goals.Unit_Goals AS VARCHAR(150)) AS UNIT
  , CAST(goals.Domain_Goals AS VARCHAR(150)) AS DOMAIN
  , CAST(goals.GOAL AS DECIMAL(4,3)) AS GOAL
  , CAST(GETDATE() AS SMALLDATETIME) AS Load_Dtm
FROM @CGCAHPS_PX_Goal_Setting_epic_id goals
WHERE goals.GOAL_YR = 2020
AND ((goals.Unit_Goals IS NOT NULL) AND (goals.Unit_Goals = 'All Service Lines'))
AND goals.DOMAIN IS NOT NULL
AND goals.GOAL IS NOT NULL
) all_goals;

SELECT *
FROM @RptgTbl
ORDER BY GOAL_YR
       , SERVICE_LINE
       , UNIT
	   , DOMAIN

--SELECT DISTINCT
--	GOAL_YR
--  , UNIT
--FROM @RptgTbl
--ORDER BY GOAL_YR
--       , UNIT
