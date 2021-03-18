class FakeWorker
  def on_complete(_opt = {})
    'success'
  end
end

RSpec.describe Sidekiq::Group::Worker do
  let(:perform) { described_class.new.perform(callback_class, {}) }
  let(:callback_class) { 'FakeWorker' }

  it { expect(perform).to eq('success') }
end
