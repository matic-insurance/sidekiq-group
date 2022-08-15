class FakeGroupWorker
  include Sidekiq::Group

  def valid_perform
    sidekiq_group(id: '12345') do |group|
      group.add('54321')
    end
  end

  def invalid_perform
    sidekiq_group(id: '12345')
  end
end

RSpec.describe Sidekiq::Group do
  let(:worker) { FakeGroupWorker.new }
  let(:collection) do
    instance_double(Sidekiq::Group::Collection, add: true, spawned_jobs!: true, initialize_total_value: true,
                                                total: 1000, processed: 34,
                                                'callback_class=' => nil, 'callback_options=' => nil)
  end

  before do
    allow(Sidekiq::Group::Collection).to receive(:new).and_return(collection)
  end

  it 'has a version number' do
    expect(Sidekiq::Group::VERSION).not_to be nil
  end

  describe '.progress' do
    it 'returns total and processed' do
      expect(described_class.progress('12345')).to eq(total: 1000, processed: 34)
    end
  end

  describe 'successful scenario' do
    before { worker.valid_perform }

    it { expect(collection).to have_received(:callback_options=).with(id: '12345') }
    it { expect(collection).to have_received(:callback_class=).with('FakeGroupWorker') }
    it { expect(collection).to have_received(:add).with('54321') }
    it { expect(collection).to have_received(:spawned_jobs!) }
    it { expect(collection).to have_received(:initialize_total_value) }

    context 'when on_complete is not defined' do
      let(:logger) { Sidekiq.logger }

      before do
        allow(logger).to receive(:warn)
        worker.on_complete({})
      end

      it { expect(logger).to have_received(:warn).with('on_complete function is not defined') }
    end
  end

  describe 'failure scenario' do
    it { expect { worker.invalid_perform }.to raise_error(Sidekiq::Group::NoBlockGivenError) }
  end
end
