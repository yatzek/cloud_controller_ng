require 'spec_helper'
require 'webdav_client'

describe 'WebDAVClient' do
  [
    # WebDAVClient.new,
    WebDAVClient::Mock.new
  ].each do |client|
    describe "contract for #{client.class}" do
      describe 'existence' do
        it 'can check existence' do
          expect(client.exists?('key', {})).to be(false)
          client.upload('key', 'value', {})
          expect(client.exists?('key', {})).to be(true)
        end
      end
    end
  end

  xdescribe 'existence' do
    let(:httpclient) { instance_double(HTTPClient) }

    it 'should raise a WebDAVError if response status is neither 200 nor 404' do
      allow(response).to receive_messages(status: 500, content: '')
      allow(httpclient).to receive_messages(head: response)

      expect { client.exists?('foobar') }.to raise_error WebDAVError, /Could not get object existence/
    end

    context 'when an OpenSSL::SSL::SSLError is raised' do
      it 'reraises a WebDAVError' do
        allow(httpclient).to receive(:head).and_raise(OpenSSL::SSL::SSLError.new)
        expect { client.exists?('foobar') }.to raise_error WebDAVError, /SSL verification failed/
      end
    end
  end
end
