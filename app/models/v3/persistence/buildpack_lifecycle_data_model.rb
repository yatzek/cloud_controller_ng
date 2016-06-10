require 'cloud_controller/diego/lifecycles/lifecycles'

class BuildpackLifecycleDataModel < Sequel::Model(:buildpack_lifecycle_data)
  LIFECYCLE_TYPE = Lifecycles::BUILDPACK

  many_to_one :droplet,
    class: '::DropletModel',
    key: :droplet_guid,
    primary_key: :guid,
    without_guid_generation: true

  many_to_one :app,
    class: '::AppModel',
    key: :app_guid,
    primary_key: :guid,
    without_guid_generation: true

  def to_hash
    { buildpack: buildpack, stack: stack }
  end

  def validate
    return unless app_guid && droplet_guid
    errors.add(:lifecycle_data, 'Cannot be associated with both a droplet and an app')
  end
end
