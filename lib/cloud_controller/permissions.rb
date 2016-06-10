class Permissions
  ROLES_FOR_READING ||= [
    Membership::SPACE_DEVELOPER,
    Membership::SPACE_MANAGER,
    Membership::SPACE_AUDITOR,
    Membership::ORG_MANAGER
  ].freeze

  ROLES_FOR_SECRETS ||= [
    Membership::SPACE_DEVELOPER,
    Membership::SPACE_MANAGER,
    Membership::ORG_MANAGER
  ].freeze

  ROLES_FOR_WRITING ||= [
    Membership::SPACE_DEVELOPER,
  ].freeze

  def initialize(user)
    @user = user
  end

  def can_read_from_space?(space_guid, org_guid)
    roles.admin? ||
      membership.has_any_roles?(ROLES_FOR_READING, space_guid, org_guid)
  end

  def can_see_secrets_in_space?(space_guid, org_guid)
    roles.admin? ||
      membership.has_any_roles?(ROLES_FOR_SECRETS, space_guid, org_guid)
  end

  def can_write_to_space?(space_guid)
    roles.admin? || membership.has_any_roles?(ROLES_FOR_WRITING, space_guid)
  end

  def readable_space_guids
    membership.space_guids_for_roles(ROLES_FOR_READING)
  end

  private

  def membership
    Membership.new(@user)
  end

  def roles
    SecurityContext.roles
  end
end
