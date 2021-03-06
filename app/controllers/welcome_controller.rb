require 'yaml'
require 'aws-sdk'

class WelcomeController < ApplicationController
  def index
    #@todays_courses = Course.where("is_visible is not :false and startdate = :today", {today: Date.today, false: false})
    all_courses = Course.where("is_visible is not :false", {false: false})
    local = DateTime.now
    @todays_courses = all_courses.find_all do |i|
      offset = i.gmt_offset
      if offset.nil?
        now = DateTime.now
        today = Date.today
      else
        now = local.new_offset(Rational(offset,24))
        today = now.to_date
      end
      if i.startdate == today or (today == (i.startdate() -1) and now.hour >= 20)
        true
      else
        false
      end
    end

    # @courses_happening_now =
    #     Course.where("is_visible is not :false and startdate <= :today and enddate >= :today", {today: Date.today, false: false})
    @courses_happening_now = all_courses.find_all do |i|
      offset = i.gmt_offset
      if offset.nil?
        now = DateTime.now
        today = Date.today
      else
        now = local.new_offset(Rational(offset,24))
        today = now.to_date
      end
      unless offset.nil?
#        require 'pry';binding.pry
      end
##########################################################################################
#
# Change this conditional to control when course appears on https://courses.bioconductor
#
##########################################################################################
#     if (i.startdate <= today and (now.hour >= 7 and now.hour <=9)) and i.enddate >= today
     if (i.startdate <= today or (today == (i.startdate() -1) and now.hour >= 20)) and i.enddate >= today
        true
      else
        false
      end
    end
  end

  def get_instance(email, course)
    config = YAML.load_file("#{Rails.root}/config.yml")
    if course.region.nil?
      if config.has_key? 'region'
        region = config['region']
      else
        region = 'us-east-1'
      end
    else
      region = course.region
    end
    ec2 = AWS::EC2.new(:region => region,
      :access_key_id => config['access_key_id'],
      :secret_access_key => config['secret_access_key'])
    options = {
      image_id: course.ami_id,
        instance_type: course.instance_type,
        count: 1, key_name: config['key_pair'],
        security_groups: config['security_group']
    }
    if config.has_key? "subnet"
      options[:subnet] = config['subnet']
    end
    instance = ec2.instances.create(options)
    instance.tag('Name', value: "Attending '#{course.title}', #{course.location}, #{course.startdate}-#{course.enddate} (#{email})")
    instance.tag("Email", value: email)
    instance.tag("CourseId", value: course.id)

    begin
      puts "instance status is #{instance.status}"
    rescue
      puts "could not determine instance status"
      sleep 1
    end

    while instance.status == :pending
      sleep 1
    end
    unless instance.status == :running
      raise "Instance is not running!"
    end
    instance
  end

  def is_course_starting_or_happening? (course)
    local = DateTime.now
    offset = course.gmt_offset
    if offset.nil?
      now = DateTime.now
      today = Date.today
    else
      now = local.new_offset(Rational(offset,24))
      today = now.to_date
    end
    if (today >= course.startdate and today <= course.enddate) or
      (today == (course.startdate() -1) and now.hour >= 20)
      true
    else
      false
    end
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
      unless (is_course_starting_or_happening? course)
        render(text: "course is not happening or starting soon") and return
      end
      unless course.password == params[:password]
        render(:text => "sorry, wrong password") and return
      end
      email = params[:email].downcase
      #email.sub! "fhcrc.org", "fredhutch.org"
      Attendee.where(email: email).where(course_id: course.id).find_each do |rec|
        render("get_url_post", locals: {url: "http://#{rec.public_dns}",
          enddate: course.enddate,
          shellinabox_url: "http://#{rec.public_dns}:4200"}) and return
      end


      count = Attendee.where(course_id: course.id).length
      if count >= course.max_instances
        render(text: "Already started #{course.max_instances} instances for this course.") and return
      end
      rec = Attendee.where(email: email).where(course_id: course.id).first
      instance = nil
      if rec.nil?
        instance = get_instance(email, course)
        dns = (instance.public_dns_name.nil?) ? instance.public_ip_address : instance.public_dns_name
        rec = Attendee.create(email: email, course_id: course.id, instance_id: instance.instance_id,
          public_dns: dns)
      else
        if rec.public_dns.nil?
          instance = get_instance(email, course)
          rec.public_dns = instance.public_dns_name
          rec.instance_id = instance.instance_id
          rec.save
        end
      end
      render("get_url_post", locals: {url: "http://#{rec.public_dns}",
        enddate: course.enddate,
        shellinabox_url: "http://#{rec.public_dns}:4200"}) and return
    end
  end

end
