
  CREATE OR REPLACE FORCE VIEW "CUSTAPPS"."MT_MEMBERS_VW" ("AGENT_NAME", "MINITEAM_ID", "TEAM_ID") AS 
  select a.agent_name, a.MINITEAM_ID, m.TEAM_ID from CUSTAPPS.MT_AGENTS a
left join CUSTAPPS.MT_MINITEAMS m
on a.MINITEAM_ID = m.id;
