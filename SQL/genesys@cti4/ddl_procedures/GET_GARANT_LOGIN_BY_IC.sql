create or replace PROCEDURE "GET_GARANT_LOGIN_BY_IC" 
(
  INIDENTITY_NUMBER IN VARCHAR2 
, INGARANT_TYPE IN VARCHAR2 
, OUTGARANT_LOGIN OUT VARCHAR2 
) AS 
BEGIN
  select REPLACE(g.LOGIN_SFA, 'TO2', '') into outGARANT_LOGIN
  from CRM_SUBJECT s
    join CRM_PARTY c on s.SUBJECT_ID = c.SUBJECT_ID
      join CRM_PARTY_REF r on r.ENTITY_TYPE_ID = 'Party' and
          r.ENTITY_ID = to_char(c.PARTY_ID) and r.REF_TYPE_ID = 'GARANT'
        join CRM_PARTY p on p.PARTY_ID = r.PARTY_ID
          join CRM_PARTY_REF_PARAM rp on rp.PARTY_REF_ID = r.PARTY_REF_ID and         
            rp.NAME = 'garantType' and rp.VALUE_INDEX = inGARANT_TYPE
        join CRM_PARTY_GA_CEXT g on g.PARTY_ID = p.PARTY_ID
  where s.IDENTITY_NUMBER = inIDENTITY_NUMBER and c.ROLE_ID = 'Customer' and ROWNUM = 1;
  EXCEPTION
    WHEN OTHERS THEN
    outGARANT_LOGIN := NULL;

END GET_GARANT_LOGIN_BY_IC;