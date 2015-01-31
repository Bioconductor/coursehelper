class AddPublicDns < ActiveRecord::Migration
  def change
    add_column :attendees, :public_dns, :string
  end
end
