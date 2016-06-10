require 'spec_helper'

describe 'Broker API Versions' do
  let(:spec_sha) do
    {
      'broker_api_v2.0_spec.rb' => 'd00c5116c35df3542e7e1cd15c568c0c',
      'broker_api_v2.1_spec.rb' => '3890c9414856e61fc786e18f4f454f18',
      'broker_api_v2.2_spec.rb' => 'cd6ffe2feae45c6d3ebc4539f9cc9624',
      'broker_api_v2.3_spec.rb' => '01c91447e7bd4319bfea73e9b2168495',
      'broker_api_v2.4_spec.rb' => '15e96ff92772407a34a860dc5060e582',
      'broker_api_v2.5_spec.rb' => '021103a168dc80c780c981500de2d5be',
      'broker_api_v2.6_spec.rb' => 'a394f1177e03b48d480ab5b690173b66',
      'broker_api_v2.7_spec.rb' => '53c1a676d407023c8fe4dcec7f90ae86',
      'broker_api_v2.8_spec.rb' => '6fb8870e7f5262dd455c7c07105c3333',
    }
  end
  let(:digester) { Digester.new(algorithm: Digest::MD5) }

  it 'verifies that there is a broker API test for each minor version' do
    stub_request(:get, 'http://username:password@broker-url/v2/catalog').to_return do |request|
      @version = request.headers['X-Broker-Api-Version']
      { status: 200, body: {}.to_json }
    end

    post('/v2/service_brokers',
      { name: 'broker-name', broker_url: 'http://broker-url', auth_username: 'username', auth_password: 'password' }.to_json,
      json_headers(admin_headers))

    major_version, current_minor_version = @version.split('.').map(&:to_i)
    broker_api_specs = (0..current_minor_version).to_a.map do |minor_version|
      "broker_api_v#{major_version}.#{minor_version}_spec.rb"
    end

    expect(broker_api_specs.length).to be > 0

    current_directory = File.dirname(__FILE__)
    current_directory_list = Dir.entries(current_directory)

    actual_checksums = {}
    broker_api_specs.each do |spec|
      expect(current_directory_list).to include(spec)

      filename = "#{current_directory}/#{spec}"
      actual_checksums[spec] = digester.digest(File.read(filename))
    end

    # These tests are not meant to be changed since they help ensure backwards compatibility.
    # If you do need to update this test, you can update the expected sha
    expect(actual_checksums).to eq(spec_sha)
  end
end
