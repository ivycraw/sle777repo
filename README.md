# sle777repo
My repository for SLE777 Applied Bioinformatics unit for Deakin University's Graduate Certificate of Bioinformatics

This repo is a demonstration of using Git with RStudio

# Notes and reminders for Ivy to clean
A commit saves a snapshot in your project's history on your own machine. Nothing leaves your computer. Commits are cheap and private, so make them often, in small focused steps.

A push uploads your commits to GitHub so teammates can see and build on them. Only work you have pushed is shared. If you commit all day but never push, nobody else has any of it. 

For week 11, I copied across my results folders like:
cp -r Week{6..10}_results sle777repo/

`git add .` adds all untracked files and unstaged changes. I probably don't want to do that without first adding some gitignore files. 

Instead, I'll do `git add Week{6..10}_results`.

[Git cheat sheet](https://git-scm.com/cheat-sheet)

```{bash}
git pull        # get everyone else's latest work first
# ... do your work, then stage and commit ...
git pull        # again, in case someone pushed while you worked
git push        # now send yours up
```

Branches and pull requests

```{bash}
git switch -c results-writeup        # create and move to a new branch
# ... edit, stage and commit as usual ...
git push -u origin results-writeup   # publish your branch to GitHub
```

After a pull request has been merged on GitHub, you need to delete the branch both on GitHub and locally. 

```{bash}
# Server: switch back to updated main
git switch main
git pull origin main

# Clean up your knowledge of deleted remote branches
git fetch --prune

# Delete the local branch
git branch -d results-writeup

# Create a fresh branch from up to date main and start new work
git switch -c new-feature-name
```

Common practice often looks like:

```{text}
main
  │
  ├── create feature/task branch
  │        ↓
  │      work
  │        ↓
  │      commits
  │        ↓
  │      push
  │        ↓
  │   pull request
  │        ↓
  └──── merge into main
           ↓
       delete branch
```

E.g., 
```{text}
results-writeup
go-enrichment
methods-section
fix-heatmap
```

Notes from the practical:
"How to avoid conflicts in the first place. Pull before you start and before you push. Keep commits small and push often — big, rare commits collide hard. Divide the work so two people rarely edit the same file at once (one owns the QC section, another the results). For the R Markdown report, commit the .Rmd source, not the knitted .html, which rewrites wholesale and conflicts constantly. And talk to each other: the best conflict-resolution tool is a message saying "I'm editing the plot section now"."

Using `git log` you can scroll through your commit history and pick the commit (version) you want to go back to.


