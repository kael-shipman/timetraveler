TimeTraveler Backup Utility
========================================================

Timetraveler is an rsync-based backup utility that attempts to make creating and managing incremental backups easy. High among its design goals is ease of use by end users. To this end, it is based on a simple, user-defined config file that controls what file tree is backed up, where backups are stored, how often backups happen, and how and when to clean up old backups.

It works by using rsync to copy the source directory into a date-stamped subdirectory of the backups directory. After the first backup, it creates a symlink called `latest` that it uses to create further backups incrementally using rsync's `--link-dest` option. (Of course, this symlink always points to the latest backup.)

For safety, it then removes write permissions for all files and directories under the backups directory.


## Installation

Like most applications that you run on your file system, timetraveler should be installed via whatever package manager is used for your OS. Currently, Debian-based distros are the only ones that have packages available. Packages can be found attached to the github releases, though I'm also hoping to make them available via a personal public package archive soon.

If no package is available for your OS, or if your OS doesn't use a package manager, you can also install timetraveler by dropping the `src` directory from this repo anywhere on your system. You can then either symlink the main `timetraveler` command into your path, use `update-alternatives` to do the same, or just execute it locally. All of those approaches _should_ work. Finally, if you want regular auto-scanning of your config file, you can install the systemd files from `peripheral` into `/etc/systemd/system/` and enable the timer using `sudo systemctl enable --now timetraveler-scan-config.service` (something the packages do automatically, where applicable).


## Usage

Timetraveler takes a config-file approach to backups. On install (via packages), it will run `timetraveler scan-config`, which checks the config directory (`$XDG_CONFIG_HOME/timetraveler/config`, which defaults to `$HOME/.config/timetraveler/config`) and creates, updates, or deletes any systemd user unit files as necessary. It also installs a systemd system timer unit to run `scan-config` once daily to pick up new changes for all users, though you can also run the command yourself after config updates.

To create an automatic backup routine for one or more file trees in your system, all you have to do is create the above-mentioned config file, in which you'll maintain one or more backup profiles. Each profile must have at a minimum a source directory and a destination directory. All other configuration is optional.

Config files are written in json (and eventually [hjson](https://hjson.org), when I figure out how to transform hjson into json in bash or C). Sample config might look like this:

```hjson
{
    backups: {
        my-full-system-backup: {
            source: /path/to/source
            target: /path/to/backup-dir
            frequency: *-*-* 00:00 // Every night at midnight
            retention: all // Don't delete any backups
        }
    }
}
```

(See [Config Option Details](#config-option-details) below for more config options and how to use them.)

As noted above, backups typically run automatically (though you can disable this by passing the "never" keyword to the frequency argument). However, they may also be initiated directly via `timetraveler backup [profile name]`.

### Manually Running Commands

Timetraveler can work just fine without timers, too. You'll still need a config file, but once you've got one you can simply run the backup command yourself on demand:

```sh
timetraveler backup [profile-name]
```

If you'd like to install timers to run your backups regularly, you can just run `timetraveler scan-config`.


## Config Option Details

Following is the full list of config options that timetraveler recognizes:

* `backups` object (required) -- an object containing named profiles representing one or more backup configurations. Keys of this object should be the name of the profile, and the value should be an object with the following properties
    * `source` string (required) -- rsync-compatible remote or local path to the directory you'd like to make backups of.
    * `target` string (required) -- rsync-compatible remote or local path to the directory where you'd like to keep all of your versioned backups for this profile.
    * `frequency` string (optional, defaults to `*-*-* 00:00`) -- 'never' (for manual backups only), or a systemd-compatible timer specification for regular automated backups (see [`systemd` calendar event syntax](https://wiki.archlinux.org/index.php/Systemd/Timers#Realtime_timer) for more info)
    * `retention` string (optional, defaults to `all`) -- How old backups should be managed (may be profile-specific or global or both)
    * `rsync-options` string (optional) -- A string of extra options to append to the rsync command (may be profile-specific or global or both)
* `rsync-command` string (optional) -- The full path the rsync command to use, if not on standard path

----------------------------------------------------------------------------------------------


## Aspirational Features

While I think the following features are important for a complete backup solution, they're also more complicated and will require a lot more work to implement. I'm leaving them as aspirational feeatures for now and will get to them when I have time.

### File Access Utilities

Each incremental backup is simply a full copy of your files, but using hardlinks to prior backups when possible to economize on space.

Since it can get confusing and cumbersome to find files among hundreds or even thousands of such backups, timetraveler provides facilities for accessing backups. In particular, it offers search capabilities that allow you to find files or directories by name or even by file contents. When listing files or directories, timetraveler will show you all _changed_ versions of a file and allow you to view the file or copy it to a temporary location for manipulation or further inspection. Here's an example of timetraveler's search:

```sh
$ timetraveler find my-backup /some/search/root -type f -name my-file.txt
$
$ timetraveler found 2 files:
$
$   /path/to/my-backup/some/search/root/subdir/my-file.txt
$
$     1. 2018-03-20 14:55:32
$     2. 2018-02-01 09:36:10
$     3. 2017-09-12 16:20:22
$
$   /path/to/my-backup/some/search/root/new-path/my-file.txt
$
$     4. 2018-04-20 00:30:33
$
$ What would you like to do?
$ 
$   1. Open a file
$   2. Copy a file to another location
$
$ : 2
$
$ Copying file #2 (2018-02-01 09:36:10). Where would you like to copy it?
$
$ : /tmp/
$
$ ....
$
```

In this case, timetraveler has found two paths that match the criteria. You'll notice that for the first path, timetraveler has also revealed three distinct revisions of the file. In this example, the user has selected to copy the second revision of the first file found to the `/tmp` directory....

Timetraveler also allows you to search files for content. In that case, it wraps grep, but offers essentially the same interface as above.

