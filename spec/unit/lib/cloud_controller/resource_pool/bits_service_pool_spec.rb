require 'spec_helper'

module VCAP::CloudController::ResourcePool
  describe BitsServicePool do
    subject { BitsServicePool.new(endpoint) }

    let(:endpoint) { 'http://bits-service.service.cf.internal/' }

    describe '#match_resources' do
      let(:resources) do
        [{ 'sha1' => 'abc' }, { 'sha1' => '12345' }]
        [{ 'sha1' => 'xyz' }, { 'sha1' => '98765' }]
      end

      let(:matches) do
        [{ 'sha1' => 'abc' }, { 'sha1' => '12345' }]
      end

      it 'makes the correct request to the bits endpoint' do
        request = stub_request(:post, File.join(endpoint, 'app_stash/matches')).
                  with(body: resources.to_json).
                  to_return(status: 200, body: [].to_json)

        subject.match_resources(resources)
        expect(request).to have_been_requested
      end

      it 'returns an array of matched descriptors' do
        stub_request(:post, File.join(endpoint, 'app_stash/matches')).
          with(body: resources.to_json).
          to_return(status: 200, body: matches.to_json)

        actual = subject.match_resources(resources)
        expect(actual).to eq(matches)
      end

      it 'raises an error when the response is not 200' do
        stub_request(:post, File.join(endpoint, 'app_stash/matches')).
          to_return(status: 400, body: '{"description":"bits-failure"}')

        expect { subject.match_resources(resources) }.to raise_error(/bits-failure/)
      end
    end

    describe '#add_resources' do
      let(:zip) { Tempfile.new('entry.zip') }

      it 'posts a zip file with new bits' do
        request = stub_request(:post, File.join(endpoint, 'app_stash/entries')).
                  with(body: /.*application".*/).
                  to_return(status: 201)

        subject.add_resources(zip)
        expect(request).to have_been_requested
      end

      it 'raises an error when the response is not 201' do
        stub_request(:post, File.join(endpoint, 'app_stash/entries')).
          to_return(status: 400, body: '{"description":"bits-failure"}')

        expect { subject.add_resources(zip) }.to raise_error(/bits-failure/)
      end
    end

    describe '#get_package' do
      let(:resources) {
        [{ 'fn' => 'app.rb', 'sha1' => '12345' }]
      }

      let(:content_bits) { 'tons of bits as ordered' }

      it 'makes the correct request to the bits service' do
        request = stub_request(:post, File.join(endpoint, 'app_stash/bundles')).
                  with(body: resources.to_json).
                  to_return(status: 200, body: content_bits)

        subject.get_package(resources)
        expect(request).to have_been_requested
      end

      it 'returns the package contents' do
        stub_request(:post, File.join(endpoint, 'app_stash/bundles')).
          with(body: resources.to_json).
          to_return(status: 200, body: content_bits)

        package = subject.get_package(resources)
        expect(package).to eq(content_bits)
      end

      it 'raises an error when the response is not 200' do
        stub_request(:post, File.join(endpoint, 'app_stash/bundles')).
          to_return(status: 400, body: '{"description":"bits-failure"}')

        expect { subject.get_package(resources) }.to raise_error(/bits-failure/)
      end
    end

    describe 'forwards vcap-request-id' do
      let(:file_path) { Tempfile.new('buildpack').path }
      let(:file_name) { 'my-buildpack.zip' }

      it 'includes the header with a POST request' do
        expect(VCAP::Request).to receive(:current_id).at_least(:twice).and_return('0815')

        request = stub_request(:post, File.join(endpoint, 'app_stash/matches')).
                  with(headers: { 'X-Vcap-Request_Id' => '0815' }).
                  to_return(status: 200, body: [].to_json)

        subject.match_resources([])
        expect(request).to have_been_requested
      end
    end

    context 'Logging' do
      let!(:request) do
        stub_request(:post, File.join(endpoint, 'app_stash/matches')).
          to_return(status: 200, body: [].to_json)
      end

      let(:vcap_id) { 'VCAP-ID-1' }

      before do
        allow(VCAP::Request).to receive(:current_id).and_return(vcap_id)
      end

      it 'logs the request being made' do
        allow_any_instance_of(Steno::Logger).to receive(:info).with('Response', anything)

        expect_any_instance_of(Steno::Logger).to receive(:info).with('Request', {
          method: 'POST',
          path: '/app_stash/matches',
          address: 'bits-service.service.cf.internal',
          port: 80,
          vcap_id: vcap_id,
          request_id: anything
        })

        subject.match_resources([])
      end

      it 'logs the response being received' do
        allow_any_instance_of(Steno::Logger).to receive(:info).with('Request', anything)

        expect_any_instance_of(Steno::Logger).to receive(:info).with('Response', {
          code: '200',
          vcap_id: vcap_id,
          request_id: anything
        })

        subject.match_resources([])
      end

      it 'matches the request_id from the request in the reponse' do
        request_id = nil

        expect_any_instance_of(Steno::Logger).to receive(:info).with('Request', anything) do |_, _, data|
          request_id = data[:request_id]
        end

        expect_any_instance_of(Steno::Logger).to receive(:info).with('Response', anything) do |_, _, data|
          expect(data[:request_id]).to eq(request_id)
        end

        subject.match_resources([])
      end
    end
  end
end
