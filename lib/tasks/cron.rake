require 'rake'
require 'yaml'
require 'aws-sdk'
require 'rails'

# NOTE: http://stackoverflow.com/questions/876396/do-rails-rake-tasks-provide-access-to-activerecord-models
# suggests that in PRODUCTION, you need to require() the specific models you are going to use
# not sure exactly what that looks like

# The below task needs to run at 55 minutes past the hour,
# every hour. 

# Here's an example crontab entry (adjust paths to taste):
# 55 * * * * cd /home/www-data/coursehelper && /bin/bash -lc "RAILS_ENV=production bin/rake course_shutdown"  >> log/rake.log 2>&1


desc "stop all instances for courses that end today"
task :course_shutdown => :environment do
  config = YAML.load_file("#{Rails.root}/config.yml")
  # ec2 = AWS::EC2.new(:access_key_id => config['access_key_id'],
  #   :secret_access_key => config['secret_access_key'])
  today = Date.today
  all_courses = Course.where("is_visible is not :false", {false: false})
  local = DateTime.now
  courses = all_courses.find_all do |i|
    offset = i.gmt_offset
    if offset.nil?
      now = DateTime.now
      today = Date.today
    else
      now = local.new_offset(Rational(offset,24))
      today = now.to_date
    end
    if now.hour == 23 and i.enddate == today
      true
    else
      false
    end
  end

  puts "There are #{courses.length} courses that end today."
  for course in courses
    attendees = course.attendees
    puts "Course #{course.title} has #{attendees.length} attendees."
    if course.region.nil?
      region = config['region']
    else
      region = course.region
    end
    ec2 = AWS::EC2.new(:region => region,
      :access_key_id => config['access_key_id'],
      :secret_access_key => config['secret_access_key'])

    for attendee in attendees
      puts "Shutting down instance for attendee #{attendee.email}."
      begin
        ec2.instances[attendee.instance_id].terminate
        attendee.destroy
      rescue Exception => e
        puts "ERROR attendee.destroy failed #{attendee.email}."
        puts e.message
      end
    end
  end
  puts "Done."
end
