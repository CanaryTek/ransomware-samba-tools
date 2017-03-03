# Ransomware samba tools

Tools to help stop ransomware infections in a samba fileserver

## The need

Ransomware has became a main security concern, and it will get (much) worse

Even though Ransomware infects mainly windows machines, it can also encrypt files located in shared folders un fileservers.
There are a **A LOT** of documentation and tools to stop infection at a fileserver level with Windows fileservers (with FSRM and other tools), but I haven't found many documentation to do the same with a samba fileserver

## What we can do

The first thing we need to do is:

  * Backup
  * Backup
  * Backup
  * Hourly snapshots

And **ONLY** when we already have working backups (and optionaly, hourly snapshots), we can try to detect the ransomware infection at an early stage and stop it

## How it works

Basically, what it does is enable full audit in Samba server and monitor the logs with fail2ban. When it detect a "suspicious" change, it bans the client IP.

Right now we have two types of detections:

  * Known ransomware: we monitor the logs for known ransomware extensions and filenames. The drawback of this approach is that it only detects known ransomware
  * Honeypots: we setup a honeypot on every shared folder with names such that an enumeration from a windows client will try to infect that folder first. And we monitor files in that honeypot folder

## TODO

There are a lot of room for improvement:

  * Create more complex honeypots: New ransomware is becoming smarter, and try to avoid honeypots
    * We could create honeypot folders with some "credible" files (office, pdf, etc)
  * Detect file changes with hashes
  * Detect when a client is changing **A LOT** of files in a short period of time (the problem is that the thresholds would depend on the server load)
