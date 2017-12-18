dns-update
==========

* dns-update - small dynamic DNS suite using SSH
* Copyright (C) 2014  Christian Garbs <mitch@cgarbs.de>
* Licensed under GNU GPL v3 (or later)
* Homepage: https://github.com/mmitch/dns-update

ABOUT
-----

This is a small suite to enable dynamic DNS updates from remote hosts.
It's my personal replacement for the not-free-any-more DynDNS service.
Clients use SSH to update their IP.  While this won't work with
J. Random Router that has a DynDNS client built in, it works on all of
my systems (they have the capabilites for scripts and SSH
connections), it's very easy to build and use and it provides the full
SSH possibilities of encryption and authentication - for free.


HOW TO INSTALL ON THE SERVER
----------------------------

1. Install a nameserver of your choice and serve a zone dedicated to
   your dynamical IPs.  You propably need a delegation for that zone
   from somewhere else.  All this is NOT handled in this howto.

   My setup works with nsd as nameserver but apart from "please reload
   the zonefile" there is no interaction with the nameserver, so it
   should be easily portable.

   The example configuration creates the zone `dynip.example.com` in
   the file `ZONEFILE=/home/dns-update/zones/dynip.example.com.zone`.
   In `/etc/nsd/nsd.conf`, the zone paragraph would look like this:

   ```
   zone:
           name: dynip.example.com
           zonefile: /home/dns-update/zones/dynip.example.com.zone
   ```


2. Create a new user for the sole purpose of handling the dynamic DNS
   updates.  This user needs a normal shell (`/bin/sh` should be
   enough - with `/bin/false`, the SSH forced commands won't run…), a
   home directory and SSH access (be sure to include him in
   AllowUsers/AllowGroups if you use them to restrict access via SSH).
   The password of the user can and should be disabled (either after
   configuration is finished or you'll have to use su(1) while
   configuring stuff).

   This repository is configured for a user `dns-update` with a home
   directory of `/home/dns-update`


3. Allow this new user to reload your nameserver configuration when a
   zonefile changes.
   
   My setup does this via sudo(8).  I created the file
   `/etc/sudoers.d/local-dns-update` which just contains the line
   `dns-update ALL =NOPASSWD: /bin/systemctl reload nsd`.  YMMV.


4. Clone this git repository RIGHT INTO the home directory of the
   dedicated user.  Log in as or su(1) to the user and do:

   ```
   $ git clone https://github.com/mmitch/dns-update.git /home/dns-update
   ```


5. Create a local branch (`git checkout -b local`).  Do your local
   configuration:

   * edit `.ssh/authorized_keys` (see notes in file)
   * edit the parameters on the top of `update-client` e.g. zone file
     name
   * edit `config/zonefile.input` to your needs (`§SERIAL§` will be
     replaced automatically)
   * edit the bottom part of `update-client` if you used a different
     sudo configuration than in this example

   Check in your changes (`git commit -a`).

   Fix the file permissions on `.ssh` and `.ssh/authorized_keys`?!
   TODO: watch what git is doing there and what can be done against it.
   
   (In case you're wondering why a non-functional `authorized_keys`
    file is part of this repository: That way it's automatically
    tracked in your local branch and you can't forget to git-add it.
    Also: inline help on first edit.)

6. Basically, you're ready to go now!



HOW TO UPDATE THE SERVER
------------------------


1. Log in/su(1) to user dns-update.

2. Switch git branch back to master (be sure to have no pending local
   changes):

   ```
   $ git checkout master
   ```

3. Get updates:

   ```
   $ get pull
   ```

4. Switch back to your local branch:

   ```
   $ git checkout local
   ```

5. Merge the updates.  It's best to do a rebase to keep a clean
   history (of course, using `merge` instead of `rebase` is also
   possible).  You might have to solve merge conflicts, be ready for
   that:
   
   ```
   $ git rebase master
   ```



LOGGING ON THE SERVER
---------------------

Your SSH server propably already logs to `/var/log/auth.log`.  There
you can find successful client logins as well as diagnostic error
messages when something goes wrong.



HOW TO INSTALL ON A CLIENT
--------------------------

- create local SSH key
- add pubkey to `.ssh/authorized_keys` on server
  - copy existing line
  - change hostname in `command=""` string
  - change public key
- to update, call `ssh -i /path/to/new/identity.pub dns-update@ns.example.com update-client <new.ip.add.ress>`
  - or use `auto` instead of the ip address to use the ssl source ip
    address automatically (useful if you're behind a router and don't
    know your outside IP, but want to send exactly this IP to the
    server)

- ppp-update-script not finished yet (but at least on Debian based
  distributions, you can simply write the `ssh` commandline
  (preferably with `auto`) into a new file under `/etc/ppp/ip-up.d`
  and you're set)
