require 'rake'
require 'yaml'
require 'aws-sdk'
require 'rails'

# NOTE: http://stackoverflow.com/questions/876396/do-rails-rake-tasks-provide-access-to-activerecord-models
# suggests that in PRODUCTION, you need to require() the specific models you are going to use
# not sure exactly what that looks like

desc "stop all instances for courses that end today"
task :course_shutdown => :environment do
  config = YAML.load_file("#{Rails.root}/config.yml")
  ec2 = AWS::EC2.new(:access_key_id => config['access_key_id'],
    :secret_access_key => config['secret_access_key'])
  today = Date.today
  courses = Course.where(enddate: today)
  puts "There are #{courses.length} courses that end today."
  for course in courses
    attendees = course.attendees
    puts "Course #{course.title} has #{attendees.length} attendees."
    for attendee in attendees
      puts "Shutting down instance for attendee #{attendee.email}."
      ec2.instances[attendee.instance_id].terminate
      attendee.destroy
    end
  end
  puts "Done."
end