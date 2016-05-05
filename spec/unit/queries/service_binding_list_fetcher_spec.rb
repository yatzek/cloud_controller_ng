require 'spec_helper'
require 'queries/service_binding_list_fetcher'

module VCAP::CloudController
  describe ServiceBindingListFetcher do
    let(:fetcher) { ServiceBindingListFetcher.new }
    let(:filters) { {} }

    describe '#fetch_all' do
      it 'returns a Sequel::Dataset' do
        results = fetcher.fetch_all
        expect(results).to be_a(Sequel::Dataset)
      end

      it 'includes all the V3 Service Bindings' do
        service_binding_1 = ServiceBindingModel.make
        service_binding_2 = ServiceBindingModel.make
        results = fetcher.fetch_all.all
        expect(results.length).to eq 2
        expect(results).to include(service_binding_1, service_binding_2)
      end
    end

    describe '#fetch' do
      let!(:service_binding_1) { ServiceBindingModel.make }
      let(:space_1) { service_binding_1.space }
      let!(:service_binding_2) { ServiceBindingModel.make }
      let(:space_2) { service_binding_2.space }
      let!(:undesirable_service_binding) { ServiceBindingModel.make }
      let(:space_guids) { [space_1.guid, space_2.guid] }

      it 'returns all of the desired service bindings' do
        results = fetcher.fetch(space_guids: space_guids).all

        expect(results).to include(service_binding_1, service_binding_2)
        expect(results).not_to include(undesirable_service_binding)
      end
    end
  end
end
