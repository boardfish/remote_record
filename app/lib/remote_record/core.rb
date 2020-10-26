# frozen_string_literal: true

module RemoteRecord
  # Include this module in your class if you're inheriting from
  # ActiveRecord::Base or your app's ApplicationRecord.
  module Core
    after_initialize :attrs
  end
end
