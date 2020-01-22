USE [DS_HSDM_App_Dev]
GO

-- ===========================================
-- Create table Rptg.CGCAHPS_Goals
-- ===========================================
IF EXISTS (SELECT TABLE_NAME 
	       FROM   INFORMATION_SCHEMA.TABLES
	       WHERE  TABLE_SCHEMA = N'Rptg' AND
	              TABLE_NAME = N'CGCAHPS_Goals')
   DROP TABLE [Rptg].[CGCAHPS_Goals]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Rptg].[CGCAHPS_Goals](
	[SVC_CDE] [VARCHAR](2) NULL,
	[GOAL_FISCAL_YR] [INT] NULL,
	[SERVICE_LINE] [VARCHAR](150) NULL,
	[UNIT] [VARCHAR](150) NULL,
	[EPIC_DEPARTMENT_ID] [VARCHAR](255) NULL,
	[EPIC_DEPARTMENT_NAME] [VARCHAR](255) NULL,
	[DOMAIN] [VARCHAR](150) NULL,
	[GOAL] [DECIMAL](4, 3) NULL,
	[Load_Dtm] [SMALLDATETIME] NULL
) ON [PRIMARY]
GO

GRANT DELETE, INSERT, SELECT, UPDATE ON [Rptg].[CGCAHPS_Goals] TO [HSCDOM\Decision Support]
GO

