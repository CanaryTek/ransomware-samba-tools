# Ransomware samba tools

Tools to help stop ransomware infections in a samba fileserver

## The need

Ransomware has became the main security concern, and it will get (much) worse

Even though ransomware infects mainly windows machines, it can also encrypt files located in shared folders in fileservers.
There is a lot of documentation and tools to stop infection at a fileserver level with Windows fileservers (with FSRM and other tools), but I haven't found many documentation to do the same with a samba fileserver

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

```
    # Anti-ransom
    full_audit: failure = none
    full_audit: success = pwrite write rename
    full_audit: prefix = IP=%I | USER=%u | MACHINE=%m | VOLUME=%S
    full_audit: facility = local7
    full_audit: priority = NOTICE
```

  * Add the following entry to all shared folders 

```
    # Option to enable audit for ransomware detection
    vfs objects = full_audit
```

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

The `setup_samba_honeypots.sh` script gets the shared folder location from samba config and creates a honeypot dir on each one. It also copies all files found in the bait-dir to these honeypot directories, changing its names to simplify detection

You should adjust the following settings in the script:

  * `bait_string`: Change it to something different. If everybody used the sample one it would be easy to avoid detection ;)
  * Rememeber to add the same string used in this script to the ``__honeypot_files_re`` in the fail2ban samba-filter.conf file
  * `bait_files_dir`: Directory with bait files to copy to the honeypots. More on this later
  * `honey_folder`: Name of the honeypot directory. It should start with low ASCII characters (\_,\$, etc) si it is processed by the ransomware first

After changing the previous settings, drop some real files in the `$bait_files_dir` directory. We need to have some real data here to keep the ransomware busy so fail2ban has time to detect and block before the ransomware starts encrypting real data

Once you have everything setup, run the `setup_samba_honeypots.sh` to setup the honeypots. You should also run it regularly in a cron job (i.e. every 30 min) because if we get an infection, files will probably get renamed and it won't detect further infections.

## Test

We have made some tests with **real** ransomware. We added then real PDF files to the bait-files dir. The setup script added the detection string, so before the infection this was our honeypot:

```
0_Memorandum-ShahZeZ6.odt
0_Memorandum-ShahZeZ6.pdf
DO_NOT_TOUCH-ShahZeZ6.txt
Factura-4742402860898-ShahZeZ6.pdf
Factura-4742403791695-ShahZeZ6.pdf
Factura-4742403984945-ShahZeZ6.pdf
Factura-4742404036744-ShahZeZ6.pdf
Factura-4742404110745-ShahZeZ6.pdf
Factura-4742404111289-ShahZeZ6.pdf
Factura-4742404111320-ShahZeZ6.pdf
Factura-4742404199285-ShahZeZ6.pdf
Factura-4742404240625-ShahZeZ6.pdf
Factura-4742404356934-ShahZeZ6.pdf
```

Then we run a real ransomware, after a couple seconds fail2ban detected the infection and banned the IP. This is the log:

```
==> /var/log/messages <==
Mar  3 20:03:59 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|rename|ok|____Secret_Data____/0_Memorandum-ShahZeZ6.odt|____Secret_Data____/0_Memorandum-ShahZeZ6.odt.yvoter
Mar  3 20:03:59 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|pwrite|ok|____Secret_Data____/0_Memorandum-ShahZeZ6.odt.yvoter
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|rename|ok|____Secret_Data____/0_Memorandum-ShahZeZ6.pdf|____Secret_Data____/0_Memorandum-ShahZeZ6.pdf.yxucvd
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|pwrite|ok|____Secret_Data____/0_Memorandum-ShahZeZ6.pdf.yxucvd
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|rename|ok|____Secret_Data____/Factura-4742402860898-ShahZeZ6.pdf|____Secret_Data____/Factura-4742402860898-ShahZeZ6.pdf.rsdwas
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|pwrite|ok|____Secret_Data____/Factura-4742402860898-ShahZeZ6.pdf.rsdwas
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|rename|ok|____Secret_Data____/Factura-4742403791695-ShahZeZ6.pdf|____Secret_Data____/Factura-4742403791695-ShahZeZ6.pdf.ugyqfw
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|pwrite|ok|____Secret_Data____/Factura-4742403791695-ShahZeZ6.pdf.ugyqfw
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|rename|ok|____Secret_Data____/Factura-4742403984945-ShahZeZ6.pdf|____Secret_Data____/Factura-4742403984945-ShahZeZ6.pdf.urefkc
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|pwrite|ok|____Secret_Data____/Factura-4742403984945-ShahZeZ6.pdf.urefkc
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|rename|ok|____Secret_Data____/Factura-4742404036744-ShahZeZ6.pdf|____Secret_Data____/Factura-4742404036744-ShahZeZ6.pdf.ahdciw

==> /var/log/fail2ban.log <==
2017-03-03 20:04:00,498 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,504 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,506 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,507 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,508 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,509 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,511 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,512 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,514 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,515 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68
2017-03-03 20:04:00,516 fail2ban.filter         [7413]: INFO    [samba] Found 192.168.122.68

==> /var/log/messages <==
Mar  3 20:04:00 test smbd_audit: IP=192.168.122.68 | USER=test | MACHINE=ctk-pc | VOLUME=test|pwrite|ok|____Secret_Data____/Factura-4742404036744-ShahZeZ6.pdf.ahdciw

==> /var/log/fail2ban.log <==
2017-03-03 20:04:00,740 fail2ban.actions        [7413]: NOTICE  [samba] Ban 192.168.122.68
```

As we can see in the logs, the infected machine started encrypting files in our honeypot at 20:03:59 and fail2ban detected it and blocked the ip at 20:04:00, so the the ransomware only had 1 second to encrypt files in the server. If we have enough files in our honeypot, it won't get very far in just 1 second...

If we check the status of our honeypot, we see that we only had 6 files encrypted, si the "infection" was limited to our honeypot and no real riles where afected.

Not bad...

```
0_Memorandum-ShahZeZ6.odt.yvoter
0_Memorandum-ShahZeZ6.pdf.yxucvd
DO_NOT_TOUCH-ShahZeZ6.txt
Factura-4742402860898-ShahZeZ6.pdf.rsdwas
Factura-4742403791695-ShahZeZ6.pdf.ugyqfw
Factura-4742403984945-ShahZeZ6.pdf.urefkc
Factura-4742404036744-ShahZeZ6.pdf.ahdciw
Factura-4742404110745-ShahZeZ6.pdf
Factura-4742404111289-ShahZeZ6.pdf
Factura-4742404111320-ShahZeZ6.pdf
Factura-4742404199285-ShahZeZ6.pdf
Factura-4742404240625-ShahZeZ6.pdf
Factura-4742404356934-ShahZeZ6.pdf
```

## TODO

There are a lot of room for improvement:

  * Detect file changes with hashes
  * Detect when a client is changing **A LOT** of files in a short period of time (the problem is that the thresholds would depend on the server load)
