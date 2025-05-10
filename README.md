# Useful Scripts

A small collection of bash-based utilities I use regularly.

## Prerequisites

* **Bash** (for `.sh` scripts)
* **tree** (optional, for `dump_dir.sh`’s directory-tree display)
* **SSH keys** configured (for `rsync_pyproj.sh` & `rsync_files.sh`)

---

## dump\_dir.sh

Dumps a directory tree **and** all text file contents into a single output file.

```bash
dump_dir.sh [options] <DIR> [OUTPUT_FILE]
```

* **DIR**: Directory to dump (default: current directory)
* **OUTPUT\_FILE**: Output file path (default: `~/dumps/<dir_name>_dump.txt`)

**Options:**

* `-e, --exclude PATTERN`
Additional file or directory patterns to exclude (repeatable).
* `-h, --help`
Show usage and exit.

**Behavior:**

* Defaults to writing the dump to `~/dumps/<basename_of_DIR>_dump.txt` (creates `~/dumps/` if needed).
* Errors out if the output file would reside inside the dumped directory.
* Applies all exclude patterns both to the tree display and text-file dumps.

**Example:**

```bash
# Dump ~/projects/myapp, excluding logs:
./dump_dir.sh -e 'logs/' ~/projects/myapp
# → writes to ~/dumps/myapp_dump.txt
```

---

## rsync\_pyproj.sh

Sync a local directory (e.g., a Python project) **to** or **from** a remote machine using sensible defaults.

```bash
rsync_pyproj.sh [options] <SRC> <DEST>
```

* One of `<SRC>` or `<DEST>` must be a remote endpoint (`[USER@]HOST:PATH/`).

**Options:**

* `-u USER`
Override remote SSH user.
* `-k`
Keep `.git/` (do **not** exclude it).
* `-d`
Delete extraneous files on destination (`--delete`).
* `-e PATTERN`
Extra `--exclude=PATTERN` (repeatable).
* `-h, --help`
Show usage and exit.

**Examples:**

```bash
# Push local → remote:
./rsync_pyproj.sh ./app/ myserver:~/projects/app/

# Pull remote → local, delete extras, exclude logs:
./rsync_pyproj.sh -d -e 'logs/' myserver:~/projects/app/ ./local_app/
```

---

## rsync\_files.sh

A general-purpose `rsync` wrapper to sync any two endpoints (local ↔ remote) with easy excludes and optional deletion.

```bash
rsync_files.sh [options] <SRC> <DEST>
```

* `<SRC>` and `<DEST>` can both be local paths or one can be a remote endpoint (`[USER@]HOST:PATH/`).

**Options:**

* `-e, --exclude PATTERN`
Add an `--exclude=PATTERN` (repeatable).
* `-d, --delete`
Enable `--delete` to remove extraneous files on the destination.
* `-h, --help`
Show usage and exit.

**Examples:**

```bash
# Upload local → remote, ignoring .tmp files:
./rsync_files.sh -e '*.tmp' ./site/ user@server:/var/www/site/

# Download remote → local, mirror-deleting extras:
./rsync_files.sh -d user@server:/var/logs/ ./logs/
```
