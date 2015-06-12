require 'yaml'
require 'aws-sdk'

class WelcomeController < ApplicationController
  def index
    #@todays_courses = Course.where("is_visible is not :false and startdate = :today", {today: Date.today, false: false})
    all_courses = Course.where("is_visible is not :false", {false: false})
    local = DateTime.now
    @todays_courses = all_courses.find_all do |i|
      offset = i.gmt_offset
      if i.nil?
        today = Date.now
      else
        today = local.new_offset(Rational(utc_offset,24)).to_date
      end

    end

    @courses_happening_now = 
        Course.where("is_visible is not :false and startdate <= :today and enddate >= :today", {today: Date.today, false: false})
  end

  def get_instance(email, course)
    config = YAML.load_file("#{Rails.root}/config.yml")
    ec2 = AWS::EC2.new(:access_key_id => config['access_key_id'],
      :secret_access_key => config['secret_access_key'])
    instance = ec2.instances.create(image_id: course.ami_id,
      instance_type: course.instance_type,
      count: 1, key_name: config['key_pair'],
      security_groups: config['security_group'])
    instance.tag('Name', value: "Attending '#{course.title}', #{course.location}, #{course.startdate}-#{course.enddate} (#{email})")
    instance.tag("Email", value: email)
    instance.tag("CourseId", value: course.id) # for easy group termination

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
    elsif request.post?
      Rails.logger.info "in post of get_url"
      if params[:email].empty? or params[:password].empty?
        render(text: "email and password can't be blank") and return
      end
      unless params[:email] =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        render(text: "invalid email address") and return
      end
      today = Date.today
      course = Course.find(params[:id])
      if (course.enddate < today or course.startdate > today)
        render(text: "course is not happening or starting soon") and return
      end
      unless course.password == params[:password]
        render(:text => "sorry, wrong password") and return
      end
      email = params[:email].downcase
      #email.sub! "fhcrc.org", "fredhutch.org"
      count = Attendee.where(course_id: course.id).length
      if count >= course.max_instances
        render(text: "Already started #{course.max_instances} instances for this course.") and return
      end
      rec = Attendee.find_by_email(email)
      instance = nil
      if rec.nil?
        instance = get_instance(email, course)
        rec = Attendee.create(email: email, course_id: course.id, instance_id: instance.instance_id,
          public_dns: instance.public_dns_name)
      else
        if rec.public_dns.nil?
          instance = get_instance(email, course)
          rec.public_dns = instance.public_dns_name
          rec.instance_id = instance.instance_id
          rec.save
        end
      end
      render("get_url_post", locals: {url: "http://#{rec.public_dns}",
        enddate: course.enddate}) and return
    end
  end

end
