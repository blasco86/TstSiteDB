create or replace function tstsite_exe.gen_random_bytes(integer) returns bytea
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

alter function tstsite_exe.gen_random_bytes(integer) owner to tstsite;

