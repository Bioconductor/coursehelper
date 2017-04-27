# Course Helper Application

## Table of Contents

- [App overview](#overview)
- [App hosting and administration](#hosting)
    - [Deploying changes](#changes)
- [Building or Updating a course AMI](#buildAMI)
    - [Launch AMI of Interest](#launchAMI)
    - [Update New Instance](#updateInst)
    - [Clone and Clean Up](#cloneNclean)
    - [Testing Rstudio](#testR)
    - [Initializing courses.bioconductor.org](#initCourse)
    - [Adding a Course](#addCourse)
    - [Updating a Course](#updateCourse)
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
and enter your email address and a password(_*_) and you will get
your very own EC2 instance and a URL to RStudio Server
(and possibly shellinabox) on that instance. If you forget
your URL, you can go back to the app and it will tell you
your url.

_*_ = The password should be written down on the whiteboard
in the room where the course is taking place. This ensures
that only legitimate course attendees can register.

When the course ends, the app will terminate all instances.

Before this app existed, we would tediously print out slips of
paper with the urls and pass them out, and this involved
typing and making mistakes.

<a name="hosting"></a>
## Hosting and Administration

The app is hosted on an AWS instance called `courses.bioconductor.org`.

To administer it:

    ssh www-data@courses.bioconductor.org
    cd app

Your public key should be installed there, if not, please ask.

The app code lives in [https://github.com/Bioconductor/coursehelper](https://github.com/Bioconductor/coursehelper).

It is checked out in `www-data`'s  home directory, in
`~/app`.

The Ruby dependencies of the app are declared in the
[Gemfile](Gemfile).

<a name="changes"></a>
### Deploying changes

It is not enough to simply do `git pull` on production. You also need to
`touch tmp/restart.txt` in order to tell rails to use the latest changes.

<a name="buildAMI"></a>
## Building or Updating a course AMI 

This is going to assume that instead of directly modifying the existing course AMI that the desired result is to clone the AMI, update it, and add the new `ami_id` to the course. 
**Remember:** This process may be iterated a number of times depending on how
materials evolve or are updated.  It is important to always de-register (delete)
intermediate AMIs and terminate intermediate Instances. When the course
completes, terminate Instances, de-register AMIs, and delete any AMI snapshots
from the course.  

<a name="launchAMI"></a>
#### 1. Launch Existing AMI Of Interest

Log on to the AWS Management Console at:

`https://aws.amazon.com/console` 

1. Select EC2 (Virtual Servers in the Cloud). 
2. On the left tool bar, under Images, select AMIs.  
3. Launch the AMI of Interest. Make sure you have an AMI with the appropriate versions of R and Bioconductor. (See [Bioconductor AMIs](http://bioconductor.org/help/bioconductor-cloud-ami/#ami_ids)).
**Note:** Before launching, you should have an idea of the [InstanceType](https://aws.amazon.com/ec2/instance-types/) and generally you will want to have a [key pair set up](http://bioconductor.org/help/bioconductor-cloud-ami/#first-time-steps).
  
  \>Follow the prompts and after each step select `Next: ...` in the lower right corner
  
    1. Choose instance type
    2. Configure Instances. This section is generally okay as is. 
    3. Storage. This section is generally okay as is. 
       (For large conferences you may have to increase the storage)
    4. Tag Instance. Select a Name and Value for the instance.  
       Generally a good practice to also include the date: YearMonthDayTime. 
       If utilizing similar naming to previous AMI, it acts as an internal time stamp.
    5. Security. Under `Assign a security group:` choose `Select an existing security group`  
       Especially when setting up for a course or workshop, Select the following items:  
         1. name: `http-to-the-world` description: `port 80 open to world` (this is needed by rstudio)
         2. name: `ssh` description: `ips that are allowed to ssh to instances`
    6. Review and Launch.  
       Generally, launch with existing key pair. 
       You should have access to the private key associated with the public key pair selected.  
4. Click on the instance id that appears when launching 
5. Copy the **IP** address 


Don't sign out of the AWS console; we will be returning.  

<a name="updateInst"></a>
#### 2. Update New Instance 

Now that an instance has been created, we will use a terminal to update the information on that instance. 

1. Open a terminal 
2. ssh into the instance:  
   ssh -i \<keypair\> ubuntu\@**IP**  
   The \<keypair\> should be the private key matching to the key pair used when launching in the previous section and the **IP** is the copied **IP** address from step 5 of the previous section
3. Update the information as necessary.  
    e.g. clone course material, cd into a course directory and update, if necessary build and install course packages
4. Make sure all R packages are updated.  
    1. `R`
    2. `biocLite()` 
    3. `q()`  Do not save workspace!!* 
5. `clean_ami`
6. Exit the ssh instance.
7. Exit the terminal.

\* **Note:** If you save the workspace, all rstudio sessions launched with this AMI will have that saved workspaced. In generally it is a better practice to have a clean rstudio session by not saving the workspace and loading libraries and objects as needed when utilizing the AMI.  

<a name="cloneNclean"></a>
#### 3. Clone and Clean Up 

Now we must go back to the AWS console. 

1. On the left tool bar, under Instances, select Instances
2. Select the newly made instance 
3. Under Actions, Under Instance State, select `Stop`
4. Once the instance State shows that it is stopped,  
   Under Actions, Under Image, select `Create Image`  
   Follow prompt:  
     Image Name (Best practice is to include time stamp: YearMonthDayTime)  
     Create Image  
     Close  
5. On the left tool bar, under Images, select AMIs
6. What until the New AMI is done being created, and shows a Status of available. Then copy the `AMI ID` field for that new AMI. If updating a previously existing course, this `ami_id` should be used when [Updating a course](#updateCourse)
7. On the left tool bar, go back to Instances, Instances 
8. Select the newly created instance
9. (optional) Under Actions, Under Instance State, select `Terminate`. If you think you will run the instance again you can leave the instance in a `Stop` state instead of terminating but it is not recommended to leave intermediate AMIs and instances, for cost and space efficiency. You can also restart the instance for testing purposes (see below)

<a name="testR"></a>
#### 4. Testing (optional)

It is not a bad idea to test the AMI created to make sure your rstudio has everything anticipated.  However, be mindful of how many times you do this as there may be a cost involved. 

To test an rstudio session there are two options: 

1. See the previous section on [Launching Existing AMI of Interest](#launchAMI). Once you have the **IP** address, you can copy and paste that **IP** address into a web browser. It should open an rstudio session. 
2. Alternately, if you still have an instance of the AMI created, you can also go to Instances, Under Instances in the left tool bar and click on the newly created instance. If the instance is in an instant state of `stopped`, go under Actions, under Instant State, and select `Start`. On the bottom of the page there is information about the instance. The **IP** address listed can be copied in a web browser to launch the rstudio session. Don't forget to stop your instance when you are finished.       

<a name="initCourse"></a>
## Initializing courses.bioconductor.org

Because of space and cost, we do not leave the courses.bioconductor.org AMI running. 
It therefore will have to be restarted and initialized with a new elastic IP address. 

In the AWS Management Console:

1. On the left tool bar, under Instances, select Instances
2. Select the Instance names courses.bioconductor.org
3. Under Actions, Under Instance State, select `Start` and `Yes, Start`

Now a new elastic **IP** needs to be created: 

1. On the left tool bar, under Network & Security, select Elastic IPs
2. Under Actions, Allocate New Addesss. Change the EIP used to `VPC` and select `Yes, Allocate`
3. It should give you a confirmation window. In that window select: `View Elastic IP`
4. With the new Elasic IP Address selected, Under Actions, select `Associate Address`
5. In Instancee, start typing courses.bioconductor.org and select the appropriate entry, and Click `Associate`
6. Make note of the **IP** address

Now update courses.bioconductor.org **IP**:

1. At the top of the AWS Management Console, Select Services, and go to `Route 53`
2. Click on `Hosted Zones` under DNS management
3. Click on `bioconductor.org` under Domain Name
4. Find and select `courses.bioconductor.org`
5. In the window to the right, In the Value section, Delete the listed IP and enter the newly created elastic **IP** address. 
6. Change TTL (Seconds): to 0
7. Select `Save Record Set`

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

Again, assuming you are on courses.bioconductor.org:

    ssh www-data@courses.bioconductor.org
    cd app

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

Again, assuming you are on courses.bioconductor.org:

    ssh www-data@courses.bioconductor.org
    cd app

Run the console:

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

It is important when the course completes to: terminate Instances, de-register AMIs, and delete any AMI snapshots
from the course.  


<a name="postMaterials"></a>
## Post course materials

Post the course AMI and any related materials to the web site following instructions here:

https://github.com/Bioconductor/bioconductor.org/blob/master/README.md#adding-course-material-to-the-spreadsheet
