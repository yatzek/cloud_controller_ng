module VCAP::CloudController
  class Membership
    SPACE_DEVELOPER     = 0
    SPACE_MANAGER       = 1
    SPACE_AUDITOR       = 2
    ORG_MEMBER          = 3
    ORG_MANAGER         = 4
    ORG_AUDITOR         = 5
    ORG_BILLING_MANAGER = 6

    def initialize(user)
      @user = user
    end

    def has_any_roles?(roles, space_guid=nil, org_guid=nil)
      roles = [roles] unless roles.is_a?(Array)

      member_guids = member_guids(roles: roles)
      member_guids.include?(space_guid) || member_guids.include?(org_guid)
    end

    def space_guids_for_roles(roles)
      roles = [roles] unless roles.is_a?(Array)

      roles.map do |role|
        case role
        when SPACE_DEVELOPER
          @user.spaces.map(&:guid)
        when SPACE_MANAGER
          @user.managed_spaces.map(&:guid)
        when SPACE_AUDITOR
          @user.audited_spaces.map(&:guid)
        when ORG_MEMBER
          @user.organizations_dataset.join(
            :spaces, spaces__organization_id: :organizations__id
          ).select(:spaces__guid).map(&:guid)
        when ORG_MANAGER
          @user.managed_organizations_dataset.join(
            :spaces, spaces__organization_id: :organizations__id
          ).select(:spaces__guid).map(&:guid)
        when ORG_BILLING_MANAGER
          @user.billing_managed_organizations_dataset.join(
            :spaces, spaces__organization_id: :organizations__id
          ).select(:spaces__guid).map(&:guid)
        when ORG_AUDITOR
          @user.audited_organizations_dataset.join(
            :spaces, spaces__organization_id: :organizations__id
          ).select(:spaces__guid).map(&:guid)
        end
      end.flatten.compact
    end

    private

    def member_guids(roles: [])
      roles.map do |role|
        case role
        when SPACE_DEVELOPER
          @space_developer ||=
            @user.spaces_dataset.
            association_join(:organization).
            where(organization__status: 'active').map(&:guid)
        when SPACE_MANAGER
          @space_manager ||=
            @user.managed_spaces_dataset.
            association_join(:organization).
            where(organization__status: 'active').map(&:guid)
        when SPACE_AUDITOR
          @space_auditor ||=
            @user.audited_spaces_dataset.
            association_join(:organization).
            where(organization__status: 'active').map(&:guid)
        when ORG_MEMBER
          @org_member ||=
            @user.organizations_dataset.
            where(status: 'active').map(&:guid)
        when ORG_MANAGER
          @org_manager ||=
            @user.managed_organizations_dataset.
            where(status: 'active').map(&:guid)
        when ORG_AUDITOR
          @org_auditor ||=
            @user.audited_organizations_dataset.
            where(status: 'active').map(&:guid)
        when ORG_BILLING_MANAGER
          @org_billing_manager ||=
            @user.billing_managed_organizations_dataset.
            where(status: 'active').map(&:guid)
        end
      end.flatten.compact
    end
  end


  class MembershipClient
    def initialize()
        @client = HTTPClient.new
        @headers = { 'Authorization' => VCAP::CloudController::SecurityContext.auth_token }
    end

    def has_any_roles?(roles, space_guid=nil, org_guid=nil)
      request = {
        roles: roles,
        space_guid: space_guid,
        org_guid: org_guid
      }

      result = @client.put('http://api.bosh-lite.com/v3/memberships/has_roles', MultiJson.dump(request), @headers)

      return result.status == 204
    end

    def space_guids_for_roles(roles)
      result = @client.put('http://api.bosh-lite.com/v3/memberships/space_guids', MultiJson.dump(roles), @headers)

      return MultiJson.load(result.body)
    end
  end
end
