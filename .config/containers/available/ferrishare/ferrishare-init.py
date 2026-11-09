#!/usr/bin/env python3
"""Provision FerriShare's `config.toml` non-interactively.

FerriShare refuses to start without `./data/config.toml`, and that file can only
be produced by an *interactive* wizard (`ferrishare --init`) because it hashes the
admin password with argon2id. This driver runs the wizard inside a pseudo-terminal
and answers every prompt in order:

  * every `Text`/`Select`/`Confirm` prompt already carries a sensible initial value,
    so it is accepted with a bare ENTER;
  * the `Admin password:` prompt and its `Confirmation:` are fed the password.

The generated config lives in the stack's named volume. The admin password is printed
once on success: store it safely, because Podman secrets are write-only and the argon2id
hash in config.toml cannot be reversed.

Usage:
  FH_ADMIN_PW='...' ./ferrishare-init.py [--volume ferrishare-data]
      [--image ghcr.io/tobiasmarschner/ferrishare] [--force] [--timeout 120]
"""

import argparse
import os
import pty
import re
import secrets
import select
import subprocess
import sys
import time

# inquire re-renders with ANSI escapes; strip them so prompt markers match cleanly.
ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")


def build_steps(admin_pw):
    """Ordered (prompt-marker, keystrokes). A bare CR accepts the initial value."""
    return [
        ("App name:", "\r"),
        ("Interface:", "\r"),
        ("Proxy Depth:", "\r"),
        ("Admin password:", admin_pw + "\r"),
        ("Confirmation:", admin_pw + "\r"),
        ("Maximum filesize:", "\r"),
        ("Maximum storage:", "\r"),
        ("Maximum uploads per IP:", "\r"),
        ("Daily request limit per IP:", "\r"),
        ("Log level:", "\r"),
        ("Enable Privacy Policy?", "\r"),
        ("Enable Legal Notice?", "\r"),
    ]


def drive(cmd, steps, timeout):
    """Run `cmd` on a PTY, answering each prompt marker once. Returns (rc, output)."""
    pid, fd = pty.fork()
    if pid == 0:  # child
        os.environ["TERM"] = os.environ.get("TERM", "vt100")
        os.execvp(cmd[0], cmd)
        os._exit(127)

    buf = b""
    idx = 0
    consumed = 0  # chars of the (stripped) stream already accounted for
    start = time.time()
    while True:
        if time.time() - start > timeout:
            os.kill(pid, 9)
            return 124, buf.decode(errors="replace")
        r, _, _ = select.select([fd], [], [], 1)
        if r:
            try:
                data = os.read(fd, 8192)
            except OSError:
                data = b""
            if not data:
                break
            buf += data
            text = ANSI_RE.sub("", buf.decode(errors="replace")).replace("\r", "")
            while idx < len(steps):
                marker, answer = steps[idx]
                pos = text.find(marker, consumed)
                if pos == -1:
                    break
                os.write(fd, answer.encode())
                consumed = pos + len(marker)
                idx += 1
    try:
        _, status = os.waitpid(pid, 0)
        rc = os.waitstatus_to_exitcode(status)
    except ChildProcessError:
        rc = 0
    return rc, buf.decode(errors="replace")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--volume", default="ferrishare-data")
    ap.add_argument("--image", default="ghcr.io/tobiasmarschner/ferrishare")
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument(
        "--force",
        action="store_true",
        help="re-run the wizard even if config.toml already exists",
    )
    args = ap.parse_args()

    admin_pw = os.environ.get("FH_ADMIN_PW") or secrets.token_urlsafe(18)

    subprocess.run(
        ["podman", "volume", "create", args.volume],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    # Skip if the volume already holds a config (idempotency).
    existing = subprocess.run(
        ["podman", "volume", "export", args.volume],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if not args.force and existing.returncode == 0:
        names = subprocess.run(
            ["tar", "-t"], input=existing.stdout, stdout=subprocess.PIPE
        ).stdout.decode(errors="replace")
        if "config.toml" in names:
            print(
                f"[ferrishare-init] config.toml already present in '{args.volume}'; "
                f"nothing to do (use --force to overwrite)."
            )
            return 0

    cmd = [
        "podman",
        "run",
        "--rm",
        "-it",
        "-v",
        f"{args.volume}:/app/data",
        args.image,
        "--init",
    ]
    rc, out = drive(cmd, build_steps(admin_pw), args.timeout)

    if rc != 0 or "Successfully wrote config" not in out:
        tail = ANSI_RE.sub("", out).replace("\r", "\n").strip().splitlines()[-15:]
        print("\n".join(tail), file=sys.stderr)
        print(f"[ferrishare-init] ERROR: wizard failed (rc={rc}).", file=sys.stderr)
        return 1

    print(f"[ferrishare-init] OK: config.toml written into volume '{args.volume}'.")
    print(
        f"[ferrishare-init] Admin password (SAVE IT; it is not recoverable): {admin_pw}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
