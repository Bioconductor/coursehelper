# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# the following are NOT the final AMI ids:
Course.create(title: 'Learn Bioconductor', location: 'Genentech',
    startdate: Date.new(2015,2,2), enddate: Date.new(2015,2,3),
    ami_id: 'ami-b87917d0', instance_type: 'm3.xlarge', 
    max_instances: 25)
Course.create(title: 'Use Bioconductor', location: 'Genentech',
    startdate: Date.new(2015,2,4), enddate: Date.new(2015,2,4),
    ami_id: 'ami-b87917d0', instance_type: 'm3.xlarge', 
    max_instances: 25)
