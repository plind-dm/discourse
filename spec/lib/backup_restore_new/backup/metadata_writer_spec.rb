# frozen_string_literal: true
# rubocop:disable Discourse/OnlyTopLevelMultisiteSpecs

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

  describe "#estimated_file_size" do
    it "adds 1 kilobyte to the actual filesize" do
      subject.write_into(io)
      current_size = io.string.bytesize

      expect(current_size).to be > 256
      expect(subject.estimated_file_size).to eq(current_size + 1024)
    end
  end

  describe "#write" do
    def expect_metadata(expected_data_overrides = {})
      subject.write_into(io)
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
      let(:backup_uploads_result) do
        BackupRestoreNew::Backup::UploadStats.new(
          total_count: 83_829,
          included_count: 83_827,
          failed_ids: [29329, 39202]
        )
      end
      let(:backup_optimized_images_result) do
        BackupRestoreNew::Backup::UploadStats.new(
          total_count: 251_487,
          included_count: 251_481,
          failed_ids: [23880, 39828, 48520, 59329, 92939, 110392]
        )
      end

      it "writes the correct metadata" do
        expect_metadata(
          uploads: { total_count: 83_829, included_count: 83_827, missing_count: 2 },
          optimized_images: { total_count: 251_487, included_count: 251_481, missing_count: 6 }
        )
      end
    end

    context "with multisite", type: :multisite do
      it "writes the correct metadata" do
        test_multisite_connection("second") do
          expect_metadata(db_name: "second", multisite: true)
        end
      end
    end

    context "with S3 enabled" do
      before do
        setup_s3
        SiteSetting.s3_cdn_url = "https://s3.cdn.com"
      end

      it "writes the correct metadata" do
        expect_metadata(
          s3_base_url: "//s3-upload-bucket.s3.dualstack.us-west-1.amazonaws.com",
          s3_cdn_url: "https://s3.cdn.com"
        )
      end
    end

    context "with plugins" do
      def create_plugin(name, enabled:)
        metadata = Plugin::Metadata.new
        metadata.name = name

        normalized_name = name.underscore
        enabled_setting_name = "plugin_#{normalized_name}_enabled"
        SiteSetting.setting(enabled_setting_name.to_sym, enabled)

        instance = Plugin::Instance.new(metadata, "/tmp/#{normalized_name}/plugin.rb")
        instance.enabled_site_setting(enabled_setting_name)
        instance
      end

      before do
        visible_plugins = [
          create_plugin("discourse-solved", enabled: true),
          create_plugin("discourse-chat", enabled: true),
          create_plugin("discourse-math", enabled: false),
        ]
        hidden_plugins = [
          create_plugin("poll", enabled: true),
          create_plugin("styleguide", enabled: false)
        ]
        all_plugins = visible_plugins + hidden_plugins
        Discourse.stubs(:plugins).returns(all_plugins)
        Discourse.stubs(:hidden_plugins).returns(hidden_plugins)
      end

      it "includes only visible plugins in metadata" do
        expect_metadata(
          plugins: {
            enabled: ["discourse-solved", "discourse-chat"],
            disabled: ["discourse-math"]
          }
        )
      end
    end
  end
end
