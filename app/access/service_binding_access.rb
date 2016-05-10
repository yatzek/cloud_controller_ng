module VCAP::CloudController
  class ServiceBindingAccess < BaseAccess
    def create?(service_binding, params=nil)
      return true if admin_user?
      # return false if service_binding.in_suspended_org?
      # service_binding.app.space.has_developer?(context.user)


      membership = MembershipClient.new
      membership.has_any_roles?([Membership::SPACE_DEVELOPER], service_instance.space_guid)
    end

    def delete?(service_binding)
      create?(service_binding)
    end
  end
end
