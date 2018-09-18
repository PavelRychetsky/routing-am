create or replace PROCEDURE GET_RUT_PARAMS_AM_DISTRIB_V010 (
	inDEMAND_TYPE IN VARCHAR2,
  inCU_REF_NO IN VARCHAR2,
  inIDENTITY_NUMBER IN VARCHAR2,
  inSTAT_SRV IN VARCHAR2,
  outVALUE OUT NOCOPY VARCHAR2)
  
IS

	TYPE ParamsType IS TABLE OF VARCHAR2(128);
	params ParamsType := ParamsType('PRIORITY', 'PRIORITY_GROW_RATE', 'TARGET_WAIT', 'TARGET_SLA', 'SCHEDULER_WAIT', 'TARGET_OVER_WAIT',
      'PROTECT_EXPRESSION', 'PROTECT_AG_NAME', 'PROTECT_VQ_NAME', 'PROTECT_LEVEL', 'PROTECT_VOICE_VQ_SL60', 'PROTECT_VOICE_VQ_SL15',
      'PROTECT_VOICE_AG_WAIT', 'PROTECT_VOICE_AG_DEDIC', 'PROTECT_VOICE_AG_TIME_WAIT', 'PROTECT_VQG_NAME', 'PROTECT_VOICE_A_AVAILABLE',
      'GARANT_TYPE');
	i INTEGER;
	vTMP_PARAM1 VARCHAR2(128);
	vTMP_PARAM2 VARCHAR2(128);
	vTMP_PARAM_FINAL VARCHAR2(128);
  vGARANT_LOGIN VARCHAR2(50);
  vGARANT VARCHAR2(100);
  vMINITEAM_ID VARCHAR2(100);
  vTEAM_ID VARCHAR2(100);
  vMINITEAM VARCHAR2(4000);
  vTEAM VARCHAR2(4000);

BEGIN

	outVALUE := '';

	FOR i IN 1 .. params.count LOOP
		BEGIN
			SELECT RUT_PARAMS_VALUE into vTMP_PARAM1
			FROM AM_RUT_PARAMS
			WHERE RUT_PARAMS_NAME = 'ALL_@_' || params(i);
		EXCEPTION
			WHEN OTHERS THEN
				vTMP_PARAM1 := NULL;
		END;

		BEGIN
			SELECT RUT_PARAMS_VALUE into vTMP_PARAM2
			FROM AM_RUT_PARAMS
			WHERE RUT_PARAMS_NAME = inDEMAND_TYPE || '_*_' || params(i);
		EXCEPTION
			WHEN OTHERS THEN
				vTMP_PARAM2 := NULL;
		END;

  	vTMP_PARAM_FINAL := '';

		IF vTMP_PARAM1 IS NOT NULL THEN
			vTMP_PARAM_FINAL := vTMP_PARAM1;
		END IF;

		IF vTMP_PARAM2 IS NOT NULL THEN
			vTMP_PARAM_FINAL := vTMP_PARAM2;
		END IF;

		IF vTMP_PARAM_FINAL IS NULL THEN
			vTMP_PARAM_FINAL := '__UNDEF';
		END IF;

    IF params(i) = 'GARANT_TYPE' THEN
      BEGIN
        IF inCU_REF_NO is not null and vTMP_PARAM_FINAL != '__UNDEF' THEN
     	    BEGIN
            GENESYS.GET_GARANT_LOGIN@TO_CTI4(inCU_REF_NO, vTMP_PARAM_FINAL, vGARANT_LOGIN); -- E2E × MAINTEST = CTI4R × CTI4
          END;
        END IF;
        IF vGARANT_LOGIN is null and inIDENTITY_NUMBER is not null and vTMP_PARAM_FINAL != '__UNDEF' THEN
     	    BEGIN
            GENESYS.GET_GARANT_LOGIN_BY_IC@TO_CTI4(inIDENTITY_NUMBER, vTMP_PARAM_FINAL, vGARANT_LOGIN); -- E2E × MAINTEST = CTI4R × CTI4
          END;
        END IF;
		    IF vGARANT_LOGIN IS NOT NULL THEN
          BEGIN -- find GARANT, MINITEAM, TEAM related to GARANT_LOGIN
            BEGIN -- refresh GARANT_LOGIN by Genesys employee_id
              select employee_id into vGARANT_LOGIN from cfg8m.cfg_person@to_cti2.world where upper(USER_NAME) = upper(vGARANT_LOGIN);
            EXCEPTION
              WHEN OTHERS THEN
              vGARANT := NULL;
            END;

            if vGARANT_LOGIN is not null then
              BEGIN -- find GARANT's MINITEAM and TEAM
                vGARANT := vGARANT_LOGIN  || '@' || inSTAT_SRV || '.A';
                select MINITEAM_ID, TEAM_ID into vMINITEAM_ID, vTEAM_ID
                  from CUSTAPPS.MT_MEMBERS_VW@TO_CTI1
                  where agent_name = vGARANT_LOGIN;
              EXCEPTION
                WHEN OTHERS THEN
                vMINITEAM_ID := NULL;
              END;
            END IF;

            if vMINITEAM_ID is not null then
              BEGIN -- find MINITEAM (excluding  GARANT) and TEAM (excluding MINITEAM mebers)
                select (listagg(agent_name, '@' || inSTAT_SRV || '.A,') within group (order by null)) into vMINITEAM
                  from CUSTAPPS.MT_MEMBERS_VW@TO_CTI1
                  where MINITEAM_ID = vMINITEAM_ID
                    and AGENT_NAME != vGARANT_LOGIN;
                if vMINITEAM is not null then
                 vMINITEAM := vMINITEAM  || '@' || inSTAT_SRV || '.A';
                END IF;
    
                select (listagg(agent_name, '@' || inSTAT_SRV || '.A,') within group (order by null)) into vTEAM
                  from CUSTAPPS.MT_MEMBERS_VW@TO_CTI1
                  where TEAM_ID = vTEAM_ID
                    and MINITEAM_ID != vMINITEAM_ID;
                if vTEAM is not null then
                 vTEAM := vTEAM  || '@' || inSTAT_SRV || '.A';
                END IF;
              END;
            END IF;

          END;
		    END IF;
      END;
    END IF;

	outVALUE := outVALUE || params(i) || ':' || vTMP_PARAM_FINAL || '|';

	END LOOP;

  outVALUE := outVALUE || 'GARANT:' || NVL(vGARANT, '__UNDEF') || '|' || 'MINITEAM:' || NVL(vMINITEAM, '__UNDEF') || '|' || 'TEAM:' || NVL(vTEAM, '__UNDEF') || '|';

END;