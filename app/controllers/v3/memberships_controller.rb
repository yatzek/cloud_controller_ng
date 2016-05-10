class MembershipsController < ApplicationController
  # PUT /v3/memberships/roles {space_guid: , org_guid: , roles: ['space.developer']}
  def has_roles
    if membership.has_any_roles?(params['roles'], params['space_guid'], params['org_guid'])
      head :no_content
    else
      render nothing: true, status: 400
    end
  end

  # PUT /v3/memberships/space_guids {  roles: ['space.developer', 'space.manager'] }
  def space_guids
    result = membership.space_guids_for_roles(params['roles'])
    render status: :ok, json: result
  end
end
