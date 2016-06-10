require 'spec_helper'

describe BackgroundJobEnvironment do
  let(:bg_config) { { db: 'cc-db', logging: { level: 'debug2' } } }
  subject(:background_job_environment) { described_class.new(bg_config) }

  before do
    allow(Steno).to receive(:init)
  end

  describe '#setup_environment' do
    let(:message_bus) { double(:message_bus) }
    let(:message_bus_configurer) { double(MessageBus::Configurer, go: message_bus) }

    before do
      allow(MessageBus::Configurer).to receive(:new).and_return(message_bus_configurer)
      allow(DB).to receive(:load_models)
      allow(Thread).to receive(:new).and_yield
      allow(EM).to receive(:run).and_yield
      allow(ResourcePool).to receive(:new)
    end

    it 'loads models' do
      expect(DB).to receive(:load_models)
      background_job_environment.setup_environment
    end

    it 'configures components' do
      expect(Config).to receive(:configure_components)
      background_job_environment.setup_environment
    end

    it 'configures app observer with null stager and dea pool' do
      expect(AppObserver).to receive(:configure).with(
        instance_of(Stagers),
        instance_of(Runners)
      )
      background_job_environment.setup_environment
    end
  end
end
