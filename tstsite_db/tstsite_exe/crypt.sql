create or replace function tstsite_exe.crypt(text, text) returns text
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

alter function tstsite_exe.crypt(text, text) owner to tstsite;

