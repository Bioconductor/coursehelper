class Trimattendees < ActiveRecord::Migration
  def change
    remove_column :attendees, :firstname
    remove_column :attendees, :lastname
  end
end
