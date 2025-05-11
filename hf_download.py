#!/usr/bin/env python3
"""
hf_download.py

A utility for downloading entire Hugging Face repositories, with options
for snapshot or individual file downloading, pattern exclusion, and
integrity control.
"""

import argparse
import os
import time
from fnmatch import fnmatch
from typing import List
from huggingface_hub import (
    HfApi,
    hf_hub_download,
    snapshot_download,
    list_repo_files,
)


def download_files_individually(
    repo_id: str,
    local_dir: str,
    repo_type: str,
    excludes: List[str],
    max_retries: int,
    skip_integrity: bool,
    use_token: bool,
) -> None:
    """Download files one by one from a Hugging Face repository.

    Args:
        repo_id: The Hugging Face repository ID (e.g., 'bigscience/bloom').
        local_dir: Destination directory to store the files.
        repo_type: Either 'dataset' or 'model'.
        excludes: List of glob patterns for files to exclude.
        max_retries: Number of retry attempts on failure.
        skip_integrity: If True, bypasses etag validation.
        use_token: If True, uses Hugging Face auth token (requires prior login).
    """
    api = HfApi()
    print(f"\n🔍 Fetching file list for {repo_type.upper()} '{repo_id}'...")
    files = api.list_repo_files(repo_id=repo_id, repo_type=repo_type)
    print(f"📄 Found {len(files)} files. Previewing and downloading...\n")

    os.makedirs(local_dir, exist_ok=True)

    for file in files:
        if any(fnmatch(file, pat) for pat in excludes):
            print(f"🚫 Excluded: {file}")
            continue
        else:
            print(f"✅ Will download: {file}")

        attempt = 0
        while attempt < max_retries:
            try:
                print(f"⬇️ Downloading: {file} (Attempt {attempt+1}/{max_retries})")
                hf_hub_download(
                    repo_id=repo_id,
                    filename=file,
                    repo_type=repo_type,
                    local_dir=local_dir,
                    force_download=skip_integrity,
                    token=True if use_token else None,
                )
                print(f"✅ Successfully downloaded: {file}")
                break
            except Exception as e:
                attempt += 1
                print(f"❌ Failed to download {file}. Error: {e}")
                if attempt < max_retries:
                    print("🔁 Retrying in 10 seconds...")
                    time.sleep(10)
                else:
                    print(
                        f"🚨 Skipping file after {max_retries} failed attempts: {file}"
                    )

    print("\n🎉 Individual file download completed.")


def download_snapshot(
    repo_id: str,
    local_dir: str,
    repo_type: str,
    excludes: List[str],
    skip_integrity: bool,
    force_integrity: bool,
    use_token: bool,
) -> None:
    """Download an entire Hugging Face repository snapshot at once.

    Args:
        repo_id: The Hugging Face repository ID (e.g., 'facebook/opt-1.3b').
        local_dir: Destination directory to store the files.
        repo_type: Either 'dataset' or 'model'.
        excludes: List of glob patterns to exclude.
        skip_integrity: If True, force re-download regardless of etag.
        force_integrity: If True, override exclusion filters.
        use_token: If True, uses Hugging Face auth token (requires prior login).
    """
    print(f"\n📦 Starting snapshot download of {repo_id} to {local_dir}...")

    ignore_patterns = excludes if not force_integrity else None

    print(f"🔎 Excluding patterns: {excludes}")
    print("📋 Previewing matching files...")
    files = list_repo_files(repo_id=repo_id, repo_type=repo_type)
    for f in files:
        if ignore_patterns and any(fnmatch(f, pat) for pat in ignore_patterns):
            print(f"   🚫 {f}")
        else:
            print(f"   ✅ {f}")

    snapshot_download(
        repo_id=repo_id,
        repo_type=repo_type,
        local_dir=local_dir,
        force_download=skip_integrity,
        ignore_patterns=ignore_patterns,
        token=True if use_token else None,
    )

    print("\n✅ Snapshot download complete.")


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Download entire Hugging Face repositories using snapshot or individual download methods.",
        epilog="""
Examples:
  python hf_download.py facebook/opt-1.3b ./opt_model
  python hf_download.py --method individual -e '__pycache__' -e '*.git' bigscience/bloom ./bloom_model
  python hf_download.py --repo-type model --use-token myuser/private-model ./private_model
""",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("SRC", help="Hugging Face repo ID, e.g. 'facebook/opt-1.3b'")
    parser.add_argument("DEST", help="Local output directory")
    parser.add_argument("--repo-type", choices=["dataset", "model"], default="dataset")
    parser.add_argument(
        "-e",
        "--exclude",
        action="append",
        default=[],
        help="Glob pattern to exclude (can repeat, e.g., -e '*.bin')",
    )
    parser.add_argument(
        "--method",
        choices=["snapshot", "individual"],
        default="snapshot",
        help="Download method",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=3,
        help="Retries for failed downloads (individual mode)",
    )
    parser.add_argument(
        "--skip-integrity", action="store_true", help="Bypass etag integrity checks"
    )
    parser.add_argument(
        "--force-integrity",
        action="store_true",
        help="Force snapshot to ignore exclusion rules",
    )
    parser.add_argument(
        "--use-token",
        action="store_true",
        help="Use Hugging Face auth token (requires `huggingface-cli login`)",
    )
    return parser.parse_args()


def main():
    """Entry point for direct execution."""
    args = parse_args()

    if args.method == "snapshot":
        download_snapshot(
            repo_id=args.SRC,
            local_dir=args.DEST,
            repo_type=args.repo_type,
            excludes=args.exclude,
            skip_integrity=args.skip_integrity,
            force_integrity=args.force_integrity,
            use_token=args.use_token,
        )
    else:
        download_files_individually(
            repo_id=args.SRC,
            local_dir=args.DEST,
            repo_type=args.repo_type,
            excludes=args.exclude,
            max_retries=args.max_retries,
            skip_integrity=args.skip_integrity,
            use_token=args.use_token,
        )


if __name__ == "__main__":
    main()
