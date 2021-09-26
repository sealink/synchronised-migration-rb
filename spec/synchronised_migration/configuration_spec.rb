require "spec_helper"

describe SynchronisedMigration::Configuration do
  context "with default values" do
    subject { described_class.new(application: "test", version: "1.2.3") }

    it "has sane defaults" do
      expect(subject).to have_attributes({
        redis_uri: "redis://127.0.0.1:6379/0",
        command: "bin/launch/migrate",
        application: "test",
        version: "1.2.3",
        debug: false,
        timeout_milliseconds: 3_600_000,
        retry_delay_milliseconds: 3000,
        success_key: "migration-success-test-1.2.3",
        fail_key: "migration-failed-test",
        lock_key: "migration-lock-test"
      })
    end
  end

  context "when configuration is loaded via cli options" do
    let(:cli_options) {
      {
        config: "spec/support/cli_config.yml",
        version: "1.2.3"
      }
    }

    subject { described_class.from_cli(cli_options) }

    context "when all options from config file" do
      it {
        is_expected.to have_attributes({
          redis_uri: "redis://127.0.0.1:6379/10",
          command: "bin/launch/custom_migrate",
          application: "Quicktravel",
          version: "1.2.3",
          debug: false,
          timeout_milliseconds: 3_600_000,
          retry_delay_milliseconds: 3000
        })
      }
    end

    context "when options are overwritten" do
      let(:cli_options) {
        {
          config: "spec/support/cli_config.yml",
          redis_uri: "redis://127.0.0.1:6379/32",
          version: "1.2.3",
          debug: true
        }
      }

      it {
        is_expected.to have_attributes({
          redis_uri: "redis://127.0.0.1:6379/32",
          command: "bin/launch/custom_migrate",
          application: "Quicktravel",
          version: "1.2.3",
          debug: true,
          timeout_milliseconds: 3_600_000,
          retry_delay_milliseconds: 3000
        })
      }
    end
  end
end
