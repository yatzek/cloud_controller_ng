require 'presenters/v3/app_presenter'
require 'presenters/v3/droplet_presenter'
require 'presenters/v3/package_presenter'
require 'presenters/v3/process_presenter'
require 'presenters/v3/route_mapping_presenter'
require 'presenters/v3/task_presenter'

module VCAP::CloudController
  class DefaultPresenterFactory
    PRESENTERS = {
      'App' => VCAP::CloudController::ProcessPresenter,
      'AppModel' => VCAP::CloudController::AppPresenter,
      'DropletModel' => VCAP::CloudController::DropletPresenter,
      'PackageModel' => VCAP::CloudController::PackagePresenter,
      'RouteMappingModel' => VCAP::CloudController::RouteMappingPresenter,
      'TaskModel' => VCAP::CloudController::TaskPresenter,
    }.freeze

    def makePresenter(resource, *options)
      class_name = resource.class.name
      presenter = PRESENTERS.fetch(class_name.demodulize, nil) ||
        "#{class_name}Presenter".constantize

      presenter.new(resource, *options)
    end
  end

  class SpaceSecretPresenterFactory
    def initialize(audited_spaces, presenter_factory: nil)
      @audited_spaces = audited_spaces
      @presenter_factory = presenter_factory || DefaultPresenterFactory.new
    end

    def makePresenter(resource)
      is_space_auditor = @audited_spaces.include?(resource.space_guid)
      @presenter_factory.makePresenter(resource, show_secrets: !is_space_auditor)
    end
  end

  class PaginatedListPresenter
    def initialize(dataset, base_url, message=nil, presenter_factory: nil)
      @dataset = dataset
      @base_url = base_url
      @message = message
      @presenter_factory = presenter_factory || DefaultPresenterFactory.new
    end

    def to_hash
      {
        pagination: PaginationPresenter.new.present_pagination_hash(paginator, @base_url, @message),
        resources: presented_resources
      }
    end

    private

    def presented_resources
      paginator.records.map { |resource| presenter(resource).to_hash }
    end

    def presenter(resource)
      @presenter_factory.makePresenter(resource)
    end

    def paginator
      @paginator ||= SequelPaginator.new.get_page(@dataset, @message.try(:pagination_options))
    end
  end
end
