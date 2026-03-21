<div style="column-count: 2; column-gap: 40px;">

# Git for Godot Cheat Sheet

## Local Repository Setup
| Command | Description |
|---------|-------------|
|`git init`                       | Initialize a new Git repository           |
|`git status`                     | Show current changes in working directory |
|`git add -A`                     | Stage all files (ready to by committed)   |
|`git commit -m "Message"`        | Records changes to repo (creates a checkpoint) |

| Cloning GitHub Repo | |
|---------|-------------|
* From repo page click green 'Code' dropdown button
* Select `HTTPS` or `SSH` and click "Copy URL to clipboard"
    * You'll have to use `HTTPS` if you don't have a GitHub account
* In Git Bash - navigate to desired git folder
    * reccomend `c/Users/<username>/git/`
* `git clone <url>`
    * Paste url copied from GitHub


## Standard Workflow (Everyday Use)
| Command | Description |
|---------|-------------|
| `git status`                    | Show current changes in working directory |
| `git add -A`                    | Stage all changes (tracked + untracked)   |
| `git commit -m "message"`       | Commit changes with a message |
| `git push origin <branch-name>` | Upload commits to remote repository |

| Helpful | |
|---------|-------------|
| `git add <file>`          | Stage file (in case you don't want to add all)|
| `git add <file1> <file2>` | Stage files listed (need a space between each)|
| `git reset <file>` | Removes file from staging


## Branch Workflow
| Command | Description |
|---------|-------------|
|`git checkout -b <branch-name>` | Create new branch and switch to it |
|`git checkout <branch-name>`    | Switch to specified branch |
|`git push origin <branch-name>` | Push branch to origin/GitHub |

| Helpful | |
|---------|-------------|
| `git branch` | Shows list of existing branches |
| `git branch -vv` | Show verbose list of existing branches |
| `git push -u origin HEAD` | Local will track with remote |
| `branch -vv --sort=committerdate` | Verbose list sorted by date of last commit |
| `git branch -d <branch-name>` | Delete branch (use -D to force delete)|


## Pull / Fetch / Sync
| Command | Description |
|---------|-------------|
|`git fetch -p`   | Update remote branches and remove deleted ones |
|`git pull`       | Fetch and merge remote changes |
|`git remote -v`  | Show remote repository URLs |


## Git LFS (Large Files)
| Command | Description |
|---------|-------------|
| `git lfs install`                | Enable Git LFS (required once on machine) |
| `git lfs track` | List files being tracked by LFS |
| `git lfs track "*.<filetype>"`          | Track file type with LFS |
| `git lfs status` | Use after `git add` to check if staged files are LFS |

## Git Bash Basics
| Command | Description |
|---------|-------------|
| `echo $HOME` | Show home directory                     |
| `cd`         | Return to home directory                |
| `cd <dir>`    | Enter directory                         |
| `pwd`        | Show current directory                  |
| `ls`         | List files                              |
| `clear`      | Clear terminal                          |
| `explorer .` | Open current folder in Windows Explorer |

Notes:
```
- Ctrl+C cancels commands (NOT copy)
- Right-click to copy/paste
- If terminal is stuck → press Ctrl+C
```

## Help Commands
| Command | Description |
|---------|-------------|
| `git --help`           | Show general help |
| `git <command> --help` | Show detailed help for a command |
| `git help <command>`   | Alternative help command |
| `git status -h`        | Show quick help summary |
| `help` | Show Bash Commands |
| `help <command>` | Shows detailed help for Bash command|

## Common Pain Points

**Not sure what changed?** → git status

**Push rejected?** → Run `git pull` or `git fetch -p` first

**Branch not tracking remote?** → Use `git push -u origin <branch>`

**Terminal stuck?** → `Ctrl + C`

**Lost in folders?** → `pwd`  (Print Working Directory - tells you where you are)


## Tips

- Commit often with clear messages
- Use branches for features and experiments
- Set upstream once to simplify future pushes (`git push -u origin HEAD`)
- Decide Git LFS tracking early for large assets
- Always check `git status` before committing

</div>