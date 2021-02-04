# frozen_string_literal: true

class PrepareDb < ActiveRecord::Migration[5.2]
  def up
    down
    create_table :record_references do |table|
      table.string :remote_resource_id
      table.timestamps
    end
  end

  def down
    drop_table :record_references if table_exists?(:record_references)
  end
end
