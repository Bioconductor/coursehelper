class Course < ActiveRecord::Base
  has_many :attendees
end
