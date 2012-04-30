def add_access_level(permissable, user, access_level_s)
  unless user == :public
    permission = Permission.find_or_initialize_by_permissable_type_and_permissable_id_and_user_id(permissable.class.to_s, permissable.id, user.id)
  else
    permission = PublicPermission.find_or_initialize_by_permissable_type_and_permissable_id(permissable.class.to_s, permissable.id)
  end
  permission.save!
  permissable.permissions << permission
  access_level_s = [access_level_s] unless access_level_s.is_a?(Array)
  for access_level in access_level_s do
    permission.grant_access_level(access_level)
  end
end

def add_access_levels_to_users(permissable, actors, access_level_s)
  for actor in actors do
    add_access_level permissable, actor, access_level_s
  end
end

#Return Permission instance for user for Permissable or Permissable Proxy in question.
def user_permission_object(user, permissable_or_proxy)
  if object.respond_to?(:is_permissable)
    return permissable_or_proxy.permissions.find_by_actor_id(user.id)
  elsif object.respond_to?(:is_permissable_proxy)
    target = permissable_or_proxy.permission_inheritance_target
    unless target == nil || !target.respond_to?(:is_permissable)
      return target.permissions.find_by_actor_id(user.id)
    end
  else
    return nil
  end
end
