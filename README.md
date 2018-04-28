TimeTraveler Backup Utility
========================================================

>
> **NOTE:** This readme describes my _aspirations_ for this project, not a finished product. Writing readmes helps me more fully understand and specify a project before I embark on actually creating it, so that's why this exists.
>
> At the time of this writing, `timetraveler` is a simple shell script that lightly wraps `rsync` and adds a few little tricks. My intention is that the interface remain constant as I build out the project and add the aspirational funtionality.
>
> Pull requests welcome....
>

Timetraveler is an rsync-based backup utility that attempts to make creating and managing incremental backups easy. High among its design goals is ease of use by end users. To this end, it is based on a simple, user-defined config file that controls what file tree is backed up, where backups are stored, how often backups happen, and how and when to clean up old backups.

It works by using rsync to copy the source directory into a date-stamped subdirectory of the backups directory. After the first backup, it creates a symlink called `latest` that it uses to create further backups incrementally using rsync's `--link-dest` option. (Of course, this symlink always points to the latest backup.)

For safety, it then removes write permissions for all files and directories under the backups directory.


## Installation

Like most applications that you run on your file system, timetraveler should be installed via whatever package manager is used for your OS. If no package is available for your OS, or if your OS doesn't use a package manager, you can also just download the executable from [github](https://github.com/kael-shipman/timetraveler/releases) or compile it for your system.


## Usage

Timetraveler takes a config-file approach to backups. On install, it will run `timetraveler scan-config`, which checks the config directory (`$XDG_CONFIG_HOME/timetraveler/config`, which defaults to `$HOME/.config/timetraveler/config`) and creates, updates, or deletes any systemd timer unit files as necessary.

To create an automatic backup routine, all you have to do is create a config file, `~/.config/timetraveler/config`, in which you'll maintain one or more backup profiles. Each profile must have at a minimum a source directory, a destination directory, backup frequency (defined in [`systemd` calendar event syntax](https://wiki.archlinux.org/index.php/Systemd/Timers)), and retention policy.

Sample config might look like this:

```hjson
{
    backups: {
        my-full-system-backup: {
            source-dir: /path/to/source
            backup-dir: /path/to/backup-dir
            frequency: *-*-* 00:00 // Every night at midnight
            retention: all // Don't delete any backups
        }
    }
}
```

(See [Config Option Details](#config-option-details) below for more config options and how to use them.)

As noted above, backups typically run automatically (though you can disable this -- see config). However, they may also be initiated directly via `timetraveler backup [profile name]`.

### File Access Utilities

Each incremental backup is simply a full copy of your files, but using hardlinks to prior backups when possible to economize on space.

Since it can get confusing and cumbersome to find files among hundreds or even thousands of backups, timetraveler provides facilities for accessing backups. In particular, it offers search capabilities that allow you to find files or directories by name or even by file contents. When listing files or directories, timetraveler will show you all _changed_ versions of a file and allow you to view the file or copy it to a temporary location for manipulation or further inspection. Here's an example of timetraveler's search:

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
```

### Additional Config Options

In addition to the basic config options outlined above, timetraveler also recognizes the following profile-specific config options:

* `rsync-options` -- A string of extra options to append to the rsync command


## Implementation Details

On backup, the application should do the following:

* Create the backup directory, if not exists
* If a `latest` symlink exists, backup runs `rsync -aHAXx --link-dest=/path/to/backup/latest /path/to/source /path/to/backup/source-[date]`
* If no `latest` symlink exists, backup runs above command but without the `--link-dest` parameter
* After successful copy, backup creates symlink from `latest` to the most recently created backup


