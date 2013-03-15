class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :organization_id, :integer
  end

  def self.down
    remove_column :audits, :organization_id
  end
end