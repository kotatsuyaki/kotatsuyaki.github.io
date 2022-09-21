---
title: "Let's Start Emacs (For No Apparent Reason)"
date: 2019-06-24
author: kotatsuyaki (Ming-Long Huang)
---

For a long time, I've been sticking to [vim](https://www.vim.org/) as my primary editor. I tried to integrate as much editing functionalities into it as I could. The result turned out to be great, but with the growing count of loaded plugins the editor starts to slow down, eventually rendering it unusable. Yes, I still input characters at my full speed, but the enormous lag of the cursor annoys me *a lot*.

On a sunday morning (not sure when) I finally couldn't withstand the sluggish environment and fired up `emacs`. It's like "How to exit vim" joke but more difficult IMO, with all those cryptic key bindings and commands.

<!-- more -->

# What's Emacs, exactly?

From GNU's own manual it reads:

> Emacs is the extensible, customizable, self-documenting real-time display editor.

Okay hold on, I don't quite understand that.

Simply put, assuming that you've used Vim before, we can make a quick comparison. Vim is a good *text editor*, while Emacs is a good *text editor, file manager, debugger, game center, and more.* It can do nearly whatever you want, provided that there's an package for that purpose (we might talk about that later). Some folks on the Internet calls it an operating system, which is true to some degree.

# Why Emacs?

- Never have to exit Emacs (?)
- Consistency. Instead of learning separate tools, just use Emacs.
- Extensibility. Compose new packages if you're free.
- It's cool, just like vim.

# Installation

I'm using emacs on Manjaro / Arch Linux. If it's the case, then installing emacs is quite straightforward; just issue the following commands in your favorite terminal emulator:

```bash
sudo pacman -Syu
sudo pacman -S emacs
```

On other operating systems, check out [their official installation guide](https://www.gnu.org/software/emacs/download.html#gnu-linux).

# Basic Usage

Now we can start using emacs. I'll cover...

- Terms
- Starting and exiting (Yes it's important)
- Opening and saving files
- Commands

## Terms

When viewing manuals, forum posts or answers on SO, you'll often encounter some abbreviations of the key bindings.

| abbreviation | meaning                            |
|--------------|------------------------------------|
| `C-[key]`    | Hold down `Ctrl` and press `[key]` |
| `M-[key]`    | Hold down `Meta` and press `[key]` |
| `RET`        | Press the enter key                |

Here the `Meta` is somewhat confusing, as I haven't seen a physical keyboard with that key in my life.[^1] On most machines, either the windows key or the `Alt` key is equivalent to the meta key.

If you encounter a sequence like `C-h t`, interpret them as separate keystrokes: Hold down `Ctrl`, press `h`, release `Ctrl`, and finally press `t` alone.

## Starting and Exiting Emacs

Emacs comes with both graphical (GUI) and text (TUI) user interfaces. The graphical one has better support of displaying images etc., while launching the TUI can let you integrate it into your terminal emulator of choice. If you prefer to use emacs inside a terminal, then type `emacs -nw` to start it.[^2] The `-nw` switch stands for "no window". Otherwise, just start it normally.

![](/images/emacs-img-1.png)

You should be greeted by the welcome buffer of Emacs once it started. To quit Emacs, do `C-x C-c` (recall last section in case you don't remember what `C-[key]` is).

## Opening and Saving Files

There are many ways to open a file. For the most basic operations, refer to the following list. Notice that all these common tasks starts with `C-x`, which is a global prefix key.

| keys      | action      |
|-----------|-------------|
| `C-x C-f` | Open a file |
| `C-x C-s` | Save file   |
| `C-x C-w` | Save as...  |

## Manipulating Buffers and Windows

"Buffers" is similar to the idea of "tabs" that occur in GUI applications nowadays. The text you edit in Emacs, the built-in file manager, and the welcome message are all contained in their own buffer.

"Windows" on the other hand, is a fancy word for "panels". It's basically the splits that you may see in a emacs session. I'm not going into details about the cluttering of these terms, as [this SO answer](https://emacs.stackexchange.com/a/13584) explains it better than I can.

| keys          | action                                 |
|---------------|----------------------------------------|
| `C-x k`       | Kill the current buffer                |
| `C-x C-left`  | Prev buffer                            |
| `C-x C-right` | Next buffer                            |
| `C-x b`       | Switch to buffer with name (prompt)    |
| `C-x C-b`     | Open the buffer manager[^3]            |
| `C-x 0`       | Close the current window               |
| `C-x 2 or 3`  | Split window horizontally / vertically |
| `C-x o`       | Switch to next window[^4]              |

## Invoking Commands

In Emacs, those functionalities which aren't bound to key mappings are generally accessed through it's command prompt. Press `M-x` to open it on the bottom of the screen, under the mode line. I'll get deeper into this (if I'm not lazy) in upcoming posts, but you may play with some interesting ~~games~~ commands first:

| command          | description                |
|------------------|----------------------------|
| `M-x calculator` | A calculator               |
| `M-x calendar`   | A calendar                 |
| `M-x tetris`     | The tetris game, built-in! |
| `M-x 5x5`        | 5x5 logic puzzle           |
| `M-x bubbles`    | Clear out bubbles game     |
| `M-x gomoku`     | Connect 5 squares (五目)   |
| `M-x life`       | Conway's Game of Life      |

... and more.

---

# References

[The GNU Emacs manual](https://www.gnu.org/software/emacs/manual/emacs.html)

[^1]: A quick googling yields it's [history on wikipedia](https://en.wikipedia.org/wiki/Meta_key). The [GNU Emacs FAQ](https://www.gnu.org/software/emacs/manual/html_node/efaq) suggests some workarounds for the meta key issue.

[^2]: I haven't found a better solution to this issue. It seems that there's no easy way to configure emacs to always launch without X window, while there are workarounds like shell aliases etc., which are beyond the topic of this post.

[^3]: Not recommended. Using the default buffer manager is a pain in the ass. I'd recommend `ibuffer` (`M-x ibuffer RET`).

[^4]: Not recommended. This is only useful when you have only 2-3 windows displayed.
