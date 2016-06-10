require 'spec_helper'

describe ServicePlanAccess, type: :access do
  subject(:access) { ServicePlanAccess.new(Security::AccessContext.new) }
  let(:token) { { 'scope' => ['cloud_controller.read', 'cloud_controller.write'] } }

  let(:user) { User.make }
  let(:service) { Service.make }
  let(:object) { ServicePlan.make(service: service) }

  before do
    SecurityContext.set(user, token)
  end

  after do
    SecurityContext.clear
  end

  it_should_behave_like :admin_full_access

  context 'for a logged in user (defensive)' do
    it_behaves_like :read_only_access
  end

  context 'a user that isnt logged in (defensive)' do
    let(:user) { nil }
    it_behaves_like :no_access
  end

  context 'any user using client without cloud_controller.read' do
    let(:token) { { 'scope' => [] } }

    it_behaves_like :no_access
  end
end
