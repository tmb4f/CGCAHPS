USE DS_HSDW_App

IF OBJECT_ID('tempdb..#goal ') IS NOT NULL
DROP TABLE #goal

IF OBJECT_ID('tempdb..#cgcahps ') IS NOT NULL
DROP TABLE #cgcahps

SELECT [goal].[SERVICE_LINE]
	   ,ROW_NUMBER() OVER (ORDER BY goal.SERVICE_LINE) AS INDX
INTO #goal
  FROM
  (
  SELECT DISTINCT
	SERVICE_LINE
  FROM [DS_HSDW_App].[Rptg].[PX_Goal_Setting]
  WHERE Service = 'CGCAHPS'
  ) goal
  ORDER BY goal.SERVICE_LINE

SELECT DISTINCT
       cgcahps.SERVICE_LINE
	   ,ROW_NUMBER() OVER (ORDER BY cgcahps.SERVICE_LINE) AS INDX
INTO #cgcahps
  FROM
  (
  SELECT DISTINCT
	SERVICE_LINE
  FROM [DS_HSDW_App].[Rptg].[CGCAHPS_Goals]
  ) cgcahps
  ORDER BY cgcahps.SERVICE_LINE

  SELECT goal.SERVICE_LINE AS GOAL_SERVICE_LINE, cgcahps.SERVICE_LINE AS cgcahps_SERVICE_LINE
  FROM #goal goal
  --INNER JOIN #cgcahps cgcahps
  LEFT OUTER JOIN #cgcahps cgcahps
  ON cgcahps.INDX = goal.INDX
  ORDER BY goal.SERVICE_LINE

