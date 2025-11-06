create or replace function tstsite_exe.gen_random_uuid() returns uuid
    security definer
    parallel safe
    language c
as
$$
begin
-- missing source code
end;
$$;

alter function tstsite_exe.gen_random_uuid() owner to tstsite;

