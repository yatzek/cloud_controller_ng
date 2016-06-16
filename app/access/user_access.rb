module VCAP::CloudController
  class UserAccess < BaseAccess
    def index?(object_class, params=nil)
      return true if admin_user?
      # allow related enumerations for certain models
      related_model = params && params[:related_model]
      related_model == Organization || related_model == Space
    end

    def read?(user)
      return true if admin_user?
      return false if context.user.nil?
      user.guid == context.user.guid
    end

    def can_remove_related_object?(user, params=nil)
      remove?(user, params)
    end

    def update_related_object?(user, params=nil)
      params[:verb] == 'remove' ? true : super
    end

    private

    def remove?(user, params)
      return true if admin_user?
      return false if context.user.nil?

      if params[:relation] == :billing_managed_organizations && billing_manager_count(user, params) <= 1
        raise CloudController::Errors::ApiError.new_from_details('LastBillingManagerInOrg')
      end
      if params[:relation] == :managed_organizations && org_manager_count(user, params) <= 1
        raise CloudController::Errors::ApiError.new_from_details('LastManagerInOrg')
      end

      return true if operating_on_managed_space?(params)
      return true if operating_on_managed_org?(params)

      return true if user.guid == context.user.guid
    end

    def billing_manager_count(user, params)
      org = user.billing_managed_organizations.find{|o| o.guid == params['billing_managed_organization']}
      return org.billing_managers.count
    end

    def org_manager_count(user, params)
      org = user.managed_organizations.find{|o| o.guid == params['managed_organization']}
      return org.managers.count
    end

    def operating_on_managed_org?(params)
      context.user.managed_organization_guids.include?(params[:related_guid]) && params[:relation].match(/organizations/)
    end

    def operating_on_managed_space?(params)
      context.user.managed_space_guids.include?(params[:related_guid]) && params[:relation].match(/spaces/)
    end
  end
end
