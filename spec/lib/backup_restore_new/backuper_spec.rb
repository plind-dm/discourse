# frozen_string_literal: true

require 'rails_helper'

describe BackupRestoreNew::Backuper do
  fab!(:admin) { Fabricate(:admin) }
  let!(:logger) do
    Class.new(BackupRestoreNew::Logger::Base) do
      def log(message, level: nil); end
    end.new
  end

  subject { described_class.new(admin.id, logger) }

  def execute_stubbed_backup(site_name: "discourse")
    date_string = "2021-03-24T20:27:31Z"
    freeze_time(Time.parse(date_string))

    tar_writer = mock("tar_writer")
    expect_tar_creation(tar_writer, site_name)
    expect_db_dump_added_to_tar(tar_writer)
    expect_uploads_added_to_tar(tar_writer)
    expect_optimized_images_added_to_tar(tar_writer)
    expect_metadata_added_to_tar(tar_writer)

    subject.run
  end

  def expect_tar_creation(tar_writer, site_name)
    current_db = RailsMultisite::ConnectionManagement.current_db
    filename = File.join(Rails.root, "public", "backups", current_db, "#{site_name}-2021-03-24-202731.tar")

    MiniTarball::Writer.expects(:create)
      .with(filename)
      .yields(tar_writer)
      .once
  end

  def expect_db_dump_added_to_tar(tar_writer)
    output_stream = mock("db_dump_output_stream")

    BackupRestoreNew::Backup::DatabaseDumper.any_instance.expects(:dump_schema_into)
      .with(output_stream)
      .once

    tar_writer.expects(:add_file_from_stream)
      .with(has_entry(name: "dump.sql.gz"))
      .yields(output_stream)
      .once
  end

  def expect_uploads_added_to_tar(tar_writer)
    output_stream = mock("uploads_stream")

    BackupRestoreNew::Backup::UploadBackuper.any_instance
      .expects(:compress_uploads_into)
      .with(output_stream)
      .returns(BackupRestoreNew::Backup::UploadStats.new(total_count: 42))
      .once

    BackupRestoreNew::Backup::UploadBackuper.expects(:include_uploads?)
      .returns(true)
      .once

    tar_writer.expects(:add_file_from_stream)
      .with(has_entry(name: "uploads.tar.gz"))
      .yields(output_stream)
      .once
  end

  def expect_optimized_images_added_to_tar(tar_writer)
    output_stream = mock("optimized_images_stream")

    BackupRestoreNew::Backup::UploadBackuper.any_instance
      .expects(:compress_optimized_images_into)
      .with(output_stream)
      .returns(BackupRestoreNew::Backup::UploadStats.new(total_count: 42))
      .once

    BackupRestoreNew::Backup::UploadBackuper.expects(:include_optimized_images?)
      .returns(true)
      .once

    tar_writer.expects(:add_file_from_stream)
      .with(has_entry(name: "optimized-images.tar.gz"))
      .yields(output_stream)
      .once
  end

  def expect_metadata_added_to_tar(tar_writer)
    output_stream = mock("metadata_stream")

    BackupRestoreNew::Backup::MetadataWriter.any_instance.expects(:estimated_file_size)
      .returns(417)
      .once

    BackupRestoreNew::Backup::MetadataWriter.any_instance.expects(:write_into)
      .with(output_stream)
      .once

    tar_writer.expects(:add_file_placeholder)
      .with(has_entries(name: "meta.json", file_size: 417))
      .returns(1)
      .once

    tar_writer.expects(:with_placeholder)
      .with(1)
      .yields(tar_writer)
      .once

    tar_writer.expects(:add_file_from_stream)
      .with(has_entry(name: "meta.json"))
      .yields(output_stream)
      .once
  end

  it "successfully creates a backup" do
    execute_stubbed_backup
  end
end
