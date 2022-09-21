---
title: "Open Tmux Split with Same PWD"
date: 2020-10-23
author: kotatsuyaki (Ming-Long Huang)
---

Tmux opens every new split and window with the same working directory (usually `$HOME`).
More often and not, this behavior is not desired because I'm working on a project residing in a particular directory.
Here's the solution. Append the following to `tmux.conf`.

```
# Assuming that prefix is C-a...

# Bind C-a u to "new window under same path"
bind-key u neww -c '#{pane_current_path}'
```

For split window, substitute `neww` for `split-window`.
