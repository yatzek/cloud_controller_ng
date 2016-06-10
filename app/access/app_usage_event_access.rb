class AppUsageEventAccess < BaseAccess
  def index?(object_class, params=nil)
    admin_user?
  end

  def reset?(object_class)
    admin_user?
  end

  def reset_with_token?(object_class)
    admin_user?
  end
end
