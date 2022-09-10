# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackupRestoreNew::Operation, type: :multisite do
  before do
    Discourse.redis.del(described_class::RUNNING_KEY)
    Discourse.redis.del(described_class::ABORT_KEY)
  end

  it "uses the correct Redis namespace" do
    test_multisite_connection("second") do
      threads = described_class.start

      expect do
        described_class.abort!
        threads.each do |thread|
          thread.join(5)
          thread.kill
        end
      end.to raise_error(SystemExit)

      described_class.finish
      threads.each { |t| expect(t.status).to be_falsey }
    end
  end
end
