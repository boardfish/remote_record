# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteRecord do
  describe '#remote_record' do
    let(:record_const) { 'RemoteRecord::Dummy::Record' }
    let(:reference_const) { 'Dummy::RecordReference' }

    let(:initialize_record) do
      stub_const(record_const, Class.new(RemoteRecord::Base) do
        def get
          puts remote_resource_id
        end
      end)
    end

    let(:initialize_reference) do
      stub_const(reference_const, Class.new(ApplicationRecord) do
        include RemoteRecord
        remote_record remote_record_class: 'RemoteRecord::Dummy::Record'
      end)
    end

    let(:initialization) do
      initialize_record
      initialize_reference
    end

    context 'when all requirements are present' do
      it 'does not raise an error' do
        expect { initialization }.not_to raise_error
      end
    end

    context 'when the record class cannot be inferred' do
      let(:initialize_reference) do
        stub_const(reference_const, Class.new(ApplicationRecord) do
          include RemoteRecord
          # It'll try and load RemoteRecord::<#Class >, which ought not to exist
          remote_record
        end)
      end

      it 'raises a RecordClassNotFound error' do
        expect { initialization }.to raise_error RemoteRecord::RecordClassNotFound
      end
    end

    context 'when the record class is set to an uninitialized constant' do
      let(:initialize_reference) do
        stub_const(reference_const, Class.new(ApplicationRecord) do
          include RemoteRecord
          # It'll try and load RemoteRecord::<#Class >, which ought not to exist
          remote_record remote_record_class: 'Foobar::Baz::Bam'
        end)
      end

      it 'raises a RecordClassNotFound error' do
        expect { initialization }.to raise_error RemoteRecord::RecordClassNotFound
      end
    end

    context 'when the remote record does not respond to #get' do
      let(:initialize_record) do
        stub_const(record_const, Class.new(RemoteRecord::Base) do
        end)
      end

      it 'raises a NotImplemented error' do
        expect { initialization }.to raise_error NotImplementedError
      end
    end
  end
end
