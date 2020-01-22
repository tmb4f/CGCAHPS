USE [DS_HSDW_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

DECLARE @StartDate DATE
       ,@EndDate DATE

--SET @StartDate = NULL
--SET @EndDate = NULL
SET @StartDate = '7/1/2018'
--SET @EndDate = '12/29/2019'
--SET @StartDate = '7/1/2019'
SET @EndDate = '1/5/2020'

DECLARE @in_servLine VARCHAR(MAX),
        @in_deps VARCHAR(MAX)

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

DECLARE @Department TABLE (DepartmentId NUMERIC(18,0))

INSERT INTO @Department
(
    DepartmentId
)
VALUES
--(10243114), -- UVHE ALLERGY DHC,Digestive Health
--(10243003), -- UVHE DIGESTIVE HEALTH,Digestive Health
--(10243087), -- UVHE SURG DIGESTIVE HL,Digestive Health
--(10242051), -- UVPC DIGESTIVE HEALTH,Digestive Health
--(10212016), -- F500 CARDIOLOGY,Heart and Vascular
--(10212019), -- F500 ENDOCRINOLOGY,Heart and Vascular
--(10243112), -- UVHE CARDIAC SURGERY,Heart and Vascular
--(10243097), -- UVHE MED CARD CL,Heart and Vascular
--(10243104), -- UVHE VASC SURG,Heart and Vascular
--(10242049), -- UVPC CARDIAC SURGERY,Heart and Vascular
--(10242008), -- UVPC CARDIOLOGY,Heart and Vascular
--(10211002), -- F415 DIABETES ED & MGT,Medical Subspecialties
--(10211006), -- F415 ENDOCRINE,Medical Subspecialties
--(10211013), -- F415 MED PITUITARY,Medical Subspecialties
--(10211003), -- F415 RHEUMATOLOGY,Medical Subspecialties
--(10228007), -- NRDG ALLERGY,Medical Subspecialties
--(10239003), -- UVMS NEPHROLOGY,Medical Subspecialties
--(10242005), -- UVPC DERMATOLOGY,Medical Subspecialties
--(10242018), -- UVPC PULMONARY,Medical Subspecialties
--(10244028), -- UVWC GASTRO ID,Medical Subspecialties
--(10244016), -- UVWC INFECTIOUS DIS,Medical Subspecialties
--(10244029), -- UVWC OBGYN ID,Medical Subspecialties
--(10211009), -- F415 ORTHO HAND CENTER,Musculoskeletal
--(10214002), -- F545 ORTHOPAEDICS FL 1,Musculoskeletal
--(10214013), -- F545 ORTHOPAEDICS FL 3,Musculoskeletal
--(10214001), -- F545 PAIN MANAGEMENT,Musculoskeletal
--(10214003), -- F545 PHYSICAL MED&RHB,Musculoskeletal
--(10214011), -- F545 SPORTS MED FL 1,Musculoskeletal
--(10214014), -- F545 SPORTS MED FL 3,Musculoskeletal
--(10211021), -- F415 NEUROSURGERY,Neurosciences and Behavioral Health
--(10211010), -- F415 NSRG SPINE CTR,Neurosciences and Behavioral Health
--(10211018), -- F415 ORTHO SPINE CTR,Neurosciences and Behavioral Health
--(10211019), -- F415 PMR SPINE CTR,Neurosciences and Behavioral Health
--(10250001), -- UVBR NEUROSURGERY,Neurosciences and Behavioral Health
--(10242039), -- UVPC NEUR PSY NEUR CL,Neurosciences and Behavioral Health
--(10242007), -- UVPC NEUROLOGY,Neurosciences and Behavioral Health
--(10242031), -- UVPC NEUROPSYCH,Neurosciences and Behavioral Health
--(10242044), -- UVPC NEUROSURGERY,Neurosciences and Behavioral Health
--(10280005), -- AUBL UVA CANC CTR AUG,Oncology
--(10306004), -- CVPJ PLASTIC SURGERY,Oncology
--(10306001), -- CVPJ UVA CANC CTR PTP,Oncology
--(10210042), -- ECCC DERMATOLOGY WEST,Oncology
--(10210055), -- ECCC ENDOCRINE EAST,Oncology
--(10210035), -- ECCC GYN ONC WOMENS,Oncology
--(10210001), -- ECCC HEM ONC EAST,Oncology
--(10210002), -- ECCC HEM ONC WEST,Oncology
--(10210014), -- ECCC HEM ONC WOMENS,Oncology
--(10210028), -- ECCC MED DHC EAST CL,Oncology
--(10210054), -- ECCC NEPHROLOGY WEST,Oncology
--(10210030), -- ECCC NEURO WEST,Oncology
--(10210032), -- ECCC NSURG WEST,Oncology
--(10210026), -- ECCC OTO CL EAST,Oncology
--(10210038), -- ECCC PAIN MANAGEMENT,Oncology
--(10210006), -- ECCC PALLIATIVE CLINIC,Oncology
--(10210057), -- ECCC PHYSMED&REHB WMS,Oncology
--(10210013), -- ECCC RAD ONC CLINIC,Oncology
--(10210016), -- ECCC SUPPORT SVCS 1FL,Oncology
--(10210058), -- ECCC SUPPORT SVCS EAST,Oncology
--(10210022), -- ECCC SURG ONC EAST,Oncology
--(10210029), -- ECCC SURG ONC WEST,Oncology
--(10210052), -- ECCC UROLOGY WEST,Oncology
--(10227002), -- MOSR RAD ONC CLINIC,Oncology
--(10239004), -- UVMS BREAST,Oncology
--(10228026), -- NRDG OPHTHALMOLOGY FL2,Ophthalmology
--(10228002), -- NRDG OPHTHALMOLOGY FL3,Ophthalmology
--(10244004), -- UVWC OPHTHALMOLOGY,Ophthalmology
--(10280004), -- AUBL PEDIATRICS,Other
--(10280016), -- AUBL PEDS DEVELOPMENT,Other
--(10280009), -- AUBL URO PEDS,Other
--(10280010), -- AUBL UVA PEDS RESP,Other
--(10280001), -- AUBL UVA SPTY CARE,Other
--(10280015), -- AUBL VASCULAR SURGERY,Other
--(10204015), -- AUMC PLASTIC SURGERY,Other
--(10353003), -- AUPN SP CARE ENDO,Other
--(10353001), -- AUPN SP CARE NEPH,Other
--(10353004), -- AUPN SP CARE PULM,Other
--(10353005), -- AUPN SP CARE RHEU,Other
--(10353006), -- AUPN SP CARE URO,Other
--(10271002), -- BRLH NEUROLOGY,Other
--(10271001), -- BRLH PEDS DEVELOPMENT,Other
--(10271004), -- BRLH PEDS GENETICS,Other
--(10390001), -- CPBE COMMONWEALTH MED,Other
--(10275003), -- CPBR ALLERGY,Other
--(10275001), -- CPBR FAMILY CARE,Other
--(10275002), -- CPBR PEDIATRICS,Other
--(10275006), -- CPBR PEDS CARDIOLOGY,Other
--(10275005), -- CPBR PEDS UROLOGY,Other
--(10257004), -- CPNM ENDOCRINE,Other
--(10257001), -- CPNM MADISON PRIMARY C,Other
--(10369009), -- CPSA CARDIAC SURGERY,Other
--(10369001), -- CPSA CARDIOLOGY,Other
--(10369012), -- CPSA VASCULAR SURGERY,Other
--(10295005), -- CPSE CH CANC CTR,Other
--(10295008), -- CPSE RAD ONC CL,Other
--(10293024), -- CPSN UVA OBGYN,Other
--(10293031), -- CPSN UVA ORTHO SPINE,Other
--(10293029), -- CPSN UVA ORTHOPEDICS,Other
--(10293030), -- CPSN UVA PEDS ORTHO,Other
--(10293026), -- CPSN UVA SURG BREAST,Other
--(10293025), -- CPSN UVA SURGICAL SVCS,Other
--(10293027), -- CPSN UVA UROLOGY,Other
--(10293032), -- CPSN UVA VASCULAR SURG,Other
--(10276004), -- CPSS PEDIATRICS,Other
--(10276008), -- CPSS UVA OBGYN,Other
--(10274001), -- CPST FAMILY PRACTICE,Other
--(10365001), -- CVJS PLASTIC SURG CL,Other
--(10341001), -- CVPE UVA RHEU PANTOPS,Other
--(10339001), -- CVPM MED WESTMINSTER,Other
--(10338001), -- CVPP OTOLARYNGOLOGY,Other
--(10363002), -- CVSL PAIN MANAGEMENT,Other
--(10387005), -- CVSM OBGYN CL,Other
--(10387006), -- CVSM PEDS DEVELOPMENT,Other
--(10387001), -- CVSM PRIMARY CARE,Other
--(10399001), -- CVSN ENDOCRINE,Other
--(10299002), -- CVSR ENDOCRINE,Other
--(10391001), -- FOVP NEUROSURGERY,Other
--(10395002), -- GAJM RAD CL & VEIN CL,Other
--(10216006), -- HBMA BEH MED,Other
--(10216005), -- HBMA PEDIATRICS,Other
--(10376004), -- HYHB NEUROSURGERY,Other
--(10267002), -- LBRA PEDS ALLERGY,Other
--(10267003), -- LBRA PEDS GENETIC,Other
--(10267001), -- LBRA PEDS PULMONARY,Other
--(10277002), -- LGGH RPC OBGYN CL,Other
--(10277001), -- LGGH WILDERNESS MEDCTR,Other
--(10220001), -- LOID MEDICAL ASSOC,Other
--(10265002), -- LWDS VASCULAR SURGERY,Other
--(10404001), -- MGST PEDIATRICS,Other
--(10228012), -- NRDG COMMUNITY MED,Other
--(10228021), -- NRDG RAD CL & VEIN CL,Other
--(10377001), -- PAMS PRIMARY CARE,Other
--(10361004), -- RMBR PEDS GENETICS CL,Other
--(10361001), -- RMBR UVA PCARD CL,Other
--(10374002), -- ROFR SURG TRANSPLANT,Other
--(10260002), -- RONK PEDS RESP MED,Other
--(10260003), -- RONK UROLOGY PEDS,Other
--(10236001), -- SDGR FAMILY MEDICINE,Other
--(10261001), -- TZCD NEUROLOGY,Other
--(10403001), -- WARA PRIMARY CARE,Other
--(10245001), -- WAYB PRIMARY CARE,Other
--(10396007), -- WCCC PEDS CARDIOLOGY,Other
--(10396006), -- WCCC PEDS ENDOCRINE CL,Other
--(10396003), -- WCCC PEDS GASTRO CL,Other
--(10396010), -- WCCC PEDS GENETICS CL,Other
--(10396012), -- WCCC PEDS HEM ONC,Other
--(10396004), -- WCCC UROLOGY PEDS CL,Other
--(10355001), -- WCPD UVA PED CARD CL,Other
--(10256001), -- WSRS NEUROLOGY,Other
--(10340001), -- WVSS PEDS RESP MED,Other
--(10348039), -- ZCSC ALLERGY,Other
--(10348024), -- ZCSC BREAST,Other
--(10348003), -- ZCSC CARDIOLOGY,Other
--(10348004), -- ZCSC DERMATOLOGY,Other
--(10348005), -- ZCSC ENDOCRINE,Other
--(10348007), -- ZCSC NEPHROLOGY,Other
--(10348008), -- ZCSC NEUROLOGY,Other
--(10348026), -- ZCSC OBGYN,Other
--(10348032), -- ZCSC OBGYN URO,Other
--(10348023), -- ZCSC ORTHO SPINE FL 1,Other
--(10348022), -- ZCSC ORTHO SPORTS MED,Other
--(10348013), -- ZCSC ORTHOPEDICS FL 1,Other
--(10348036), -- ZCSC ORTHOPEDICS FL 2,Other
--(10348027), -- ZCSC PEDS ORTHO,Other
--(10348010), -- ZCSC PHYSICAL MED REH,Other
--(10348014), -- ZCSC PRIMARY CARE,Other
--(10348011), -- ZCSC PULMONARY,Other
--(10348015), -- ZCSC UROLOGY,Other
--(10205001), -- COL COLONNADES MED ASC,Primary Care
--(10341009), -- CVPE MED NEPHROLOGY,Primary Care
--(10341004), -- CVPE PMR,Primary Care
--(10341007), -- CVPE PRIMARY CARE CL,Primary Care
--(10211004), -- F415 UNIV PHYS,Primary Care
--(10248001), -- JABA JEFFERSON ABA,Primary Care
--(10217003), -- JPA UNIV MED ASSOCS,Primary Care
--(10208001), -- NGCR FAMILY MEDICINE,Primary Care
--(10234001), -- NLSC FAMILY MEDICINE,Primary Care
--(10230009), -- ORUL MED CARD,Primary Care
--(10230006), -- ORUL MED GEN DEMP,Primary Care
--(10230005), -- ORUL MED NEPHROLOGY,Primary Care
--(10230004), -- ORUL UNIV PHYSICIANS,Primary Care
--(10242012), -- UVPC FAMILY MEDICINE,Primary Care
--(10246005), -- WALL ENDO MED FAMILY,Primary Care
--(10246001), -- WALL FAMILY MEDICINE,Primary Care
--(10246004), -- WALL MED DH FAM MED,Primary Care
--(10246007), -- WALL PEDIATRICS,Primary Care
--(10211005), -- F415 OTOLARYNGOLOGY,Surgical Subspecialties
--(10212018), -- F500 CONT PELVIC SGY,Surgical Subspecialties
--(10212017), -- F500 UROLOGY,Surgical Subspecialties
--(10217004), -- JPA DENTISTRY,Surgical Subspecialties
--(10354026), -- UVBB PEDS AUDIO,Surgical Subspecialties
--(10240003), -- UVBR ORAL SURGERY,Surgical Subspecialties
--(10241001), -- UVDV PLASTIC SURGERY,Surgical Subspecialties
--(10239015), -- UVMS SURGERY,Surgical Subspecialties
--(10244023), -- UVWC MED GI CL,Surgical Subspecialties
--(10244006), -- UVWC UROLOGY,Surgical Subspecialties
--(10337001), -- CVAB PMR WORKMED,Therapies
--(10217001), -- JPA EMPLOYEE SAME DAY,Therapies
--(10239026), -- UVMS ENDO TRANSPLANT,Transplant
--(10239024), -- UVMS ID TRANSPLANT,Transplant
--(10239020), -- UVMS SURG TRANSPLANT,Transplant
--(10239019), -- UVMS TRANSPLANT KIDNEY,Transplant
--(10239017), -- UVMS TRANSPLANT LIVER,Transplant
--(10239018), -- UVMS TRANSPLANT LUNG,Transplant
--(10228003), -- NRDG MIDLIFE,Womens and Childrens
--(10228011), -- NRDG PEDIATRICS,Womens and Childrens
--(10228001), -- NRDG UNIV PHYS WOMEN,Womens and Childrens
--(10230002), -- ORUL PEDIATRICS,Womens and Childrens
--(10354080), -- UVBB CARDIAC SURGERY,Womens and Childrens
--(10354012), -- UVBB DEV PEDS CL FL 4,Womens and Childrens
--(10354044), -- UVBB DEV PEDS CL FL 5,Womens and Childrens
--(10354049), -- UVBB DEV PEDS CL FL 6,Womens and Childrens
--(10354088), -- UVBB GEN PEDIATRIC FL4,Womens and Childrens
--(10354019), -- UVBB GEN PEDIATRIC FL6,Womens and Childrens
--(10354035), -- UVBB MATERNAL FETAL CL,Womens and Childrens
--(10354047), -- UVBB MED CARD CONGEN,Womens and Childrens
--(10354037), -- UVBB NEUROLOGY PED FL5,Womens and Childrens
--(10354034), -- UVBB NEUROSURG PEDS CL,Womens and Childrens
--(10354040), -- UVBB OBGYN FETAL CARE,Womens and Childrens
--(10354028), -- UVBB ORTHO PEDS CL,Womens and Childrens
--(10354036), -- UVBB OTOL PEDS CL,Womens and Childrens
--(10354079), -- UVBB PEDS BEH MED,Womens and Childrens
--(10354018), -- UVBB PEDS CARD CL FL 6,Womens and Childrens
--(10354008), -- UVBB PEDS DENTISTRY,Womens and Childrens
--(10354043), -- UVBB PEDS DIABETES CL,Womens and Childrens
--(10354021), -- UVBB PEDS ENDOCRINE F6,Womens and Childrens
--(10354014), -- UVBB PEDS GASTRO CL,Womens and Childrens
--(10354017), -- UVBB PEDS GENETICS CL,Womens and Childrens
--(10354084), -- UVBB PEDS HEM ONC,Womens and Childrens
--(10354023), -- UVBB PEDS ID CL,Womens and Childrens
--(10354039), -- UVBB PEDS NEONATE FL 5,Womens and Childrens
--(10354025), -- UVBB PEDS PULM FL6,Womens and Childrens
--(10354024), -- UVBB PEDS RENAL CL FL5,Womens and Childrens
--(10354013), -- UVBB PEDS RHEUM CL,Womens and Childrens
--(10354016), -- UVBB PEDS SURGERY CL,Womens and Childrens
--(10354055), -- UVBB PEDS TRANSPLANT,Womens and Childrens
--(10354054), -- UVBB PLASTIC SURG FL6,Womens and Childrens
--(10354051), -- UVBB PMR PEDS CL,Womens and Childrens
--(10354027), -- UVBB PSYCH PEDS CL,Womens and Childrens
--(10354005), -- UVBB TEEN YOUNG AD CTR,Womens and Childrens
--(10354029), -- UVBB UROLOGY PEDS FL 4,Womens and Childrens
--(10354076), -- UVBB UROLOGY PEDS FL 5,Womens and Childrens
--(10242006), -- UVPC OB-GYN,Womens and Childrens
--(10242041)  -- UVPC PEDS NEUROLOGY,Womens and Childrens
(10243114), -- UVHE ALLERGY DHC,Digestive Health
(10243003), -- UVHE DIGESTIVE HEALTH,Digestive Health
(10243087), -- UVHE SURG DIGESTIVE HL,Digestive Health
(10242051)  -- UVPC DIGESTIVE HEALTH,Digestive Health
;

SELECT @in_deps = COALESCE(@in_deps+',' ,'') + CAST(DepartmentId AS VARCHAR(MAX))
FROM @Department

--SELECT @in_deps

--CREATE PROCEDURE [Rptg].[uspSrc_Dash_PatExp_CGCAHPS_Response_Summary]
--    (
--     @StartDate SMALLDATETIME = NULL,
--     @EndDate SMALLDATETIME = NULL,
     --@in_servLine VARCHAR(MAX),
     --@in_deps VARCHAR(MAX)
--    )
--AS
/*******************************************************************************************
WHAT: Stored procedure for Patient Experience Dashboard - CGCAHPS (Outpatient) - Response Summary
WHO : Tom Burgan
WHEN: 1/2/2020
WHY : Report survey response summary for patient experience dashboard
--------------------------------------------------------------------------------------------
INFO: 
      INPUTS:	DS_HSDW_Prod.dbo.Fact_PressGaney_Responses
				DS_HSDW_Prod.rptg.Balanced_Scorecard_Mapping
				DS_HSDW_Prod.dbo.Dim_PG_Question
				DS_HSDW_Prod.dbo.Fact_Pt_Acct
				DS_HSDW_Prod.dbo.Dim_Pt
				DS_HSDW_Prod.dbo.Dim_Physcn
				DS_HSDW_Prod.dbo.Dim_Date
				DS_HSDW_App.Rptg.[PG_Extnd_Attr]
                  
      OUTPUTS:  CGCAHPS Survey Results
	
--------------------------------------------------------------------------------------------
MODS: 	1/2/2020 - Create stored procedure
*********************************************************************************************/
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

SET @locstartdate = @StartDate
SET @locenddate   = @EndDate

DECLARE @tab_servLine TABLE
(
    Service_Line VARCHAR(50)
);
INSERT INTO @tab_servLine
SELECT Param
FROM DS_HSDW_Prod.ETL.fn_ParmParse(@in_servLine, ',');
DECLARE @tab_deps TABLE
(
    epic_department_id NUMERIC(18,0)
);
INSERT INTO @tab_deps
SELECT Param
FROM DS_HSDW_Prod.ETL.fn_ParmParse(@in_deps, ',');

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
				SELECT DISTINCT sk_Dim_PG_Question, DOMAIN, REPLACE(REPLACE(QUESTION_TEXT_ALIAS, CHAR(13), ''), CHAR(10), '') AS QUESTION_TEXT_ALIAS FROM DS_HSDW_App.Rptg.PG_Extnd_Attr
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
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @StartDate AND day_date <= @EndDate) rec
LEFT OUTER JOIN #surveys_op
ON rec.day_date = #surveys_op.RECDATE
FULL OUTER JOIN
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date <= @EndDate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
ON dis.day_date = #surveys_op.DISDATE
LEFT OUTER JOIN
	(SELECT * FROM DS_HSDW_App.Rptg.CGCAHPS_Goals WHERE UNIT = 'All Clinics') goals -- CHANGE BASED ON GOALS FROM BUSH - CREATE NEW CGCAHPS_Goals
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
	(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date >= @StartDate AND day_date <= @EndDate) rec
	LEFT OUTER JOIN #surveys_op
	ON rec.day_date = #surveys_op.RECDATE
	FULL OUTER JOIN
		(SELECT * FROM DS_HSDW_Prod.dbo.Dim_Date WHERE day_date <= @EndDate) dis -- Need to report by both the discharge date on the survey as well as the received date of the survey
	ON dis.day_date = #surveys_op.DISDATE
	LEFT OUTER JOIN 
		(SELECT * FROM DS_HSDW_App.Rptg.CGCAHPS_Goals WHERE UNIT = 'All Clinics') goals
		ON #surveys_op.REC_FY = goals.GOAL_FISCAL_YR AND #surveys_op.Domain_Goals = goals.DOMAIN AND goals.SERVICE_LINE = #surveys_op.SERVICE_LINE
	WHERE (rec.day_date >= @StartDate AND rec.day_date <= @EndDate)

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
	   COUNT(DISTINCT resp.SURVEY_ID) AS SURVEY_ID_COUNT
INTO #surveys_op_sum
FROM
(
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
FROM #CGCAHPS_Clinics
WHERE Event_FY >= 2019
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

SELECT Event_Type,
       Event_FY,
	   year_num AS Event_CY,
       month_num AS [Month],
       month_short_name AS Month_Name,
       Service_Line,
       EPIC_DEPARTMENT_ID AS DEPARTMENT_ID,
       epic_department_name AS DEPARTMENT_NAME,
       CLINIC,
       Domain_Goals,
       QUESTION_TEXT_ALIAS,
       TOP_BOX,
       VAL_COUNT,
       SURVEY_ID_COUNT AS N,
       GOAL
FROM #surveys_op_sum
WHERE (Service_Line IN (SELECT Service_Line FROM @tab_servLine))
AND (epic_department_id IN (SELECT epic_department_id FROM @tab_deps))
ORDER BY Event_Type
       , Event_FY
	   , year_num
       , month_num
	   , month_short_name
	   , Service_Line
	   , EPIC_DEPARTMENT_ID
	   , epic_department_name
	   , CLINIC
	   , Domain_Goals
	   , QUESTION_TEXT_ALIAS

GO


