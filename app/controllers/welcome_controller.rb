require 'yaml'
require 'aws-sdk'

class WelcomeController < ApplicationController
  def index
    @todays_courses = Course.where("startdate = :today", {today: Date.today})
    @courses_happening_now = 
        Course.where("startdate <= :today and enddate >= :today", {today: Date.today})
  end

  def get_instance(email, course, rec=nil)
    # need to know access key, secret key, security group name, key pair name
    config = YAML.load_file("#{Rails.root}/config.yml")
    ec2 = AWS::EC2.new(:access_key_id => config['access_key_id'],
      :secret_access_key => config['secret_access_key'])
    instance = ec2.instances.create(image_id: course.ami_id,
      count: 1, key_name: config['key_pair'],
      security_groups: config['security_group'])
    instance.tag('Name', value: "Attending '#{course.title}', #{course.location}, #{course.startdate}-#{course.enddate} (#{email})")
    while instance.status == :pending
      sleep 1
    end
    unless instance.status == :running
      raise "Instance is not running!"
    end
    instance
  end

  def get_url
    if request.get?
      render :get_url, locals: {course_id: params[:id]}
      #course = Course.find(params[:id])
    elsif request.post?
      course = Course.find(params[:id])
      unless course.password == params[:password]
        render(:text => "sorry, wrong password") and return
      end
      email = params[:email].downcase
      rec = Attendee.find_by_email(email)
      if rec.nil?
        render :text => "u r not sined upp" and return
      else
        if rec.public_dns.nil?
        else
        render("get_url_post", locals: {url: "http://#{rec.public_dns}",
          enddate: course.enddate}) and return
        end
      end
      render(:text => "hi! #{params[:id]}") and return

    end
  end

end
