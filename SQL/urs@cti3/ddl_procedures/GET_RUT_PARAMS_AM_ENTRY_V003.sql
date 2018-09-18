create or replace PROCEDURE GET_RUT_PARAMS_AM_ENTRY_V003 (
	inDEMAND_TYPE IN VARCHAR2,
  inCUST_ID IN VARCHAR2,
  inMSISDN IN VARCHAR2,
  inORIGINATOR_ID IN VARCHAR2,
	outVALUE OUT NOCOPY VARCHAR2)
  
IS
  
	TYPE ParamsType IS TABLE OF VARCHAR2(128);
	params ParamsType := ParamsType('UPDATE_P8','CUSTOMER_DOC_TYPE','CUSTOMER_DOC_SUB_TYPE','ACK_EMPLOYEE_EMAIL','ACK_CUSTOMER_SMS','TARGET_SYSTEM','MISSING_DOC_ID_SKIP_UPDATE_P8');
	i INTEGER;
	vTMP_PARAM1 VARCHAR2(128);
	vTMP_PARAM2 VARCHAR2(128);
	vTMP_PARAM_FINAL VARCHAR2(128);
	vEMAIL VARCHAR2(200);
  letter VARCHAR2(2);
  aletter NUMBER;
  astr VARCHAR2(255);
  vOUT VARCHAR2(1024);
  
BEGIN

	vOUT := '';

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
    
	vOUT := vOUT || vTMP_PARAM_FINAL || '|';

	END LOOP;

  IF inORIGINATOR_ID is not null THEN
  
    BEGIN
    
      SELECT AM_EMAIL into vEMAIL
      FROM AM_LDAP
      WHERE lower(LOGINNAME) = lower('to2\' || inORIGINATOR_ID) AND rownum = 1;
      
    EXCEPTION
      WHEN OTHERS THEN
        vEMAIL := '__UNDEF';
    END;

  END IF;

  vOUT := vOUT || NVL(vEMAIL, '__UNDEF') || '|';
  
  FOR i IN 1 .. length(vOUT) LOOP
  
    letter := substr(vOUT,i,1);
    aletter := ascii(letter);
    astr := asciistr(letter);
    
    IF aletter < 128 THEN
      outVALUE := outVALUE || letter;
    ELSE
      outVALUE := outVALUE || '&#' || to_number(substr(astr,2,4),'XXXX') || ';';      
    END IF;
    
  END LOOP;
   
END;