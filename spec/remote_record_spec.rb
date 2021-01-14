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
        remote_reference
        remote_reference.completed
        remote_reference.title
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.once
      end

      it 'returns the attribute value', :vcr do
        expect(remote_reference.title).to eq('delectus aut autem')
      end

      it 'makes an additional request to fetch a fresh instance', :vcr do
        remote_reference
        remote_reference.completed
        remote_reference.fresh.title
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

      it 'is requested on initialize', :vcr do
        remote_reference
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.once
      end

      it 'is requested again on attribute access', :vcr do
        remote_reference
        remote_reference.completed
        remote_reference.title
        expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).to have_been_made.times(3)
      end

      it 'returns the attribute value', :vcr do
        expect(remote_reference.title).to eq('delectus aut autem')
      end
    end
  end

  describe 'transform' do
    subject(:remote_reference) { reference_const_name.constantize.new(remote_resource_id: 1) }
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
        expect(remote_reference.user_id).to eq(1)
      end
    end
  end

  describe 'disable fetching' do
    before { initialization }
    subject(:remote_reference) { reference_const_name.constantize.new(remote_resource_id: 1, fetching: false) }
    let(:initialize_reference) do
      stub_const(reference_const_name, Class.new(ActiveRecord::Base) do
        include RemoteRecord
        remote_record remote_record_class: 'RemoteRecord::Dummy::Record'
      end)
    end

    it 'does not make any requests' do
      remote_reference
      expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos/1')).not_to have_been_made
    end

    it 'still returns a Dummy::RecordReference' do
      expect(remote_reference).to be_a Dummy::RecordReference
    end

    it 'still responds to remote_resource_id' do
      expect(remote_reference.remote_resource_id).to eq('1')
    end

    it 'raises NoMethodError for attributes' do
      expect { remote_reference.completed }.to raise_error NoMethodError
    end
  end

  describe '#remote_all' do
    before { initialization }
    subject(:batch_fetch) do
      reference_const_name.constantize.remote_all
    end

    let(:initialize_record) do
      stub_const(record_const_name, Class.new(RemoteRecord::Base) do
        def get
          client.get("todos/#{CGI.escape(remote_resource_id.to_s)}").body
        end

        def self.all(&authz_proc)
          client(&authz_proc).get('todos').body
        end

        def self.client
          Faraday.new('https://jsonplaceholder.typicode.com') do |conn|
            conn.request :json
            conn.response :json
            conn.headers['Authorization'] = yield if block_given?
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

    it 'makes only one request', :vcr do
      batch_fetch
      expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos')).to have_been_made.once
    end

    it 'returns all records', :vcr do
      expect(batch_fetch.length).to eq(200)
    end

    it 'returns all records as references', :vcr do
      expect(batch_fetch.all? { |reference| reference.is_a? reference_const_name.constantize }).to eq(true)
    end

    it 'returns records that respond to attributes', :vcr do
      expect(batch_fetch.all? { |reference| reference.respond_to? :title }).to eq(true)
    end

    context 'when an authorization proc is supplied' do
      subject(:batch_fetch) do
        reference_const_name.constantize.remote_all { 'authz header' }
      end

      it 'is used in the request', :vcr do
        batch_fetch
        expect(
          a_request(:get,
                    'https://jsonplaceholder.typicode.com/todos').with(headers: { 'Authorization': 'authz header' })
        ).to have_been_made.once
      end
    end
  end

  describe '#remote_where' do
    before { initialization }
    subject(:batch_fetch) do
      reference_const_name.constantize.remote_where(user_id: 1)
    end

    let(:initialize_record) do
      stub_const(record_const_name, Class.new(RemoteRecord::Base) do
        def get
          client.get("todos/#{CGI.escape(remote_resource_id.to_s)}").body
        end

        def self.all(&authz_proc)
          client(&authz_proc).get('todos').body
        end

        def self.where(params, &authz_proc)
          client(&authz_proc).get('todos', params.to_h { |k, v| [k.to_s.camelize(:lower).to_sym, v] }).body
        end

        def self.client
          Faraday.new('https://jsonplaceholder.typicode.com') do |conn|
            conn.request :json
            conn.response :json
            conn.headers['Authorization'] = yield if block_given?
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

    it 'makes only one request', :vcr do
      batch_fetch
      expect(a_request(:get, 'https://jsonplaceholder.typicode.com/todos?userId=1')).to have_been_made.once
    end

    it 'returns all records', :vcr do
      expect(batch_fetch.length).to eq(10)
    end

    it 'returns all records as references', :vcr do
      expect(batch_fetch.all? { |reference| reference.is_a? reference_const_name.constantize }).to eq(true)
    end

    it 'returns records that respond to attributes', :vcr do
      expect(batch_fetch.all? { |reference| reference.respond_to? :title }).to eq(true)
    end

    context 'when an authorization proc is supplied' do
      subject(:batch_fetch) do
        reference_const_name.constantize.remote_where(user_id: 1) { 'authz header' }
      end

      it 'is used in the request', :vcr do
        batch_fetch
        expect(
          a_request(:get,
                    'https://jsonplaceholder.typicode.com/todos?userId=1')
                    .with(headers: { 'Authorization': 'authz header' })
        ).to have_been_made.once
      end
    end
  end
end
