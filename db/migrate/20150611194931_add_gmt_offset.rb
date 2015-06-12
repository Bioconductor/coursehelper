class AddGmtOffset < ActiveRecord::Migration
  def change
    add_column :courses, :gmt_offset, :string
  end
end
