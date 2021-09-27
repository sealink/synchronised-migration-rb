require "spec_helper"

describe SynchronisedMigration::Main do
  let(:redis_uri) { "redis://127.0.0.1:6379/10" }
  let(:redis) { Redis.new(url: redis_uri) }

  let(:command) { "spec/support/success-script" }
  let(:config_opts) {
    {
      redis_uri: redis_uri,
      command: command,
      application: "test",
      version: "1.2.3"
    }
  }

  let(:configuration) { SynchronisedMigration::Configuration.new(config_opts) }

  before(:each) do
    redis.flushdb
  end

  context "when succesful migration" do
    subject { SynchronisedMigration::Main.new(configuration).call }

    before do
      Timecop.freeze(Time.utc(1990))
    end

    after do
      Timecop.return
    end

    context "when executed" do
      it "returns a succesful result" do
        expect(subject).to be_succesful
      end

      it "should have the correct status code" do
        expect(subject).to have_attributes(code: 0)
      end
    end

    context "when inspecting the redis cache" do
      subject(:success_key) { JSON.parse(redis.get(configuration.success_key)) }
      subject(:lock_key) { redis.exists?(configuration.lock_key) }
      subject(:failure_key) { redis.exists?(configuration.fail_key) }

      before do
        SynchronisedMigration::Main.new(configuration).call
      end

      it "write success key" do
        expect(success_key).to eq(
          {
            "application" => "test",
            "version" => "1.2.3",
            "timestamp" => 631152000,
            "command" => "spec/support/success-script"
          }
        )
      end

      it "failure key is not present" do
        expect(failure_key).to eq false
      end

      it "lock key is not present" do
        expect(lock_key).to eq false
      end
    end
  end

  context "when re-running a succesful migration" do
    subject { SynchronisedMigration::Main.new(configuration).call }

    before do
      SynchronisedMigration::Main.new(configuration).call
    end

    context "when executed" do
      it "returns a succesful result" do
        expect(subject).to be_succesful
      end

      it "should have the correct status code" do
        expect(subject).to have_attributes(code: 1)
      end
    end

    context "when inspecting the redis cache" do
      before do
        SynchronisedMigration::Main.new(configuration).call
      end

      subject(:success_key) { redis.exists?(configuration.success_key) }
      subject(:lock_key) { redis.exists?(configuration.lock_key) }
      subject(:failure_key) { redis.exists?(configuration.fail_key) }

      it "failure key is not present" do
        expect(failure_key).to eq false
      end

      it "lock key is not present" do
        expect(lock_key).to eq false
      end

      it "success key is present" do
        expect(success_key).to eq true
      end
    end
  end

  context "when migration previously failed" do
    subject { SynchronisedMigration::Main.new(configuration).call }

    before do
      redis.flushdb
      redis.set(configuration.fail_key, "")
    end

    context "when executed" do
      it "returns a failure result" do
        expect(subject).to be_failure
      end

      it "should have the correct status code" do
        expect(subject).to have_attributes(code: 2)
      end

      it "should have the correct error msg" do
        expect(subject).to have_attributes(error_msg: "Halting the script because the previous migration failed.")
      end
    end

    context "when inspecting the redis cache" do
      before do
        SynchronisedMigration::Main.new(configuration).call
      end

      subject(:success_key) { redis.exists?(configuration.success_key) }
      subject(:lock_key) { redis.exists?(configuration.lock_key) }
      subject(:failure_key) { redis.exists?(configuration.fail_key) }

      it "failure key is present" do
        expect(failure_key).to eq true
      end

      it "lock key is not present" do
        expect(lock_key).to eq false
      end

      it "success key is not present" do
        expect(success_key).to eq false
      end
    end
  end

  context "when migration command fails" do
    let(:command) { "spec/support/failure-script" }
    subject { SynchronisedMigration::Main.new(configuration).call }

    before do
      redis.flushdb
    end

    context "when executed" do
      it "returns a failure result" do
        expect(subject).to be_failure
      end

      it "should have the correct status code" do
        expect(subject).to have_attributes(code: 3)
      end

      it "should have the correct error msg" do
        expect(subject).to have_attributes(error_msg: "Migration command failed.")
      end
    end

    context "when inspecting the redis cache" do
      before do
        SynchronisedMigration::Main.new(configuration).call
      end

      subject(:success_key) { redis.exists?(configuration.success_key) }
      subject(:lock_key) { redis.exists?(configuration.lock_key) }
      subject(:failure_key) { redis.exists?(configuration.fail_key) }

      it "failure key is present" do
        expect(failure_key).to eq true
      end

      it "lock key is not present" do
        expect(lock_key).to eq false
      end

      it "success key is not present" do
        expect(success_key).to eq false
      end
    end
  end
end
