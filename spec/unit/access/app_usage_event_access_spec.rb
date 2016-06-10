require 'spec_helper'

describe AppUsageEventAccess, type: :access do
  subject(:access) { AppUsageEventAccess.new(Security::AccessContext.new) }
  let(:token) { { 'scope' => ['cloud_controller.read', 'cloud_controller.write'] } }
  let(:user) { User.make }
  let(:object) { AppUsageEvent.make }

  before do
    SecurityContext.set(user, token)
  end

  after do
    SecurityContext.clear
  end

  context 'an admin' do
    include_context :admin_setup
    it_behaves_like :full_access
    it { is_expected.to allow_op_on_object :reset, AppUsageEvent }
  end

  context 'a user that is not an admin (defensive)' do
    it_behaves_like :no_access
    it { is_expected.not_to allow_op_on_object :index, AppUsageEvent }
    it { is_expected.not_to allow_op_on_object :reset, AppUsageEvent }
  end

  context 'using a client without cloud_controller.read' do
    let(:token) { { 'scope' => [] } }
    it_behaves_like :no_access
    it { is_expected.not_to allow_op_on_object :index, AppUsageEvent }
    it { is_expected.not_to allow_op_on_object :reset, AppUsageEvent }
  end

  context 'a user that isnt logged in (defensive)' do
    let(:user) { nil }
    it_behaves_like :no_access
    it { is_expected.not_to allow_op_on_object :index, AppUsageEvent }
    it { is_expected.not_to allow_op_on_object :reset, AppUsageEvent }
  end
end
