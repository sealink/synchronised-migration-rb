require 'spec_helper'
require 'synchronised_migration/main'

describe SynchronisedMigration::Main do
  subject { described_class }
  let(:result) { subject.call }

  context 'when the prerequisites are meet' do
    let(:redis) { double }
    let(:redlock) { double }
    let(:fail_marker_value) { nil }

    before do
      subject.instance.instance_variable_set :@redis, nil
      subject.instance.instance_variable_set :@redlock, nil

      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:get).and_return(fail_marker_value)
      allow(redis).to receive(:set)
      allow(redis).to receive(:del)

      allow(Redlock::Client).to receive(:new).and_return(redlock)
      allow(redlock).to receive(:lock!) { |lock_key, timeout, &block| block.call }

      allow(Kernel).to receive(:system).and_wrap_original { |method, *args|
        next if args == [ 'bin/launch/migrate' ]
        method.call *args
      }

      allow(Bundler).to receive(:with_original_env).and_call_original

      SynchronisedMigration.configure do |config|
        config.host = 'example.com'
        config.port = 6379
        config.db = 0
      end
    end

    context 'in the happy path' do
      it 'executes the migration successfully' do
        expect(result).to be_success
        expect(redlock).to have_received(:lock!)
        expect(redis).to have_received(:get).with('migration-failed')
        expect(redis).to have_received(:set).with('migration-failed', 1)
        expect(Kernel).to have_received(:system)
        expect(Bundler).not_to have_received(:with_original_env)
        expect(redis).to have_received(:del).with('migration-failed')
      end
    end

    context 'when require a clean Bundler environment' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('WITH_CLEAN_BUNDLER_ENV', '').and_return('1')
      end

      it 'executes it with a clean Bundler environment' do
        expect(result).to be_success
        expect(Kernel).to have_received(:system)
        expect(Bundler).to have_received(:with_original_env)
      end
    end

    context 'after a deployment failed previously' do
      let(:fail_marker_value) { '1' }

      it "doesn't execute the migration" do
        expect(result).not_to be_success
        expect(Kernel).not_to have_received(:system)
      end
    end

    context 'when the task crashed' do
      before do
        allow_any_instance_of(Process::Status).to receive(:success?).and_return(false)
      end

      it 'marks the failure in Redis' do
        expect(result).not_to be_success
        expect(redis).to have_received(:set).with('migration-failed', 1)
        expect(redis).not_to have_received(:del)
      end
    end
  end
end
