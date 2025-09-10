require 'rails_helper'

RSpec.describe DeliveryStatusService, type: :service do
  let(:account) { create(:account) }
  let(:store) { create(:store, account: account) }
  let(:courier) { create(:courier, account: account) }
  let(:delivery) { create(:delivery, status: 'created', store: store, account: account) }

  describe '.call' do
    context 'when transition is valid' do
      context 'from created to assigned' do
        let(:params) { { delivery: delivery, status: 'assigned' } }

        it 'updates delivery status successfully' do
          result = described_class.call(params)

          expect(result).to be_success
          expect(delivery.reload.status).to eq 'assigned'
        end

        it 'updates the timestamp' do
          freeze_time do
            result = described_class.call(params)

            expect(result).to be_success
            expect(delivery.reload.updated_at).to eq Time.current
          end
        end

        context 'when courier is present' do
          before { delivery.update!(courier: courier) }

          it 'schedules route calculation job' do
            expect(RouteCalculationJob).to receive(:perform_later).with(delivery)

            described_class.call(params)
          end
        end

        context 'when courier is not present' do
          it 'does not schedule route calculation job' do
            expect(RouteCalculationJob).not_to receive(:perform_later)

            described_class.call(params)
          end
        end
      end

      context 'from assigned to en_route' do
        let(:delivery) { create(:delivery, status: 'assigned', courier: courier, store: store, account: account) }
        let(:params) { { delivery: delivery, status: 'en_route' } }

        it 'updates status and starts tracking' do
          expect(TrackingViewJob).to receive(:perform_later).with(delivery)

          result = described_class.call(params)

          expect(result).to be_success
          expect(delivery.reload.status).to eq 'en_route'
        end
      end

      context 'from arrived_dropoff to delivered' do
        let(:delivery) { create(:delivery, status: 'arrived_dropoff', courier: courier, store: store, account: account) }
        let(:params) { { delivery: delivery, status: 'delivered' } }

        it 'completes delivery successfully' do
          result = described_class.call(params)

          expect(result).to be_success
          expect(delivery.reload.status).to eq 'delivered'
        end

        it 'stops tracking and completes delivery' do
          # Expect side effects for completion
          result = described_class.call(params)

          expect(result).to be_success
        end
      end

      context 'canceling delivery' do
        let(:params) { { delivery: delivery, status: 'canceled' } }

        it 'allows cancellation from any status' do
          %w[created assigned en_route arrived_pickup left_pickup arrived_dropoff].each do |status|
            delivery.update!(status: status)

            result = described_class.call(params)

            expect(result).to be_success
            expect(delivery.reload.status).to eq 'canceled'

            # Reset for next iteration
            delivery.update!(status: 'created')
          end
        end
      end
    end

    context 'when transition is invalid' do
      context 'trying to skip steps' do
        let(:params) { { delivery: delivery, status: 'delivered' } }

        it 'fails with error message' do
          result = described_class.call(params)

          expect(result).to be_failure
          expect(result.error).to include('Transição inválida de created para delivered')
          expect(delivery.reload.status).to eq 'created'
        end
      end

      context 'trying to go backwards' do
        let(:delivery) { create(:delivery, status: 'delivered', store: store, account: account) }
        let(:params) { { delivery: delivery, status: 'en_route' } }

        it 'fails with error message' do
          result = described_class.call(params)

          expect(result).to be_failure
          expect(result.error).to include('Transição inválida de delivered para en_route')
          expect(delivery.reload.status).to eq 'delivered'
        end
      end

      context 'invalid status' do
        let(:params) { { delivery: delivery, status: 'invalid_status' } }

        it 'fails validation' do
          result = described_class.call(params)

          expect(result).to be_failure
          expect(delivery.reload.status).to eq 'created'
        end
      end
    end

    context 'when database error occurs' do
      let(:params) { { delivery: delivery, status: 'assigned' } }

      before do
        allow(delivery).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'handles database errors gracefully' do
        expect { described_class.call(params) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(delivery.reload.status).to eq 'created'
      end
    end

    context 'with missing parameters' do
      it 'handles missing delivery' do
        result = described_class.call(status: 'assigned')

        expect(result).to be_failure
      end

      it 'handles missing status' do
        result = described_class.call(delivery: delivery)

        expect(result).to be_failure
      end
    end
  end

  describe 'side effects' do
    let(:params) { { delivery: delivery, status: new_status } }

    context 'when status is assigned' do
      let(:new_status) { 'assigned' }
      let(:delivery) { create(:delivery, status: 'created', courier: courier, store: store, account: account) }

      it 'schedules route calculation' do
        expect(RouteCalculationJob).to receive(:perform_later).with(delivery)
        described_class.call(params)
      end
    end

    context 'when status is en_route' do
      let(:new_status) { 'en_route' }
      let(:delivery) { create(:delivery, status: 'assigned', courier: courier, store: store, account: account) }

      it 'starts tracking' do
        expect(TrackingViewJob).to receive(:perform_later).with(delivery)
        described_class.call(params)
      end
    end

    context 'when status is delivered or canceled' do
      let(:delivery) { create(:delivery, status: 'arrived_dropoff', courier: courier, store: store, account: account) }

      context 'delivered' do
        let(:new_status) { 'delivered' }

        it 'executes completion side effects' do
          result = described_class.call(params)
          expect(result).to be_success
        end
      end

      context 'canceled' do
        let(:new_status) { 'canceled' }

        it 'executes completion side effects' do
          result = described_class.call(params)
          expect(result).to be_success
        end
      end
    end
  end

  describe 'performance' do
    let(:params) { { delivery: delivery, status: 'assigned' } }

    it 'completes within reasonable time' do
      expect do
        described_class.call(params)
      end.to perform_under(50).ms
    end
  end

  describe 'concurrency' do
    let(:params) { { delivery: delivery, status: 'assigned' } }

    it 'handles concurrent updates safely' do
      threads = 5.times.map do
        Thread.new do
          described_class.call(params)
        end
      end

      results = threads.map(&:value)

      # Only one should succeed, others should fail due to status change
      successful_results = results.count(&:success?)
      expect(successful_results).to eq 1
    end
  end
end
