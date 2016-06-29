require 'spec_helper'
require 'cloud_controller/blobstore/bits_service/blob'

module CloudController
  module Blobstore
    RSpec.describe BitsServiceBlob do
      let(:guid) { SecureRandom.uuid }
      let(:public_url) { 'http://bits-service.bosh-lite.com/resource/1.zip' }
      let(:internal_url) { 'http://bits-service.service.cf.internal/resource/1.zip' }
      let(:signer) { double(:signer) }

      subject { BitsServiceBlob.new(guid: guid, public_url: public_url, internal_url: internal_url, signer: signer) }

      describe '#public_download_url' do
        it 'returns a signed public url' do
          signed_url = 'http://bits-service.bosh-lite.com/resource/1.zip?signed=true'
          allow(signer).to receive(:sign).with(expires: kind_of(Integer), url: public_url).and_return(signed_url)

          expect(subject.public_download_url).to eq(signed_url)
        end

        describe 'when the url is not from a bit-service endpoint' do
          let(:public_url) { 'https://s3.amazonaws.com/example/example.zip' }

          it 'returns the public url as it is' do
            expect(subject.public_download_url).to eq(public_url)
          end
        end
      end

      describe '#internal_download_url' do
        it 'returns a signed internal url' do
          signed_url = 'http://bits-service.service.cf.internal/resource/1.zip?signed=true'
          allow(signer).to receive(:sign).with(expires: kind_of(Integer), url: internal_url).and_return(signed_url)

          expect(subject.internal_download_url).to eq(signed_url)
        end

        describe 'when the url is not from a bit-service endpoint' do
          let(:internal_url) { 'https://s3.amazonaws.com/example/example.zip' }

          it 'returns the internal url as it is' do
            expect(subject.internal_download_url).to eq(internal_url)
          end
        end
      end
    end
  end
end
