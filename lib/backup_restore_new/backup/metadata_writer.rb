# frozen_string_literal: true

require 'json'

module BackupRestoreNew
  module Backup
    class MetadataWriter
      def initialize(uploads_result = nil, optimized_images_result = nil)
        @upload_stats = result_to_stats(uploads_result)
        @optimized_image_stats = result_to_stats(optimized_images_result)
      end

      def write_into(output_stream)
        output_stream.write(json)
      end

      def estimated_file_size
        # adding an additional KB to account for unknown upload stats
        json.bytesize + 1.kilobyte
      end

      private

      def json
        data = {
          version: Discourse::VERSION::STRING,
          db_version: Database.current_core_migration_version,
          git_version: Discourse.git_version,
          git_branch: Discourse.git_branch,
          base_url: Discourse.base_url,
          cdn_url: Discourse.asset_host,
          s3_base_url: SiteSetting.Upload.enable_s3_uploads ? SiteSetting.Upload.s3_base_url : nil,
          s3_cdn_url: SiteSetting.Upload.enable_s3_uploads ? SiteSetting.Upload.s3_cdn_url : nil,
          db_name: RailsMultisite::ConnectionManagement.current_db,
          multisite: Rails.configuration.multisite,
          uploads: @upload_stats,
          optimized_images: @optimized_image_stats,
          plugins: plugin_list
        }

        JSON.pretty_generate(data)
      end

      def result_to_stats(result)
        {
          total_count: result&.total_count || 0,
          included_count: result&.included_count || 0,
          missing_count: result&.failed_ids&.size || 0,
        }
      end

      def plugin_list
        plugins = { enabled: [], disabled: [] }

        Discourse.visible_plugins.each do |plugin|
          key = plugin.enabled? ? :enabled : :disabled
          plugins[key] << plugin.name
        end

        plugins
      end
    end
  end
end
