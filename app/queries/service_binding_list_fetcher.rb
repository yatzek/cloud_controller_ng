module VCAP::CloudController
  class ServiceBindingListFetcher
    def fetch(space_guids:)
      ServiceBindingModel.select_all(:v3_service_bindings).
        join(:service_instances, id: :service_instance_id).
        join(:spaces, id: :space_id, guid: space_guids)
    end

    def fetch_all
      ServiceBindingModel.dataset
    end
  end
end
