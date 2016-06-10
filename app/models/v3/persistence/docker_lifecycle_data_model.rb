require 'cloud_controller/diego/lifecycles/lifecycles'

class DockerLifecycleDataModel
  LIFECYCLE_TYPE = Lifecycles::DOCKER

  def to_hash
    {}
  end
end
