create or replace function tstsite_exe.gen_salt(text) returns text
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

alter function tstsite_exe.gen_salt(text) owner to tstsite;

create or replace function tstsite_exe.gen_salt(text, integer) returns text
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

alter function tstsite_exe.gen_salt(text, integer) owner to tstsite;

