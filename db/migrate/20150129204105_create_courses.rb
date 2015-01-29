class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :title
      t.string :location
      t.date :startdate
      t.date :enddate
      t.string :ami_id
      t.string :instance_type
      t.integer :max_instances

      t.timestamps null: false
    end
  end
end
