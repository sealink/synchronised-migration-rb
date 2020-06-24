require 'spec_helper'
require 'synchronised_migration/main'

describe SynchronisedMigration::Main do
  subject { described_class }
  let(:result) { subject.call }

  context 'when the prerequisites are meet' do
    let(:redis) { double }
    let(:redlock) { double }
    let(:fail_marker_value) { nil }
    let(:success_marker_value) { nil }
    let(:version_suffix) { 'bork' }
    let(:set_version_suffix) { ENV['REDLOCK_VERSION_SUFFIX'] = version_suffix }
    let(:time_value) { double(to_i: 123456789) }

    before do
      set_version_suffix

      subject.instance.instance_variable_set :@redis, nil
      subject.instance.instance_variable_set :@redlock, nil

      allow(subject.instance).to receive(:execute).and_call_original
      allow(subject.instance).to receive(:migrate).and_call_original

      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:get) { |key|
        case key
        when "migration-failed-#{version_suffix}"
          fail_marker_value
        when "migration-failed"
          fail_marker_value
        when "migration-success-#{version_suffix}"
          success_marker_value
        when "migration-success"
          success_marker_value
        else
          raise "invalid key for redis get: #{key}"
        end
      }
      allow(redis).to receive(:set)
      allow(redis).to receive(:del)

      allow(Redlock::Client).to receive(:new).and_return(redlock)
      allow(redlock).to receive(:lock!) { |lock_key, timeout, &block| block.call }

      allow(Time).to receive(:now).and_return(time_value)

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
        expect(redis).to have_received(:get).with('migration-failed-bork')
        expect(redis).to have_received(:set).with('migration-failed-bork', 123456789, ex: 3600)
        expect(redis).to have_received(:set).with('migration-success-bork', 123456789, ex: 3600*24*30)
        expect(Kernel).to have_received(:system)
        expect(Bundler).not_to have_received(:with_original_env)
        expect(redis).to have_received(:del).with('migration-failed-bork')
      end

      context 'and migration completed previously' do
        let(:success_marker_value) { '1' }
        it 'contines without executing' do
          expect(result).to be_success
          expect(redlock).not_to have_received(:lock!)
        end
      end

      context 'executing in lock waiter' do
        let(:result2) { subject.call }

        before do
          # Note: bypasses the first success flag check so it can enter lock.
          expect(result).to be_success
          allow(redis).to receive(:get).and_return(nil, '1')
        end

        it 'early exits and does not execute again', :aggregate_failures do
          expect(result2).to be_success
          expect(redlock).to have_received(:lock!).exactly(2).times
          expect(Kernel).to have_received(:system).exactly(1).times
          expect(subject.instance).to have_received(:execute).exactly(2).times
          expect(subject.instance).to have_received(:migrate).exactly(1).times
        end
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
        expect(redis).to have_received(:set).with('migration-failed-bork', 123456789, ex: 3600)
        expect(redis).not_to have_received(:del)
      end
    end

    context 'without version suffix' do
      let(:set_version_suffix) { ENV.delete 'REDLOCK_VERSION_SUFFIX' }

      context 'in the happy path' do
        it 'executes the migration successfully' do
          expect(result).to be_success
          expect(redlock).to have_received(:lock!)
          expect(redis).to have_received(:get).with('migration-failed')
          expect(redis).to have_received(:set).with('migration-failed', 123456789, ex: 3600)
          expect(Kernel).to have_received(:system)
          expect(Bundler).not_to have_received(:with_original_env)
          expect(redis).to have_received(:del).with('migration-failed')
        end
      end

      context 'when the task crashed' do
        before do
          allow_any_instance_of(Process::Status).to receive(:success?).and_return(false)
        end

        it 'marks the failure in Redis' do
          expect(result).not_to be_success
          expect(redis).to have_received(:set).with('migration-failed', 123456789, ex: 3600)
          expect(redis).not_to have_received(:del)
        end
      end
    end
  end
end
