class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :transaction_id, :string
    add_index :audits, :transaction_id, :name => 'transaction_id_index'
  end

  def self.down
    remove_index :audits, :name => 'transaction_id_index'
    remove_column :audits, :transaction_id
  end
end

