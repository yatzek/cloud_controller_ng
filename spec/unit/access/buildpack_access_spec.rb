require 'spec_helper'

describe BuildpackAccess, type: :access do
  subject(:access) { BuildpackAccess.new(Security::AccessContext.new) }
  let(:token) { { 'scope' => ['cloud_controller.read', 'cloud_controller.write'] } }
  let(:user) { User.make }
  let(:object) { Buildpack.make }

  before do
    SecurityContext.set(user, token)
  end

  after do
    SecurityContext.clear
  end

  context 'for an admin' do
    include_context :admin_setup
    it_behaves_like :full_access
    it { is_expected.to allow_op_on_object :upload, object }
  end

  context 'for a logged in user' do
    it_behaves_like :read_only_access
    it { is_expected.not_to allow_op_on_object :upload, object }

    context 'using a client without cloud_controller.read' do
      let(:token) { { 'scope' => [] } }

      it_behaves_like :no_access
      it { is_expected.not_to allow_op_on_object :upload, object }
    end
  end
end
