create or replace function tstsite_exe.encrypt(bytea, bytea, text) returns bytea
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

alter function tstsite_exe.encrypt(bytea, bytea, text) owner to tstsite;

