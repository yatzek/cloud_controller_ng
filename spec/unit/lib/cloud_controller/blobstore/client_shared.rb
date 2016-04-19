shared_examples_for 'a blobstore client' do
  let!(:tmpfile) do
    Tempfile.open('') do |tmpfile|
      tmpfile.write('file content')
      tmpfile
    end
  end
  let(:key) { 'blobstore-client-shared-key' }
  let(:dest_path) { Dir::Tmpname.make_tmpname(Dir.mktmpdir, nil) }

  after do
    tmpfile.unlink
    File.delete(dest_path) if File.exist?(dest_path)
  end

  def upload_tmpfile(client, key='abcdef')
    Tempfile.open('') do |tmpfile|
      tmpfile.write(content)
      tmpfile.close
      client.cp_to_blobstore(tmpfile.path, key)
    end
  end

  describe 'existence' do
    it 'knows if a key exists' do
      different_content        = 'foobar'
      sha_of_different_content = Digester.new.digest(different_content)

      expect(client.exists?(sha_of_different_content)).to be false

      upload_tmpfile(client, sha_of_different_content)

      expect(client.exists?(sha_of_different_content)).to be true
      expect(client.blob(sha_of_different_content)).to be
    end
  end

  describe '#cp_r_to_blobstore' do
    let(:sha_of_nothing) { Digester.new.digest('') }

    it 'ensure that the sha of nothing and sha of content are different for subsequent tests' do
      expect(sha_of_nothing[0..1]).not_to eq(sha_of_content[0..1])
    end

    it 'copies the top-level local files into the blobstore' do
      FileUtils.touch(File.join(local_dir, 'empty_file'))
      subject.cp_r_to_blobstore(local_dir)
      expect(subject.exists?(sha_of_nothing)).to be true
    end

    it 'recursively copies the local files into the blobstore' do
      subdir = File.join(local_dir, 'subdir1', 'subdir2')
      FileUtils.mkdir_p(subdir)
      File.open(File.join(subdir, 'file_with_content'), 'w') { |file| file.write(content) }

      subject.cp_r_to_blobstore(local_dir)
      expect(subject.exists?(sha_of_content)).to be true
    end

    context 'when the file already exists in the blobstore' do
      before do
        FileUtils.touch(File.join(local_dir, 'empty_file'))
      end

      it 'does not re-upload it' do
        subject.cp_r_to_blobstore(local_dir)

        subject.cp_r_to_blobstore(local_dir)
        expect(client_sent_a_copy_request).to be(false)
      end
    end

    context 'limit the file size' do
      let(:client) do
        described_class.new(connection_config, directory_key, nil, nil, min_size, max_size)
      end

      it 'does not copy files below the minimum size limit' do
        path = File.join(local_dir, 'file_with_little_content')
        File.open(path, 'w') { |file| file.write('a') }

        client.cp_r_to_blobstore(path)
        expect(client).not_to receive(:exists)
        expect(client).not_to receive(:cp_to_blobstore)
      end

      it 'does not copy files above the maximum size limit' do
        path = File.join(local_dir, 'file_with_more_content')
        File.open(path, 'w') { |file| file.write('an amount of content that is larger than the maximum limit') }

        expect(client).not_to receive(:exists)
        expect(client).not_to receive(:cp_to_blobstore)
        client.cp_r_to_blobstore(path)
      end
    end
  end

  it 'copies directory contents recursively to the blobstore' do
    Dir.mktmpdir do |dir|
      expect {
        subject.cp_r_to_blobstore(dir)
      }.not_to raise_error
    end
  end

  it 'copies a file to the blobstore' do
    expect {
      retry_count = 2
      subject.cp_to_blobstore(tmpfile.path, 'destination_key', retry_count)
    }.not_to raise_error
  end

  it 'copies a file to a different key' do
    expect {
      subject.cp_file_between_keys(key, 'destination_key')
    }.not_to raise_error
  end

  it 'deletes all the files from the blobstore' do
    expect {
      page_size = 1
      subject.delete_all(page_size)
    }.not_to raise_error
  end

  it 'deletes all the files in a path from the blobstore' do
    expect {
      subject.delete_all_in_path('some-path')
    }.not_to raise_error
  end

  it 'deletes the file by key in the blobstore' do
    expect {
      subject.delete('source-key')
    }.not_to raise_error
  end

  it 'deletes the blob' do
    expect {
      subject.delete_blob(deletable_blob)
    }.not_to raise_error
  end

  it 'returns a blob object for a file by key' do
    expect(subject.blob(key)).to be_a(CloudController::Blobstore::Blob)
  end
end
