# AI sandbox

### Significant portions of this codebase and README were written by AI.

Run Codex or Claude Code in Docker from a Windows terminal. Each project has a small configuration file that points to its folder on your computer.

Docker makes your project folder available inside the container as `/workspace`. This is called a bind mount: it gives the container direct access to the same files on your computer, without copying them or keeping a separate mirror.

When the agent edits, creates, or deletes a file in `/workspace`, that change happens in your actual project folder. Your changes also affect the container. Closing or rebuilding the container does not undo those changes or remove your project files.

## Setup

You need Docker installed and running with Linux containers enabled.

Create a file such as `projects/my-project.bat`:

```bat
@echo off
set "PROJECT=my-project"
set "WORKSPACE=C:\code\my-project"
set "CONTAINER_WORKDIR=/workspace"
set "IMAGE=ai-sandbox"
set "CODEX_AUTH_VOLUME=ai-codex-auth"
set "CLAUDE_AUTH_VOLUME=ai-claude-auth"
```

Change `WORKSPACE` to your project's folder. Using the same volume names across projects shares your agent logins and settings.

From this repo's folder, build the image:

```bat
ai.bat my-project rebuild
```

## Use

Start either agent, or open a shell inside the container:

```bat
ai.bat my-project codex
ai.bat my-project claude
ai.bat my-project shell
```

## Built-in limits

The launcher mounts existing `.git` and `node_modules` folders as read-only. Command guards block common Git changes and package manager commands, so run those from your Windows terminal.

The container also has memory and process limits. A background check stops the session if it finds new or changed archive files, or files larger than 1 GiB, in the workspace.
