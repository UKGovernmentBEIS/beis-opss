# Changing `unique_session_id` will invalidate all sessions for the user
Warden::Manager.before_logout do |record, warden, options|
  if record && record.devise_modules.include?(:session_limitable) &&
      warden.authenticated?(options[:scope]) &&
      !record.skip_session_limitable?
    unique_session_id = Devise.friendly_token
    record.update_unique_session_id!(unique_session_id) if record.has_completed_registration?
  end
end
