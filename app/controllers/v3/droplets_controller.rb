require 'presenters/v3/droplet_presenter'
require 'presenters/v3/paginated_list_presenter'
require 'queries/droplet_delete_fetcher'
require 'queries/droplet_list_fetcher'
require 'actions/droplet_delete'
require 'actions/droplet_copy'
require 'actions/droplet_create'
require 'messages/droplet_create_message'
require 'messages/droplets_list_message'
require 'messages/droplet_copy_message'
require 'cloud_controller/membership'
require 'controllers/v3/mixins/app_subresource'

class DropletsController < ApplicationController
  include AppSubresource

  def index
    message = DropletsListMessage.from_params(app_subresource_query_params)
    invalid_param!(message.errors.full_messages) unless message.valid?

    if app_nested?
      app, dataset = DropletListFetcher.new(message: message).fetch_for_app
      app_not_found! unless app && can_read?(app.space)
    else
      dataset = if roles.admin?
                  DropletListFetcher.new(message: message).fetch_all
                else
                  DropletListFetcher.new(message: message).fetch_for_spaces(space_guids: readable_space_guids)
                end
    end

    audited_spaces = Membership.new(current_user).space_guids_for_roles(Membership::SPACE_AUDITOR)
    presenter_factory = SpaceSecretPresenterFactory.new(audited_spaces)

    render status: :ok, json: PaginatedListPresenter.new(dataset, base_url(resource: 'droplets'), message, presenter_factory: presenter_factory)
  end

  def show
    droplet = DropletModel.where(guid: params[:guid]).eager(:space, space: :organization).all.first
    droplet_not_found! unless droplet && can_read?(droplet.space)
    render status: :ok, json: DropletPresenter.new(droplet, show_secrets: can_see_secrets?(droplet.space))
  end

  def destroy
    droplet, space, _org = DropletDeleteFetcher.new.fetch(params[:guid])
    droplet_not_found! unless droplet && can_read?(space)

    unauthorized! unless can_write?(space)

    droplet_deletor = DropletDelete.new(current_user.guid, current_user_email)
    droplet_deletor.delete(droplet)

    head :no_content
  end

  def copy
    message = DropletCopyMessage.create_from_http_request(params[:body])
    unprocessable!(message.errors.full_messages) unless message.valid?

    source_droplet = DropletModel.where(guid: params[:guid]).eager(:space, space: :organization).all.first
    droplet_not_found! unless source_droplet && can_read?(source_droplet.space)
    unable_to_perform!('Droplet copy', 'source droplet is not staged') unless source_droplet.staged?

    destination_app = AppModel.where(guid: message.app_guid).eager(:space, :organization).all.first
    app_not_found! unless destination_app && can_read?(destination_app.space)
    unauthorized! unless can_write?(destination_app.space)

    droplet = DropletCopy.new(source_droplet).copy(destination_app, current_user.guid, current_user_email)

    render status: :created, json: DropletPresenter.new(droplet)
  end

  def create
    staging_message = DropletCreateMessage.create_from_http_request(params[:body])
    unprocessable!(staging_message.errors.full_messages) unless staging_message.valid?

    package = PackageModel.where(guid: params[:package_guid]).eager(:app, :space, space: :organization, app: :buildpack_lifecycle_data).all.first
    package_not_found! unless package && can_read?(package.space)
    staging_in_progress! if package.app.staging_in_progress?

    if package.type == VCAP::CloudController::PackageModel::DOCKER_TYPE
      FeatureFlag.raise_unless_enabled!('diego_docker')
    end

    unauthorized! unless can_write?(package.space)

    lifecycle = LifecycleProvider.provide(package, staging_message)
    unprocessable!(lifecycle.errors.full_messages) unless lifecycle.valid?

    droplet_creator = DropletCreate.new(actor: current_user,
                                        actor_email: current_user_email)
    droplet = droplet_creator.create_and_stage(package, lifecycle, staging_message)

    render status: :created, json: DropletPresenter.new(droplet)
  rescue DropletCreate::InvalidPackage => e
    invalid_request!(e.message)
  rescue DropletCreate::SpaceQuotaExceeded
    unable_to_perform!('Staging request', "space's memory limit exceeded")
  rescue DropletCreate::OrgQuotaExceeded
    unable_to_perform!('Staging request', "organization's memory limit exceeded")
  rescue DropletCreate::DiskLimitExceeded
    unable_to_perform!('Staging request', 'disk limit exceeded')
  end

  private

  def droplet_not_found!
    resource_not_found!(:droplet)
  end

  def package_not_found!
    resource_not_found!(:package)
  end

  def staging_in_progress!
    raise CloudController::Errors::ApiError.new_from_details('StagingInProgress')
  end

  def unable_to_perform!(operation, message)
    raise CloudController::Errors::ApiError.new_from_details('UnableToPerform', operation, message)
  end
end
