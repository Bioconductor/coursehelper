class AddPwToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :password, :string
  end
end
