--! Previous: sha1:4a2b1d3d44a68f9472f08b3a919e30ffc4e63574
--! Hash: sha1:945897ad8ca49a6497fe866f4c51a2febf6da0a3

--! split: 1-current.sql
-- Enter migration here
drop function app_public.delete_friend_request(user_id uuid);

create or replace function app_public.delete_friend_request(user_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public', 'pg_temp'
    AS $$
declare
  v_friend_request app_public.friend_requests;
  v_current_user uuid;
begin
  select id into v_current_user from app_public.users where id = app_public.current_user_id();

  if v_current_user is null then
    raise exception 'You must log in to remove a friend request' using errcode = 'LOGIN';
  end if;

  if (select from app_public.friend_requests where (sender_id = v_current_user and receiver_id = user_id) or (receiver_id = v_current_user and sender_id = user_id)) is null then
    raise exception 'There is no friend request between the given users`' using errcode = 'INVAL';
  end if;

  delete from app_public.friend_requests where (sender_id = v_current_user and receiver_id = user_id) or (receiver_id = v_current_user and sender_id = user_id);

  select * into v_friend_request from app_public.friend_requests where receiver_id = v_current_user or sender_id = v_current_user;

  return true;
end;
$$;
