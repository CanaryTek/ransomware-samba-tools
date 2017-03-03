# Ransomware samba tools

Tools to help stop ransomware infections in a samba fileserver

## The need

Ransomware has became **THE** main security concern, and it will get (much) worse

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

**DISCLAIMER:** What we do with this tools is not new, these technics have been used in windows server for a long time. Even the idea of using samba audit is not ours, we first saw it in a german magazine( https://www.heise.de/security/artikel/Erpressungs-Trojaner-wie-Locky-aussperren-3120956.html)

Right now we have two types of detections:

  * Known ransomware: we monitor the logs for known ransomware extensions and filenames. The drawback of this approach is that it only detects known ransomware
  * Honeypots: we setup a honeypot on every shared folder with names such that an enumeration from a windows client will try to infect that folder first. And we monitor files in that honeypot folder

### Known Ransomware

We use two regular expresions for detecting known ransomware extensions and file names. They are defined in the fail2ban samba-filter.conf file

**NOTE:** Some of these file names are pretty common, so this type of detection may cause false positives. You may need to modify the regex to avoid false positives

### Honeypots

The idea with the honeypots is creating a folder on each shared folder that will be the first processed in a windows file enumeration. In ths honeypot we create some "bait" files and monitor them for changes.

Since Ransomware is becoming smarter, we create different file types with different sizes. We should avoid "suspicious" file names like "honeypot" or "bailt". To avoid false positives, what we do is include random strings in the bait filenames, and monitor for that strings.

Some examples of good filenames could be:

  * Accounting-ooKoich3.xls 
  * Memorandum-Be1their.odt

And we would monitor the samba accounting logs for the strings: ooKoich3 and Be1their

### Installation

#### Setup samba for full audit

In the samba dir there is a sample smb.conf file for reference

  * Configure full accounting in samba adding the following entries to the [global] section

    # Anti-ransom
    full_audit: failure = none
    full_audit: success = pwrite write rename
    full_audit: prefix = IP=%I | USER=%u | MACHINE=%m | VOLUME=%S
    full_audit: facility = local7
    full_audit: priority = NOTICE

  * Add the following entry to all shared folders 

    # Option to enable audit for ransomware detection
    vfs objects = full_audit

#### Install and setup fail2ban

The sample fail2ban files are in the fail2ban directory

  * Install fail2ban
  * Copy and adjust the samba-jail.conf to the fail2ban jails directory. You may need to change the bantime and notifications email
  * Copy and adjust the samba-filter.conf to the fail2ban filter directory. Yoy may need to adjust the following parameters
    * `__honeypot_files_re`: Regex matching the bait files names. MAKE SURE YOU SET THIS CORRECLY
    * `__known_ransom_extensions_re`= Known ransomware extensions. You may add eny new extensions, or remove one to avoid false positives
    * `__known_ransom_files_re`= Known ransomware files. You may add eny new extensions, or remove one to avoid false positives

#### Setup honeypots

In the tools directory there is a script to simplify the honeypot setup on all samba shared folders

The `setup_samba_honeypots.sh` script gets the shared folder location from samba config and creates a honeypot dir on each one. It also copies all files found in the bait-dir to these honeypot directories
You can add any file to the bait-files directory, and they will be copied to all honeypots. Just remember to add a random string to the file name and adding that string to the `__honeypot_files_re`

The `setup_samba_honeypots.sh` script should be run in a crontab (i.e. hourly) to make sure you have honepots in any share you may create. It is also needed to add the bait files again after an infection, because most ransomware will rename the files and any further infection will not be detected

## TODO

There are a lot of room for improvement:

  * Detect file changes with hashes
  * Detect when a client is changing **A LOT** of files in a short period of time (the problem is that the thresholds would depend on the server load)
