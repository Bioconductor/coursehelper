class AddVisibleToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :is_visible, :boolean
  end
end
