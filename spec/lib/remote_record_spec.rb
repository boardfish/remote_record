# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteRecord do
  let(:record_const_name) { 'RemoteRecord::Dummy::Record' }
  let(:reference_const_name) { 'Dummy::RecordReference' }

  let(:initialize_record) do
    stub_const(record_const_name, Class.new(RemoteRecord::Base) do
      def get
        client.get("todos/#{CGI.escape(remote_resource_id.to_s)}").body
      end

      private

      def client
        Faraday.new('https://jsonplaceholder.typicode.com') do |conn|
          conn.request :json
          conn.response :json
          conn.use Faraday::Response::RaiseError
        end
      end
    end)
  end

  let(:initialize_reference) do
    stub_const(reference_const_name, Class.new(ApplicationRecord) do
      include RemoteRecord
      remote_record remote_record_class: 'RemoteRecord::Dummy::Record'
    end)
  end

  let(:initialization) do
    initialize_record
    initialize_reference
  end

  describe '#remote_record' do
    context 'when all requirements are present' do
      it 'does not raise an error' do
        expect { initialization }.not_to raise_error
      end
    end

    context 'when the inferred record class is not defined' do
      let(:initialize_reference) do
        stub_const(reference_const_name, Class.new(ApplicationRecord) do
          include RemoteRecord
          remote_record # Inferred to be `RemoteRecord::Class`
        end)
      end

      it 'raises a RecordClassNotFound error' do
        expect { initialization }.to raise_error RemoteRecord::RecordClassNotFound
      end
    end

    context 'when the record class is set to an uninitialized constant' do
      let(:initialize_reference) do
        stub_const(reference_const_name, Class.new(ApplicationRecord) do
          include RemoteRecord
          remote_record remote_record_class: 'Foobar::Baz::Bam'
        end)
      end

      it 'raises a RecordClassNotFound error' do
        expect { initialization }.to raise_error RemoteRecord::RecordClassNotFound
      end
    end

    context 'when the remote record does not respond to #get' do
      let(:initialize_record) do
        stub_const(record_const_name, Class.new(RemoteRecord::Base) do
        end)
      end

      it 'raises a NotImplemented error' do
        expect { initialization }.to raise_error NotImplementedError
      end
    end
  end

  describe '#fetch_remote_resource' do
    # rubocop:disable RSpec/LeadingSubject
    before { initialization }

    around { |example| VCR.use_cassette('json_placeholder', &example) }

    subject(:remote_reference) { reference_const_name.constantize.new(remote_resource_id: 1) }
    # rubocop:enable RSpec/LeadingSubject

    context 'when memoize is true' do
      let(:initialize_reference) do
        stub_const(reference_const_name, Class.new(ApplicationRecord) do
          attr_accessor :remote_resource_id

          # Don't attempt a database connection to load the schema
          def self.load_schema!
            @columns_hash = {}
          end

          include RemoteRecord
          remote_record remote_record_class: 'RemoteRecord::Dummy::Record' do |c|
            c.memoize true
          end
        end)
      end

      it 'is only requested once' do
        remote_reference
        remote_reference.completed
        remote_reference.title
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.once
      end

      it 'returns the attribute value' do
        expect(remote_reference.title).to eq('delectus aut autem')
      end
    end

    context 'when memoize is false' do
      let(:initialize_reference) do
        stub_const(reference_const_name, Class.new(ApplicationRecord) do
          attr_accessor :remote_resource_id

          # Don't attempt a database connection to load the schema
          def self.load_schema!
            @columns_hash = {}
          end

          include RemoteRecord
          remote_record remote_record_class: 'RemoteRecord::Dummy::Record' do |c|
            c.memoize false
          end
        end)
      end

      it 'is requested on initialize' do
        remote_reference
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.once
      end

      it 'is requested again on attribute access' do
        remote_reference
        remote_reference.completed
        remote_reference.title
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.times(3)
      end

      it 'returns the attribute value' do
        expect(remote_reference.title).to eq('delectus aut autem')
      end
    end
  end
end
