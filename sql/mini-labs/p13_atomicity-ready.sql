-- Starting-state check only; changed rows after a lab are expected.
DO $guard$
BEGIN
 IF (WITH items AS (
 SELECT 'relation|'||c.relname||'|'||c.relkind::text||'|'||c.relrowsecurity::text AS value
 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='p13_atomicity'
 UNION ALL
 SELECT 'column|'||c.relname||'|'||(row_number() OVER (PARTITION BY c.oid ORDER BY a.attnum))::text||'|'||a.attname||'|'||format_type(a.atttypid,a.atttypmod)||'|'||a.attnotnull::text||'|'||coalesce(pg_get_expr(d.adbin,d.adrelid),'')
 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_attribute a ON a.attrelid=c.oid
 LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum
 WHERE n.nspname='p13_atomicity' AND c.relkind='r' AND a.attnum>0 AND NOT a.attisdropped
 UNION ALL
 SELECT 'constraint|'||c.relname||'|'||k.conname||'|'||pg_get_constraintdef(k.oid)
 FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='p13_atomicity'
 UNION ALL
 SELECT 'index|'||indexname||'|'||indexdef FROM pg_indexes WHERE schemaname='p13_atomicity'
 UNION ALL
 SELECT 'trigger|'||t.tgname FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
 JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='p13_atomicity' AND NOT t.tgisinternal
 UNION ALL
 SELECT 'function|'||p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='p13_atomicity'
 UNION ALL
 SELECT 'type|'||t.typname FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
 WHERE n.nspname='p13_atomicity' AND t.typrelid=0 AND t.typelem=0
 UNION ALL
 SELECT 'policy|'||policyname FROM pg_policies WHERE schemaname='p13_atomicity'
 UNION ALL
 SELECT 'rewrite|'||c.relname||'|'||r.rulename||'|'||pg_get_ruledef(r.oid)
 FROM pg_rewrite r JOIN pg_class c ON c.oid=r.ev_class
 JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='p13_atomicity'
 UNION ALL
 SELECT 'inheritance|'||cn.nspname||'.'||c.relname||'|'||pn.nspname||'.'||p.relname
 FROM pg_inherits i JOIN pg_class c ON c.oid=i.inhrelid
 JOIN pg_namespace cn ON cn.oid=c.relnamespace JOIN pg_class p ON p.oid=i.inhparent
 JOIN pg_namespace pn ON pn.oid=p.relnamespace
 WHERE cn.nspname='p13_atomicity' OR pn.nspname='p13_atomicity'
 ) SELECT md5(string_agg(value,E'\n' ORDER BY value)) FROM items) IS DISTINCT FROM 'd32b85f65e9135fb1bd15874f777c330' THEN
  RAISE EXCEPTION 'p13_atomicity: structure differs from the supplied lab; save work and ask the TA. No reset performed.';
 END IF;
 IF EXISTS (
  SELECT 1 FROM pg_depend d JOIN pg_rewrite r ON r.oid=d.objid AND d.classid='pg_rewrite'::regclass
  JOIN pg_class source ON source.oid=d.refobjid JOIN pg_namespace n ON n.oid=source.relnamespace
  WHERE n.nspname='p13_atomicity' AND r.ev_class<>source.oid
 ) OR EXISTS (
  SELECT 1 FROM pg_constraint k JOIN pg_class source ON source.oid=k.confrelid
  JOIN pg_namespace n ON n.oid=source.relnamespace
  JOIN pg_class target ON target.oid=k.conrelid JOIN pg_namespace tn ON tn.oid=target.relnamespace
  WHERE n.nspname='p13_atomicity' AND tn.nspname<>'p13_atomicity'
 ) THEN
  RAISE EXCEPTION 'p13_atomicity: a dependent view or external foreign key exists; no reset performed.';
 END IF;
END
$guard$;
DO $ready$ BEGIN
IF (SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text),'[]'::jsonb) FROM p13_atomicity.loans t) <> '[]'::jsonb THEN RAISE EXCEPTION 'p13_atomicity: not at starting state (expected after doing this lab); reset this lab before replay'; END IF;
IF (SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text),'[]'::jsonb) FROM p13_atomicity.copies t) <> '[{"state": "available", "copy_id": 1301}]'::jsonb THEN RAISE EXCEPTION 'p13_atomicity: not at starting state (expected after doing this lab); reset this lab before replay'; END IF;
END $ready$;
SELECT 'p13_atomicity ready' AS result;
