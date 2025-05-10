# Useful Scripts

A small collection of bash- and python-based utilities I use regularly.

## Prerequisites

- **Bash** (for `.sh` scripts)
- **tree** (optional, for `dump_dir.sh`’s directory-tree display)
- **SSH keys** configured (for `rsync_pyproj.sh`)

## dump_dir.sh

Dumps a full directory tree **and** all text file contents into a single output file.

*Inspired by [uithib](https://uithub.com/). Provides similar functionality but for local projects.*

```bash
dump_dir.sh [options]
````

**Options:**

* `-d, --dir DIRECTORY`
  Directory to dump (default: current directory)
* `-o, --output FILE`
  Output file path (default: `dump.txt`)
* `-x, --exclude PATTERN`
  Additional file or directory patterns to exclude (repeatable)
* `-h, --help`
  Show usage

**Example:**

```bash
./dump_dir.sh -d ~/Projects -o myproj_dump.txt \
  -x 'node_modules' -x '*.log'
```

---

## rsync\_pyproj.sh

Sync a local Python project to a remote machine over SSH with sensible defaults and easy excludes.

```bash
rsync_pyproj.sh -h HOST -r REMOTE_DIR [options]
```

**Required:**

* `-h HOST`        SSH host or alias (from `~/.ssh/config`)
* `-r REMOTE_DIR`  Target directory on remote

**Options:**

* `-l LOCAL_DIR`   Local dir to sync (default: current)
* `-u USER`        Remote SSH user override
* `-k`             Keep `.git/` (do NOT exclude)
* `-d`             Delete extras on remote
* `-e PATTERN`     Extra `--exclude=PATTERN` (repeatable)
* `-h, --help`     Show usage

**Example:**

```bash
./rsync_pyproj.sh -h myserver -r ~/projects/app \
  -e '*.tmp' -d
```
