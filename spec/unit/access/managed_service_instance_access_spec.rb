require 'spec_helper'

describe ManagedServiceInstanceAccess, type: :access do
  subject(:access) { ManagedServiceInstanceAccess.new(Security::AccessContext.new) }
  let(:token) { { 'scope' => ['cloud_controller.read', 'cloud_controller.write'] } }

  let(:user) { User.make }
  let(:org) { Organization.make }
  let(:space) { Space.make(organization: org) }
  let(:service) { Service.make }
  let(:service_plan) { ServicePlan.make(service: service) }
  let(:object) { ManagedServiceInstance.make(service_plan: service_plan, space: space) }

  before do
    SecurityContext.set(user, token)
  end

  after do
    SecurityContext.clear
  end

  context 'admin' do
    include_context :admin_setup
    it_behaves_like :full_access

    context 'service plan' do
      it 'allowed when the service plan is not visible' do
        new_plan = ServicePlan.make(active: false)

        object.service_plan = new_plan
        expect(subject.update?(object)).to be_truthy
      end
    end
  end

  context 'space developer' do
    before do
      org.add_user(user)
      space.add_developer(user)
    end

    context 'service plan' do
      it 'allows when the service plan is visible' do
        new_plan = ServicePlan.make(service: service)
        object.service_plan = new_plan
        expect(subject.create?(object)).to be_truthy
        expect(subject.read_for_update?(object)).to be_truthy
        expect(subject.update?(object)).to be_truthy
      end

      it 'fails when assigning to a service plan that is not visible' do
        new_plan = ServicePlan.make(active: false)

        object.service_plan = new_plan
        expect(subject.create?(object)).to be_falsey
        expect(subject.update?(object)).to be_falsey
      end

      it 'succeeds when updating from a service plan that is not visible' do
        new_plan = ServicePlan.make(active: false)

        object.service_plan = new_plan
        expect(subject.read_for_update?(object)).to be_truthy
      end
    end
  end
end
