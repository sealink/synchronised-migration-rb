require 'spec_helper'
require 'synchronised_migration/main'

describe SynchronisedMigration::Main do
  subject { described_class }
  let(:result) { subject.call }

  context 'when the prerequisites are meet' do
    let(:redis) { double }
    let(:redlock) { double }
    let(:fail_marker_value) { nil }
    let(:rake_task) { double }

    before do
      subject.instance.instance_variable_set :@redis, nil
      subject.instance.instance_variable_set :@redlock, nil

      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:get).and_return(fail_marker_value)
      allow(redis).to receive(:set)
      allow(redis).to receive(:del)

      allow(Redlock::Client).to receive(:new).and_return(redlock)
      allow(redlock).to receive(:lock!) { |lock_key, timeout, &block| block.call }

      stub_const 'Rake', Module.new
      stub_const 'Rake::Task', { 'launch:migrate' => rake_task }

      allow(rake_task).to receive(:invoke)

      stub_const(
        'RedisConfig', double(
          get: {
            host: 'example.com',
            port: 6379,
            db: 0
          }
        )
      )
    end

    context 'in the happy path' do
      it 'executes the migration successfully' do
        expect(result).to be_success
        expect(redlock).to have_received(:lock!)
        expect(redis).to have_received(:get).with('migration-failed')
        expect(redis).to have_received(:set).with('migration-failed', 1)
        expect(rake_task).to have_received(:invoke)
        expect(redis).to have_received(:del).with('migration-failed')
      end
    end

    context 'after a deployment failed previously' do
      let(:fail_marker_value) { '1' }

      it "doesn't execute the migration" do
        expect(result).not_to be_success
        expect(rake_task).not_to have_received(:invoke)
      end
    end

    context 'when the task crashed' do
      before do
        allow(rake_task).to receive(:invoke) do
          fail 'An error message'
        end
      end

      it 'marks the failure in Redis' do
        expect { result }.to raise_error('An error message')
        expect(redis).to have_received(:set).with('migration-failed', 1)
        expect(redis).not_to have_received(:del)
      end
    end
  end
end
