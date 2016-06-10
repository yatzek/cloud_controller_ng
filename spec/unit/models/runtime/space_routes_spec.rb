require 'spec_helper'

describe SpaceRoutes do
  let(:space) { Space.make }

  subject { SpaceRoutes.new(space) }

  describe '#count' do
    context 'when there are no routes' do
      its(:count) { should eq 0 }
    end

    context 'when there are multiple routes' do
      before { 2.times { Route.make(space: space) } }
      its(:count) { should eq 2 }
    end

    context 'whyen there is a route belonging to different space' do
      before { Route.make(space: Space.make) }
      its(:count) { should eq 0 }
    end
  end
end
