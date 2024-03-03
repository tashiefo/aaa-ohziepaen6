# Ansible Advanced Submission

This is an assignment submission for the [Ansible Advanced](https://www.udemy.com/course/learn-ansible-advanced/) course on [Udemy](https://www.udemy.com/) offered by [KodeKloud](https://www.kodekloud.com/).  If none of these sound familiar, this will likely not be of interest to you.

## Environment

This solution was developed on macOS.  Linux should also work, but it is untested.

Software packages required are:

* VirtualBox - to provide a test environment
* Vagrant - to provision VirtualBox
* The vbguest plugin for vagrant (install with `vagrant plugin install vagrant-vbguest`).
* Ansible - of course

Python3 and Ruby are dependencies of Ansible and Vagrant, respectively, and will generally be installed by most package managers when you install the above.

### If vbguest is a problem for you

The vbguest plugin is optional; if it gives you problems, or you'd just rather skip that, comment the line mentioning vbguest out in the Vagrant file, but be sure to install the latest VirtualBox Guest Additions manually.  This is required to pull full IP address information from the virtual machines using the virtualbox inventory plugin.

## Initial setup

This section prepares the virtual machines and the basic environment.

1. Ensure the vbguest plugin is installed, if it isn't already:  `vagrant plugin install vagrant-vbguest`
2. Create the virtual machines:  `vagrant up`
3. You may need to reboot the VMs as a result of Guest Additions installation:  `vagrant reload`
4. Install community roles: `ansible-galaxy install -r requirements.yml` (you can append `-p ./roles` to the command if you prefer)
5. Ensure you can ssh to each VM using your ssh key.  You can do this manually, or run `ansible-playbook -i vbox.yml --vault-pass-file=vaultPassword.txt setup-ssh.yml`.  Note that this runbook will try to remove IP addresses and hostnames matching the created VMs from your ~/.ssh/known_hosts file to avoid complications.
6. Edit group_vars/all.yml and fill in email addresses of your choice, and your local mailhost.  Note that the play assumes that authentication is not required.

## Running the playbook

1.  `ansible-playbook -i vbox.yml --vault-pass-file=vaultPassword.txt playbook.yml`

## Cleanup

Cleanup procedure is:

1. Remove VMs from hosts: `ansible-playbook -i vbox.yml --vault-pass-file=vaultPassword.txt setup-ssh.yml --extra-vars cleanup=true`
2. Remove VMs: `vagrant destroy`
3. remove added roles from ~/.ansible/roles/

## My solution

### Support files
* group_vars:
  * all.yml - contains email parameters
  * db_servers.yml, lb_servers.yml, web_servers.yml - contains user, password, and database connection information for each group
* roles:
  * flask_web: A role close to the one produced in the course.  The target directory's a variable, declared in defaults, and has been moved to /opt/app to allow for other usages of /opt, such as guest additions.  A task to kill any currently running instances of flask has been added.
  * mysql_db: Also close to the one produced in the course, however, the configuration is modified to open port 3306, and a handler is used to restart the service in the event the configuration file is touched as a result of this modification.
  * python:  Also close to the one produced in the course, used without modifications.
* playbook.yml: the main playbook.
* README.md:  This file.
* requirements.yml:  external roles used.  Loads nginx roles.
* setup-ssh.yml:  Initial setup and cleanup of ssh key stuff.  Pass `--extra-vars cleanup=true` to just run a cleanup pass.
* Vagrantfile:  Defines virtual machines.  Edit to adjust the number of machines created and the like, or to remove the dependency on the vbguest plugin (if you want to install the guest additions manually).
* vaultPassword.txt:  The password for the ansible-vault files used in group_vars.  Contains the same password used throughout the course.
* vbox.yml:  The dynamic inventory definition.  This uses the virtualbox plugin, which pulls host and IP information from VirtualBox.  This mechanism is why an up-to-date version of Guest Additions is required, as IP addresses are not otherwise dynamically available.  Hosts are sorted into groups based on simple hostname rules.

### The Playbook

#### 1. Make sure required variables are set

This section checks to make sure email parameters are set in advance, to avoid having to go through the whole run, only to find out at the end something's missing.

Uses debug for feedback, and the Jinja2 mandatory filter to perform the actual checks.

#### 2.  Deploy database server

As in the course, simply deploys Python and a database server to the db_server group.  It's much the same as the course, but opens the port for external connections, and allows the user to connect from any other host, as well as localhost.

The database server is "ansmaster" in the VMs built.

#### 3.  Deploy a web application

Again, as in the course, deploys Python, Flask, and the application to a location defined by a variable, by default /opt/app.

The role now kills any existing copies of flask to ensure that an update isn't ignored, and automatically pulls from the original Git repository's master branch.  Changes should be overwritten.  Environment variables are now provided in an environment section rather than on the command line.

A few more environment variables are being set than may be paid attention to by the app, depending on how configuration works.  This is for future-proofing and was probably unnecessary on my part, but I had trouble resisting.

The web servers are "answeb*" in the VMs built.

#### 4.  Deploy a load balancer

This uses the official roles published by Nginx, Inc. to deploy and configure the open source version of Nginx.

This happens in two discrete tasks.  The installation portion is straightforward.  The configuration is more involved, and requires quite an entertaining set of complex variable definitions.

Because I wanted to build the backend to accommodate any number of backends, I couldn't define the backend servers statically in the required list, nor could I use Jinja2's for loop to build YAML itself.  This is something that SaltStack does allow, since it renders the entire file with Jinja2 before parsing it as YAML, but it is likely a tradeoff of sorts to allow flexibility in how variables are defined.

My solution was to use a block of text, and a for loop inside that, to build a JSON structure that I could then feed to the desired list under the upstream definition, which points nginx's backend to the two flask servers running on port 5000.

A round-robin strategy is used by default to make validation less complicated, but you'd probably want something else in a production server.

A server is also defined on port 80, with its root document defined to point at http://upstr/ (the upstream definition above).

SSL/TLS is avoided in this setup for simplicity's sake, another thing you'd want to worry about in a production environment.

#### 5.  Completion notification

This sends an email on completion.  From (sender), To, and mail relay (host) parameters are set via variables.  The body is defined in a text block.

In case more than one load balancer is built, this is handled by building a list of links using a for loop in yet another variable, which is included in the body of the email.  That said, having multiple load balancers is only handled in this email section, and not the rest of the playbook.  Handling for multiple sites or an HA load balancer setup would require rework of, at least, the Nginx section, and is beyond the scope of the project.

## Conclusion

That's it.  Please contact me with any questions you may have.
