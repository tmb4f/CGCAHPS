USE DS_HSDW_App

SELECT DISTINCT
       resp.[Svc_Cde]
	  ,attr.DOMAIN
      ,quest.VARNAME
	  ,quest.QUESTION_TEXT
	  ,attr.QUESTION_TEXT_ALIAS
  FROM [DS_HSDW_Prod].[Rptg].[vwFact_PressGaney_Responses] resp
  LEFT OUTER JOIN [DS_HSDW_Prod].Rptg.vwDim_PG_Question quest
  ON quest.sk_Dim_PG_Question = resp.sk_Dim_PG_Question
  LEFT OUTER JOIN Rptg.PG_Extnd_Attr attr
  ON attr.sk_Dim_PG_Question = resp.sk_Dim_PG_Question
  WHERE (
resp.sk_Dim_PG_Question IN
--
-- CGCAHPS
--
(
	'784','707','711','715','719','721','729','731','754','776','788','790','795','797','799',
	'801','803','805','807','809','851','853','904','905','924','928','1256','1257','1259','725',
	'735','737','739','750','752','754','756','758','743','913','919','915','916','766','768','770','772','780','782','778'
)
OR
resp.sk_Dim_PG_Question IN
--
-- CHCAHPS
--
	(
		'2092', -- AGE
		'2129', -- CH_33
		'2130', -- CH_34
		'2151', -- CH_48
		'2204', -- G10
		'2205', -- G33
		'2208', -- G9
		'2212', -- I35
		'2213', -- I4
		'2214', -- I49
		'2215', -- I4PR
		'2217', -- I50
		'2326', -- M2
		'2327', -- M2PR
		'2330', -- M8
		'2345', -- O2
		'2184', -- CH_8CL
		'2186', -- CH_9CL
		'2096', -- CH_10CL
		'2098', -- CH_11CL
		'2100', -- CH_12CL
		'2102', -- CH_13CL
		'2103', -- CH_14
		'2104', -- CH_15
		'2105', -- CH_16
		'2106', -- CH_17
		'2107', -- CH_18
		'2108', -- CH_19
		'2110', -- CH_20
		'2112', -- CH_22
		'2113', -- CH_23
		'2116', -- CH_25CL
		'2119', -- CH_27CL
		'2122', -- CH_29CL
		'2129', -- CH_33
		'2130', -- CH_34
		'2146', -- CH_45CL
		'2152', -- CH_49
		'2153', -- CH_4CL
		'2167', -- CH_5CL
		'2180', -- CH_6CL
		'2111', -- CH_21
		'2125', -- CH_30
		'2128', -- CH_32CL
		'2131', -- CH_35
		'2132', -- CH_36
		'2133', -- CH_37
		'2136', -- CH_39CL
		'2140', -- CH_40CL
		'2141', -- CH_41
		'2142', -- CH_42
		'2143', -- CH_43
		'2148', -- CH_46CL
		'2150', -- CH_47CL
		--'2134', -- CH_38	3/6/2019 TMB Exclude responses for questiom "Provider tell child take new meds"
		'2384'  -- UNIT
	)
OR
resp.sk_Dim_PG_Question IN
--
-- ED
--
	(
		'323','324','326','327','328','329','330','332','378','379','380','382','383','384','385','388',
		'389','396','397','398','399','400','401','429','431','433','434','435','436','437','440','441',
		'442','446','449','450','1212','1213','1214'
	)
OR
resp.sk_Dim_PG_Question IN
--
-- HCAHPS
--
	(
		'1','2','4','5','6','7','11','14','16','17','18','24','27','28','29',
		'30','32','33','34','37','38','84','85','86','87','87','88','89',
		'90','92','93','99','101','105','106','108','110','112','113','126','127',
		'130','136','288','482','519','521','526','1238','2412','2414'
	)
)
AND attr.QUESTION_TEXT_ALIAS IS NOT NULL
  ORDER BY resp.Svc_Cde
         , attr.DOMAIN
