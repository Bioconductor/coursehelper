# Course Helper Application

## Table of Contents

- [App overview](#overview)
- [App hosting and administration](#hosting)
    - [Deploying changes](#changes)
- [Building a course AMI](#buildAMI)
    - [Adding a course](#addCourse)
    - [Updating a course](#updateCourse)
- [End user usage](#userUsage)
- [Modifying all instances during a course](#modifyDuringCourse)
- [After a course](#afterCourse)
    - [Shut down instances](#shutdown)
    - [Post course materials](#postMaterials)

<a name="overview"></a>
## Overview

This is a [rails](http://rubyonrails.org/) application.

App URL: [https://courses.bioconductor.org/](https://courses.bioconductor.org/)

It is meant to facilitate using Amazon Machine Images (AMIs) to
teach Bioconductor courses. It manages individual AMI instances for each course attendee and
automatically shuts off the instances when the course is over.

You give the app some basic information about the course.
Then, on the first day of the course (actually the night before)
you can go to the [app url](https://courses.bioconductor.org/)
and enter your email address and a password(*) and you will get
your very own EC2 instance and a URL to RStudio Server
(and possibly shellinabox) on that instance. If you forget
your URL, you can go back to the app and it will tell you
your url. 

* = The password should be written down on the whiteboard
in the room where the course is taking place. This ensures
that only legitimate course attendees can register.

When the course ends, the app will terminate all instances.

Before this app existed, we would tediously print out slips of
paper with the urls and pass them out, and this involved
typing and making mistakes.

<a name="hosting"></a>
## Hosting and Administration

The app is hosted on habu, inside the fhcrc network.

To administer it:

    ssh www-data@habu
    cd coursehelper

Your public key should be installed there, if not, please ask.

The app code lives in [https://github.com/Bioconductor/coursehelper](https://github.com/Bioconductor/coursehelper).

It is checked out in `www-data`'s  home directory, in 
`~/coursehelper`.

The Ruby dependencies of the app are declared in the
[Gemfile](Gemfile).

<a name="changes"></a>
### Deploying changes

It is not enough to simply do `git pull` on production. You also need to 
`touch tmp/restart.txt` in order to tell rails to use the latest changes.

<a name="buildAMI"></a>
## Building a course AMI

Generally this involves the following steps:

* Locate all course materials
* Determine whether the course will use Bioconductor release or devel
* Instantiate one of the standard
  [Bioconductor AMIs](http://www.bioconductor.org/help/bioconductor-cloud-ami/#ami_ids). Install all necessary course materials on it.
* Update all R packages on the AMI by calling `biocLite()` without
  arguments. If R itself is outdated you might update it as well.
* Save this instance as a new AMI and make a note of the AMI.
* You may need to iterate on this process a couple
  of times as the course material evolves. Be sure and
  de-register intermediate AMIs to save space.

<a name="addCourse"></a>
## Adding a course

When a course is scheduled, you should find out the following
as soon as possible:

* Dates and times of the course
* Name of the course
* Where the course will be held (time zone)
* Approximate number of attendees - is there a limit?
* Any special requirements for the instance type? Will attendees
  be doing any parallel computing, for example?
* Will the course use the release or devel version of Bioconductor?
* Where is the course material? (Usually a github repository).
* Are there any special dependencies (at the R or system level)
  that will be required for the course?

Once you have gathered all this information, you can create a
record for the course in the app database. You do this with the 
Rails console. 

Again, assuming you are on habu:

    ssh www-data@habu
    cd coursehelper

You can run the console like this:

	rails console production

Then create a new course. Here's an example with example values:

    new_course = Course.new(title: "Advanced R/Bioconductor", location: 
    "Buffalo, NY", startdate: "2016-02-21", enddate: "2016-02-23", ami_id: 
    "ami-11223344", instance_type: "t2.large", max_instances: 20, password:
    "supersecretpassword", gmt_offset: "-5")
    new_course.save()
    exit


The `ami_id` should match the AMI you created earlier. You can always
update this if the ami ID changes later. The app won't allow any more
than `max_instances` to be created so be sure you set that generously.
The `password` should not be emailed, but written in the classroom
where all attendees can see it. You should determine (google is helpful)
the `gmt_offset` of the location where the course will be taught (I
guess this can change depending on whether daylight savings is in effect?)
If you omit `gmt_offset`, it will default to Seattle time since
that's where most courses used to be taught.

Note that there is also a `region` parameter which you can
set to an [AWS region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).
If the course is to be taught in a far-flung region 
like Australia or Japan, this will mean the instances will
be started in a region closer to the attendees so 
latency should be lower and perceived
performance should be better. In order for this to work,
you **must** 
[copy your AMI to the target region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/CopyingAMIs.html).
Note that after copying, the copied
AMI in the destination region has a new AMI-ID and this
is what you should use when adding the course record above.
This feature has **not** been extensively tested so you
should confirm it works before using it, perhaps by creating
a dummy course.

<a name="updateCourse"></a>
## Updating a course

Again you do this through the console:

    rails console production


 You can list all courses with 

     Course.all

If you know your course was the last one added, you can get it with:

    course = Course.last

Or you can query by title or other attribute:

    course = Course.find_by_title("Advanced R/Bioconductor")

Once you have retrieved the course, you can modify it and then resave it:

    course.ami_id = "ami-44332211"
    course.save
    exit

<a name="userUsage"></a>
## End user usage

On the day the course starts,
all attendees should be told to go to the app URL,
[https://courses.bioconductor.org](https://courses.bioconductor.org).
(There isn't much to see there if there are no courses going
on or upcoming.)

They should click on the course they are attending (usually there
is only one course going on at a given time).
They need to enter their email address and then the course
password which should be written down somewhere in the room.
Their email addresses are not tracked, just used as an identifier
to be associated with their instance URL. The app
will start up an instance and return to the user the URL
they will need to access that instance. (If they have already
started a instance, it will return the URL previously
started by the user with that email.)

It's really important that attendees only use the URL
given to them by the app, not the one they see their
neighbor (or the teacher) using. Using someone else's
URL will disable access for that other user.

For the convenience of teachers and others who are helping
with the course, you can retrieve your URL starting at 8PM
the night before the course.

<a name="modifyDuringCourse"></a>
## Modifying all instances during a course

We try and avoid this but sometimes it happens that every instance
needs to be updated with some software, after the course is 
underway and people have already started their instances.

There's some code to do these updates in parallel. 
You need to get a list of the instance IDs that need
to be updated. This is not (yet) documented but can be
accomplished with the `aws` command line client plus
basic tools like `cut`, `sed`, etc. 
Come up with a one-line script to do the update.
Then use [ec2_hot_update](https://github.com/dtenenba/ec2_hot_update)
to run that script on all instances in parallel.

<a name="afterCourse"></a>
## After the course

<a name="shutdown"></a>
## Shut down instances

The app should shut down all instances associated with the course
at 23:55 on the last day of the course. This is done via the
following cron job:

    55 * * * * cd /home/www-data/coursehelper && /bin/bash -lc "RAILS_ENV=production bin/rake course_shutdown"  >> log/rake.log 2>&1

 (It runs at every hour but the logic figures out if it is the right
 hour in the course time zone.)
It works, but you should still doublecheck that it worked so we 
don't have to pay lots of money for unused instances.

<a name="postMaterials"></a>
## Post course materials

Post the course AMI and any related materials to the web site following instructions here:

https://github.com/Bioconductor/bioconductor.org/blob/master/README.md#adding-course-material-to-the-spreadsheet
