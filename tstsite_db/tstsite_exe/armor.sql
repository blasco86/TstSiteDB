create or replace function tstsite_exe.armor(bytea) returns text
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

alter function tstsite_exe.armor(bytea) owner to tstsite;

create or replace function tstsite_exe.armor(bytea, text[], text[]) returns text
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

alter function tstsite_exe.armor(bytea, text[], text[]) owner to tstsite;

