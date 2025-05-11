# Useful Scripts

A small collection of bash‑ and Python‑based utilities I use regularly.

## Prerequisites

- **Bash** (for `.sh` scripts)
- **tree** (optional, for `dump_dir.sh`’s directory‑tree display)
- **SSH keys** configured (for `rsync_pyproj.sh` & `rsync_files.sh`)
- **Python 3** with `huggingface-hub` installed (for `hf_download.py`):
  ```bash
  pip install huggingface-hub
  ```

---

## dump_dir.sh

Dumps a directory tree **and** all text file contents into a single output file.

```bash
dump_dir.sh [options] <DIR> [OUTPUT_FILE]
```

- **DIR**: Directory to dump (default: current directory)
- **OUTPUT_FILE**: Output file path (default: `~/dumps/<dir_name>_dump.txt`)

**Options:**

- `-e, --exclude PATTERN`
Additional file or directory patterns to exclude (repeatable).
- `-h, --help`
Show usage and exit.

**Behavior:**

- Defaults to writing the dump to `~/dumps/<basename_of_DIR>_dump.txt` (creates `~/dumps/` if needed).
- Errors out if the output file would reside inside the dumped directory.
- Applies all exclude patterns both to the tree display and text‑file dumps.

**Example:**

```bash
# Dump ~/projects/myapp, excluding logs:
./dump_dir.sh -e 'logs/' ~/projects/myapp
# → writes to ~/dumps/myapp_dump.txt
```

---

## rsync_pyproj.sh

Sync a local directory (e.g., a Python project) **to** or **from** a remote machine using sensible defaults.

```bash
rsync_pyproj.sh [options] <SRC> <DEST>
```

- One of `<SRC>` or `<DEST>` must be a remote endpoint (`[USER@]HOST:PATH/`).

**Options:**

- `-u USER`
Override remote SSH user.
- `-k`
Keep `.git/` (do **not** exclude it).
- `-d`
Delete extraneous files on destination (`--delete`).
- `-e PATTERN`
Extra `--exclude=PATTERN` (repeatable).
- `-h, --help`
Show usage and exit.

**Examples:**

```bash
# Push local → remote:
./rsync_pyproj.sh ./app/ myserver:~/projects/app/

# Pull remote → local, delete extras, exclude logs:
./rsync_pyproj.sh -d -e 'logs/' myserver:~/projects/app/ ./local_app/
```

---

## rsync_files.sh

A general-purpose `rsync` wrapper to sync any combination of files or directories to/from a destination with easy excludes and optional deletion.

```bash
rsync_files.sh [options] <SRC1> [<SRC2> ...] <DEST>
```

- `<SRC*>` can be local paths or remote endpoints (`[USER@]HOST:PATH/`).
- `<DEST>` is the last argument (local or remote).

**Options:**

- `-e, --exclude PATTERN`
Add an `--exclude=PATTERN` (repeatable).
- `-d, --delete`
Enable `--delete` to remove extraneous files on DEST.
- `-h, --help`
Show usage and exit.

**Examples:**

```bash
# Upload multiple files to remote:
./rsync_files.sh -e '*.tmp' ./a.txt ./b.txt user@server:/path/

# Download multiple logs:
./rsync_files.sh -d user@server:/var/log/foo.log user@server:/var/log/bar.log ~/logs/
```

---

## hf_download.py

Download entire Hugging Face repos (models or datasets) via snapshot or individual-file mode.

```bash
hf_download.py [options] <SRC> <DEST>
```

- **SRC**: Hugging Face repo ID, e.g. `facebook/opt-1.3b`
- **DEST**: Local output directory

**Options:**

- `--repo-type {dataset,model}` (default: `dataset`)
- `-e, --exclude PATTERN`
Glob pattern to skip (repeatable).
- `--method {snapshot,individual}`
Download mode (default: snapshot).
- `--max-retries N`
Retry count (individual mode, default: 3).
- `--skip-integrity`
Bypass etag checks.
- `--force-integrity`
Override excludes in snapshot mode.
- `--use-token`
Use local HF token (`huggingface-cli login`).
- `-h, --help`
Show usage and exit.

**Examples:**

```bash
# Snapshot download:
python3 hf_download.py bigscience/bloom ./bloom_model

# Individual files, excluding .bin:
python3 hf_download.py --method individual -e '*.bin' facebook/opt-1.3b ./opt_model
```

---
