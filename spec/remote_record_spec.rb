# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteRecord do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'test.db'
    )
    PrepareDb.migrate(:up)
  end

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
    stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
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
        stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
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
        stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
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
        stub_const(record_const_name, Class.new(RemoteRecord::Base))
      end

      it 'raises a NotImplemented error' do
        expect { initialization }.to raise_error NotImplementedError
      end
    end

    context 'when a rescue_from hook is configured on the reference' do
      let(:initialize_record) do
        stub_const('SomeError', Class.new(StandardError))
        stub_const(record_const_name, Class.new(RemoteRecord::Base) do
          def get
            raise SomeError
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
        stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
          include RemoteRecord

          remote_record remote_record_class: 'RemoteRecord::Dummy::Record'
          rescue_from 'SomeError' do; end # rubocop:disable Style/BlockDelimiters
        end)
      end

      it 'handles the error using the given block' do
        initialization
        expect { reference_const_name.constantize.new(remote_resource_id: 1) }.not_to raise_error
      end
    end
  end

  describe '#fetch_remote_resource' do
    before { initialization }

    subject(:remote_reference) { reference_const_name.constantize.new(remote_resource_id: 1) }
    context 'when memoize is true' do
      let(:initialize_reference) do
        stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
          include RemoteRecord
          remote_record remote_record_class: 'RemoteRecord::Dummy::Record' do |c|
            c.memoize true
          end
        end)
      end

      it 'is only requested once', :vcr do
        remote_reference.remote
        remote_reference.remote.completed
        remote_reference.remote.title
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.once
      end

      it 'returns the attribute value', :vcr do
        expect(remote_reference.remote.title).to eq('delectus aut autem')
      end

      it 'makes an additional request to fetch a fresh instance', :vcr do
        remote_reference.remote
        remote_reference.remote.completed
        remote_reference.remote.fresh.title
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.twice
      end
    end

    context 'when memoize is false' do
      let(:initialize_reference) do
        stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
          include RemoteRecord
          remote_record remote_record_class: 'RemoteRecord::Dummy::Record' do |c|
            c.memoize false
          end
        end)
      end

      it 'is not requested on initialize', :vcr do
        remote_reference.remote
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).not_to have_been_made
      end

      it 'is requested on attribute access', :vcr do
        remote_reference.remote
        remote_reference.remote.completed
        remote_reference.remote.title
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.times(2)
      end

      it 'returns the attribute value', :vcr do
        expect(remote_reference.remote.title).to eq('delectus aut autem')
      end
    end
  end

  describe 'transform' do
    subject(:remote_reference) { reference_const_name.constantize.create(remote_resource_id: 1) }
    before { initialization }

    context 'when transform is snake_case' do
      let(:initialize_reference) do
        stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
          include RemoteRecord
          remote_record remote_record_class: 'RemoteRecord::Dummy::Record' do |c|
            c.transform [:snake_case]
          end
        end)
      end

      it 'makes snake case attributes available', :vcr do
        expect(remote_reference.remote.user_id).to eq(1)
      end
    end
  end

  describe 'querying' do
    before { initialization }
    let(:initialize_reference) do
      stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
        include RemoteRecord
        remote_record remote_record_class: 'RemoteRecord::Dummy::Record'
      end)
    end

    subject(:remote_reference) do
      reference_const_name.constantize.create(remote_resource_id: 1)
      reference_const_name.constantize.no_fetching { |r| r.find_by(remote_resource_id: 1) }
    end

    it 'does not make any requests in the no_fetching context', :vcr do
      remote_reference
      expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).not_to have_been_made
    end

    it 'still returns a Dummy::RecordReference', :vcr do
      expect(remote_reference).to be_a Dummy::RecordReference
    end

    it 'still responds to remote_resource_id', :vcr do
      expect(remote_reference.remote.remote_resource_id).to eq('1')
    end
  end

  describe '#remote.all' do
    before { initialization }
    subject(:batch_fetch) do
      reference_const_name.constantize.remote.all
    end

    let(:initialize_record) do
      stub_const(record_const_name, Class.new(RemoteRecord::Base) do
        def get
          client.get("todos/#{CGI.escape(remote_resource_id.to_s)}").body
        end

        def client
          Faraday.new('https://jsonplaceholder.typicode.com') do |conn|
            conn.request :json
            conn.response :json
            conn.headers['Authorization'] = authorization
            conn.use Faraday::Response::RaiseError
          end
        end
      end)
    end

    let(:initialize_reference) do
      stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
        include RemoteRecord
        remote_record remote_record_class: 'RemoteRecord::Dummy::Record'
      end)
    end

    context 'when there is an implementation for all on the collection' do
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
        stub_const("#{record_const_name}::Collection", Class.new(RemoteRecord::Collection) do
          def all
            response = client.get('todos').body
            match_remote_resources_by_id(response)
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
      it 'returns all records present in the database', :vcr do
        reference_const_name.constantize.insert_all((1..3).map do |id|
          { remote_resource_id: id, created_at: Time.now, updated_at: Time.now }
        end)
        expect(batch_fetch.length).to eq(3)
      end

      it 'makes only one request', :vcr do
        batch_fetch
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos')).to have_been_made.once
      end

      it 'returns all records as references', :vcr do
        expect(batch_fetch.all? { |reference| reference.is_a? reference_const_name.constantize }).to eq(true)
      end

      it 'returns records that respond to attributes', :vcr do
        expect(batch_fetch.all? { |reference| reference.remote.respond_to? :title }).to eq(true)
      end
    end

    context 'when there is no implementation for all on the collection' do
      it 'returns all records present in the database', :vcr do
        reference_const_name.constantize.insert_all((1..3).map do |id|
          { remote_resource_id: id, created_at: Time.now, updated_at: Time.now }
        end)
        expect(batch_fetch.length).to eq(3)
      end

      it 'returns all records as references', :vcr do
        expect(batch_fetch.all? { |reference| reference.is_a? reference_const_name.constantize }).to eq(true)
      end

      it 'returns records that respond to attributes', :vcr do
        expect(batch_fetch.all? { |reference| reference.remote.respond_to? :title }).to eq(true)
      end
    end

    context 'when a configuration override is supplied' do
      subject(:batch_fetch) do
        reference_const_name.constantize.remote(config: RemoteRecord::Config.new(authorization: 'authz header')).all
      end

      it 'is used in the request', :vcr do
        reference_const_name.constantize.insert_all(
          [{ remote_resource_id: 1, created_at: Time.now, updated_at: Time.now }]
        )
        batch_fetch
        expect(
          a_request(:get,
                    'https://jsonplaceholder.typicode.com/todos/1').with(headers: { 'Authorization': 'authz header' })
        ).to have_been_made.once
      end
    end
  end
end
