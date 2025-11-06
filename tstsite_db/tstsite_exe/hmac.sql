create or replace function tstsite_exe.hmac(text, text, text) returns bytea
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

alter function tstsite_exe.hmac(text, text, text) owner to tstsite;

create or replace function tstsite_exe.hmac(bytea, bytea, text) returns bytea
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

alter function tstsite_exe.hmac(bytea, bytea, text) owner to tstsite;

