require "spec_helper"

describe SynchronisedMigration::Commands::Clear do
  let(:redis_uri) { "redis://127.0.0.1:6379/10" }
  let(:redis) { Redis.new(url: redis_uri) }
  let(:options) { {} }

  subject { described_class.new.call(**options) }
  before(:each) do
    redis.flushdb
  end

  context "when running the command with no config file" do
    it "should fail" do
      expect { described_class.new.call(**options) }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  context "when running a clear all keys - no version provided" do
    let(:options) {
      {
        redis_uri: redis_uri,
        config: "spec/support/cli_config.yml",
        all: true
      }
    }

    it "should fail" do
      expect { described_class.new.call(**options) }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  context "when running a clear - fail key only" do
    let(:options) {
      {
        redis_uri: redis_uri,
        config: "spec/support/cli_config.yml",
        version: "1.2.3"
      }
    }

    it { is_expected.to eq nil }
  end

  context "when running a clear - all keys" do
    let(:options) {
      {
        redis_uri: redis_uri,
        config: "spec/support/cli_config.yml",
        version: "1.2.3",
        all: true
      }
    }

    it { is_expected.to eq nil }
  end
end
