require "spec_helper"

describe SynchronisedMigration::Commands::Migrate do
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

  context "when running the command with no version file" do
    let(:options) { {config: "spec/support/cli_config.yml"} }

    it "should fail" do
      expect { described_class.new.call(**options) }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  context "when running a successful migration" do
    let(:options) {
      {
        redis_uri: redis_uri,
        config: "spec/support/cli_config.yml",
        version: "1.2.3",
        debug: true,
        command: "spec/support/success-script"
      }
    }

    it { is_expected.to eq nil }
  end
end
