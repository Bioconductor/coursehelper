class CreateAttendees < ActiveRecord::Migration
  def change
    create_table :attendees do |t|
      t.string :firstname
      t.string :lastname
      t.references :course, index: true
      t.string :email
      t.boolean :is_admin
      t.boolean :is_instructor
      t.string :instance_id

      t.timestamps null: false
    end
    add_foreign_key :attendees, :courses
  end
end
