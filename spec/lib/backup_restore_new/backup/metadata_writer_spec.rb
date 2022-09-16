# frozen_string_literal: true

require 'rails_helper'

describe BackupRestoreNew::Backup::MetadataWriter do
  subject { described_class.new(backup_uploads_result, backup_optimized_images_result) }
  let(:backup_uploads_result) { nil }
  let(:backup_optimized_images_result) { nil }
  let(:io) { StringIO.new }

  before do
    BackupRestoreNew::Database.stubs(:current_core_migration_version).returns(20220926152703)
    Discourse.stubs(:git_version).returns("c0924f0cae1264ed1d00dda3f6c5417cdb750cf0")
    Discourse.stubs(:git_branch).returns("main")
    Discourse.stubs(:base_url).returns("https://discourse.example.com")
    Discourse.stubs(:asset_host).returns("https://cdn.example.com/foo")
    Discourse.stubs(:plugins).returns([])
    Discourse.stubs(:hidden_plugins).returns([])
  end

  describe "#write" do
    def expect_metadata(expected_data_overrides = {})
      subject.write(io)
      expect(io.string).to be_present

      expected_data = {
        version: Discourse::VERSION::STRING,
        db_version: 20220926152703,
        git_version: "c0924f0cae1264ed1d00dda3f6c5417cdb750cf0",
        git_branch: "main",
        base_url: "https://discourse.example.com",
        cdn_url: "https://cdn.example.com/foo",
        s3_base_url: nil,
        s3_cdn_url: nil,
        db_name: "default",
        multisite: false,
        uploads: { total_count: 0, included_count: 0, missing_count: 0 },
        optimized_images: { total_count: 0, included_count: 0, missing_count: 0 },
        plugins: {
          enabled: [],
          disabled: []
        }
      }.deep_merge(expected_data_overrides)

      data = JSON.parse(io.string, symbolize_names: true)
      expect(data).to eq(expected_data)
    end

    context "without uploads" do
      it "writes the correct metadata" do
        expect_metadata
      end
    end

    context "with uploads and optimized images" do
      let(:backup_uploads_result) { BackupRestoreNew::Backup::UploadStats.new(83_829, 83_827, [29329, 39202]) }
      let(:backup_optimized_images_result) { BackupRestoreNew::Backup::UploadStats.new(251_487, 251_481, [23880, 39828, 48520, 59329, 92939, 110392]) }

      it "writes the correct metadata" do
        expect_metadata(
          uploads: { total_count: 83_829, included_count: 83_827, missing_count: 2 },
          optimized_images: { total_count: 251_487, included_count: 251_481, missing_count: 6 }
        )
      end
    end
  end
end
