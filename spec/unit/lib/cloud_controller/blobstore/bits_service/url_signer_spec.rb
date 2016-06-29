require 'spec_helper'
require 'cloud_controller/blobstore/bits_service/url_signer'

module CloudController
  module Blobstore
    module BitsService
      RSpec.describe UrlSigner do
        subject(:signer) do
          described_class.new(http_client: httpclient, username: username, password: password)
        end

        let(:httpclient) { Net::HTTP.new('https://bits-service.service.cf.internal', 80) }
        let(:expires) { 16726859876 } # some time in the year 2500
        let(:internal_endpoint) { 'http://internal.example.com' }
        let(:internal_path_prefix) { nil }
        let(:username) { 'some-user' }
        let(:password) { 'some-password' }
        let(:basic_auth_header) { { 'Authorization' => 'Basic ' + Base64.strict_encode64("#{username}:#{password}").strip } }
        let(:original_url) { 'https://bits-service.service.cf.internal/my-blob/blob.zip' }

        describe '#sign' do
          before do
            stub_request(:get, /.*\/sign\/*/).to_return(body: 'https://signed.example.com/readthis?valid-signing=some-md5-stuff', status: 200)
          end

          context 'when the url is for the internal endpoint' do
            let(:original_url) { 'https://bits-service.service.cf.internal/my-blob/blob.zip' }

            it 'requests a signed url from the bits-service with expires and path params' do
              expected_request_uri = 'https://bits-service.service.cf.internal/sign?expires=16726859876&path=%2Fmy-blob%2Fblob.zip'
              expect(httpclient).to receive(:get).with(expected_request_uri, basic_auth_header).and_call_original
              signer.sign(expires: expires, url: original_url)
            end

            it 'returns the signed url from the response with the internal endpoint host as the signed uri host' do
              signed_url = signer.sign(expires: expires, url: original_url)
              expect(signed_url).to eq('https://bits-service.service.cf.internal/readthis?valid-signing=some-md5-stuff')
            end
          end

          context 'when the url is for the external endpoint' do
            let(:original_url) { 'http://bits-service.bosh-lite.com/my-blob/blob.zip' }

            it 'requests a signed url from the bits-service with expires and path params' do
              expected_request_uri = 'https://bits-service.service.cf.internal/sign?expires=16726859876&path=%2Fmy-blob%2Fblob.zip'
              expect(httpclient).to receive(:get).with(expected_request_uri, basic_auth_header).and_call_original
              signer.sign(expires: expires, url: original_url)
            end

            it 'returns the signed url from the response with the internal endpoint host as the signed uri host' do
              signed_url = signer.sign(expires: expires, url: original_url)
              expect(signed_url).to eq('http://bits-service.bosh-lite.com/readthis?valid-signing=some-md5-stuff')
            end
          end

          context 'when the request returns an error' do
            before do
              stub_request(:get, /.*\/sign\/*/).to_return(body: '', status: 401)
            end

            it 'raises an error' do
              expect {
                signer.sign(expires: expires, url: original_url)
              }.to raise_error(SigningRequestError, /Could not get a signed url/)
            end
          end

          it 'raises SigningRequestError when HTTPClient raises SSLError' do
            allow(httpclient).to receive(:get).and_raise(OpenSSL::SSL::SSLError.new('My SSL Error'))

            expect {
              signer.sign(expires: expires, url: original_url)
            }.to raise_error(SigningRequestError, /My SSL Error/)
          end
        end
      end
    end
  end
end
