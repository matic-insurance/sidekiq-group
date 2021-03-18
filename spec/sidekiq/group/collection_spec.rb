RSpec.describe Sidekiq::Group::Collection do
  subject(:collection) { described_class.new(cid) }

  let(:cid) { 'fake_id' }

  it { expect(collection.cid).to eq('fake_id') }

  context 'when cid is blank' do
    before do
      allow(SecureRandom).to receive(:urlsafe_base64).and_return('EsFhHzzkEsFhHzzk')
    end

    let(:cid) { nil }

    it { expect(collection.cid).to eq('EsFhHzzkEsFhHzzk') }
  end

  describe '#callback_class' do
    before { collection.callback_class = 'CallbackClass' }

    it { expect(collection.callback_class).to eq('CallbackClass') }

    it { expect(REDIS.hget(cid, 'callback_class')).to eq('CallbackClass') }
  end

  describe '#callback_options' do
    before { collection.callback_options = { id: 1 } }

    let(:options) { { id: 1 }.to_json }

    it { expect(collection.callback_options).to eq(id: 1) }

    it { expect(REDIS.hget(cid, 'callback_options')).to eq(options) }
  end

  describe '#add' do
    before { collection.add(worker_id) }

    let(:worker_id) { 'worker_id' }
    let(:pending) { Sidekiq.redis { |r| r.smembers("#{collection.cid}-jids") } }

    it { expect(pending).to include(worker_id) }
  end

  describe '#spawned_jobs!' do
    before { collection.spawned_jobs! }

    let(:spawned_all_jobs) do
      Sidekiq.redis { |r| r.hget(collection.cid, 'spawned_jobs') }.present?
    end

    it { expect(spawned_all_jobs).to be true }
  end

  describe '#success' do
    before { allow(Sidekiq::Group::Worker).to receive(:perform_async) }

    let(:callback_class) { 'FakeClass' }
    let(:callback_options) { { id: 1 } }

    context 'when completed' do
      before do
        collection.callback_class = callback_class
        collection.callback_options = callback_options
        collection.spawned_jobs!
        collection.success(0)
      end

      it 'perform worker' do
        expect(Sidekiq::Group::Worker).to have_received(:perform_async)
          .with(callback_class, 'id' => 1)
      end

      it 'cleaned up redis cid' do
        expect(REDIS.get(cid)).to be_blank
      end

      it 'cleaned up redis cid-jids' do
        expect(REDIS.get("#{cid}-jids")).to be_blank
      end

      it 'sets expiration for cid-finished' do
        expect(REDIS.ttl("#{cid}-finished")).to be <= 3600
      end
    end

    context 'when callback_class is not defined' do
      before { collection.success(0) }

      it 'does not perform worker' do
        expect(Sidekiq::Group::Worker).not_to have_received(:perform_async)
      end
    end

    context 'when uncompleted' do
      before do
        collection.add([1, 2])
        collection.success(1)
      end

      it { expect(Sidekiq::Group::Worker).not_to have_received(:perform_async) }
    end
  end
end
