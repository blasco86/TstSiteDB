create or replace function tstsite_exe.pgp_key_id(bytea) returns text
    immutable
    strict
    security definer
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function tstsite_exe.pgp_key_id(bytea) owner to tstsite;

