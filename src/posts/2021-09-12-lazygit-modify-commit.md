---
title: "Edit Old Commit with Lazygit"
date: 2021-09-12
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

I used to drop right to the shell whenever I needed to edit an old commit, be it a silly typo or
a missing import I caught before pushing to a remote repository.
Doing so with the git cli is not hard.

<!-- more -->

```bash
git log # look up the commit hash to be edited
git rebase --interactive 'abcdef^' # caret means its parent
# mark the commit as "edit" and apply changes
git commit --all --amend --no-edit
git rebase --continue
```

Using [lazygit](https://github.com/jesseduffield/lazygit), the process is almost identical.

1. Navigate to the commit to be edited and press `e` (_edit commit_).
2. Stage changes and press `A` (_Amend commit with staged changes_).
3. Press `m` (_view merge/rebase options_) and select `continue`.
