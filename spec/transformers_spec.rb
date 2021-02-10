# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteRecord::Transformers do
  describe described_class::SnakeCase do
    let(:transformer) { described_class.new(data, direction) }
    subject(:expected_attribute) { transformer.transform[expected_attribute_name] }

    context 'when the direction is not valid' do
      let(:direction) { :left }
      let(:data) { { userId: 1 } }

      it 'is expected to raise an error' do
        expect { transformer }.to raise_error ArgumentError
      end
    end

    context 'when the direction is up' do
      let(:direction) { :up }
      let(:expected_attribute_name) { :user_id }
      let(:data) { { userId: 1 } }

      it { is_expected.to eq(1) }
    end

    context 'when the direction is down' do
      let(:direction) { :down }
      let(:expected_attribute_name) { :userId }
      let(:data) { { user_id: 1 } }

      it { is_expected.to eq(1) }
    end
  end

  describe described_class::DotParams do
    let(:transformer) { described_class.new(data, direction) }
    subject(:result) { transformer.transform }

    context 'when the direction is not valid' do
      let(:direction) { :left }
      let(:data) { { userId: 1 } }

      it 'is expected to raise an error' do
        expect { transformer }.to raise_error ArgumentError
      end
    end

    context 'when the direction is up' do
      let(:direction) { :up }
      let(:data) { { customer: { user_id: 1 }, state: :completed } }

      it { is_expected.to eq('customer.user_id:1;state:completed') }
    end

    xcontext 'when the direction is down' do
      let(:direction) { :down }
      let(:expected_attribute_name) { :userId }
      let(:data) { 'customer.user_id:1;state:completed' }

      it { is_expected.to eq({ customer: { user_id: 1 }, state: :completed }) }
    end
  end
end
