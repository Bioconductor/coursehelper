class WelcomeController < ApplicationController
  def index
    @todays_courses = Course.where("startdate = :today", {today: Date.today})
    @courses_happening_now = 
        Course.where("startdate <= :today and enddate >= :today", {today: Date.today})
  end

  def get_url
    if request.get?
    elsif request.post?
    end
  end

end
