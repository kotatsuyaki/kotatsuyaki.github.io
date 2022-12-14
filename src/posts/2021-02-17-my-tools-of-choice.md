---
title: "My Personal Collection of Tools"
date: 2021-02-17
sort_by: "date"
draft: true
author: kotatsuyaki (Ming-Long Huang)
---

Here's a list (and hopefully with short descriptions) of the software tools I loved and enjoyed, which are all highly subjective. This post will be updated if I change my minds (which happens fairly often!), or if I discover something new. However, as an extension to the belief that [cool URIs don't change](https://www.w3.org/Provider/Style/URI), cool public contents also shouldn't randomly disappear based on my will. Hence, information about tools that I don't actively use anymore will still remain resident here, with a leading mark to emphasize the fact that I'm no longer familiar with them.

As I've suggested, my list of tools is extremely biased towards software with the following traits.

<!-- more -->

- Free and open software.
- Minimal and lightweight.
- Configurable via text files.
- Well-documented. Functionalities need not to be immediately discoverable, but they must be mentioned somewhere in the official manuals.

# Contents

Names that aren't self-explanatory are followed by the main use case. Entries without links are planned but not written yet.

# <a name="h-os"></a>Operating Systems (Distros)

Most of the time I use Linux exclusively, except for times when I want to test my projects under other kinds of environment. I have several requirements for Linux distros:

1. Rolling release, or not but with packages that are recent enough. Note that rolling release is not synonymous with cutting-edge software. Beta-quality software shouldn't slip into the default in the distro, because that makes that the system less safe and prone to severe bugs.
1. Support for x86_64, x86, and the ARM architecture. I have several old rigs and Raspberry Pi's where I'd like to run the same distros as my main machines. Sadly, this requirement throws Arch out of the window.
1. ~~Preferrably no SystemD, because it's too complicated for most of my use cases.~~ I've changed
   my mind. While SystemD indeed introduces a bunch of dependencies into the system, most of them
   are needed for a regular system anyways - things like dbus, udev, and pcre etc. are all necessary
   these days. Also, the complexity of SystemD is inherent to system management in general -
   re-inventing the whole mechanism with some ad-hoc shell scripts is fun, but I'd rather not to do
   it everywhere.

- <a name="h-nixos"></a>NixOS

  TBA

- <a name="h-void-linux"></a>Void Linux

  It features the lightweight [Runit](http://smarden.org/runit/) init system, optional musl libc, and supports those three ISAs just mentioned. Another interesting feature of the builtin XBPS package manager is that partial updates are allowed thanks to its checks for shared library consistency.

  The installation process is trivial for anyone with experience of manually installing an OS with command line interface. Their [official installation guide](https://docs.voidlinux.org/installation/index.html) covers pretty much everything one needs to know. Instructions from Arch and Gentoo wiki are usually more or less interchangeable, just keep an eye on those commands managing SystemD / OpenRC.

- <a name="h-gentoo-linux"></a>Gentoo Linux

  This distro is kinda peculiar in the sense that the packages aren't provided as binaries, and compilation happens on the users' machines instead. The Portage package manager makes it extremely flexible to opt in / out for individual functionalities of a piece of software through the [USE flags](https://wiki.gentoo.org/wiki/USE_flag).

  Before trying Gentoo for the first time I've been worried about the compilation time, but it turned out to be a non-issue since

  1. My main machines are powerful enough these days.
  1. For packages that takes too long to compile there's usually [binary packages](https://wiki.gentoo.org/wiki/Binary_package_guide/en) available[^1]. Examples that I frequently use includes [`firefox-bin`](https://packages.gentoo.org/packages/www-client/firefox-bin) and [`rust-bin`](https://packages.gentoo.org/packages/dev-lang/rust-bin).
  1. For weaker devices there's [Distcc](https://wiki.gentoo.org/wiki/Distcc) support built-in, which enables distributed (or delegated) compilation of the packages.

# <a name="h-de"></a>Desktop Environments

I lied in the heading of this section, because I don't regularly use full-fledged desktop environments anymore.

- <a name="h-i3"></a>[i3-gaps](https://github.com/Airblader/i3)

  A tiling window manager. If don't know what a tiling window manager is, it's basically something that **manages** the windows by **tiling** them side-by-side, in a non-overlapping fashion. Here's how it looks in action.

  ![](/images/tiling-wm.png)

  Note that i3-gaps is an almost-identical fork from [i3](https://i3wm.org/), with the ability to specify gap sizes between the windows (purely aesthetic). All the documentation from upstream applies.

  Complementary Parts for i3-gaps, because i3 alone is too barebones:

  - [rofi](https://github.com/davatorium/rofi). Application launcher with levenshtein distance matching mechanism.
  - [Polybar](https://github.com/polybar/polybar). Status bar for tiling WMs.
  - [picom](https://github.com/yshui/picom). Lightweight compositor (the program responsible for rendering window transparency, shadow/blur/fade effects etc.) for X11.
  - [feh](https://feh.finalrewind.org/). Lightweight image viewer, here used as wallpaper setter.
  - [scrot](https://github.com/resurrecting-open-source-projects/scrot). Screenshot from the command line. Usually I use it from [my i3wm keybindings](https://gitlab.com/Akitaki/dotfiles/-/blob/4eefdd594ff7ae05db7082bc9746913d4f86acd4/_config/i3/config.template#L60).

- <a name="h-kde"></a>[KDE](https://kde.org/) (Not active user anymore)

  I used KDE plasma for a somewhat long period, roughly around the same time I started diving into the world of Linux and FOSS software. It's rich in feature, customizable and highly usable, unlike the hamburger button disaster [that started invading other DEs](https://ubuntu-mate.community/t/horrible-gtk3-gnome-ui-design-is-leaking-into-ubuntu-mate-applications-in-20-04/22028?page=3). Although I'm no longer using it, it's still my recommended DE for Linux newbies.

  Here's an old screenshot of my KDE setup. It's mimicking the visual style and layout of macOS of the time, since I came from the macOS world. In practice one can make KDE looks whatever you like. Windows 95 style? [Yes, it can do that](https://store.kde.org/p/1012363/). Replacing the built-in window manager with i3wm? [Yes, it can do that](https://userbase.kde.org/Tutorials/Using_Other_Window_Managers_with_Plasma).

  ![](/images/kde-screenshot.png)

# <a name="h-editors"></a>Text Editors

This topic actually deserves its own blog post, because over half of the time when I'm using a computer, I stay inside the text editors. The only hard requirement is that they should not be Electron based -- I'm tired of having multiple apps that are actually Chromium under the hood eating memory and storage space.

Thanks to the development and standardization of the [LSP](https://microsoft.github.io/language-server-protocol/), a protocol that generalizes the communication between development tools and the backend servers, my choices are no longer constrained by their support for specific programming / markup languages. Any editor will do, as long as there's support for LSP.

With that being said, I'm 100% tied to modal editing (Vim-style key bindings in particular). It's almost impossible for me to unlearn these habits and use modeless editors anymore. I'm aware of the fact that many editors ([and even IDEs](http://vrapper.sourceforge.net/home/#:~:text=Vrapper%20is%20an%20Eclipse%20plugin,have%20opened%20in%20the%20workbench.)) provide Vim-mode, but as far as I know none of them is actually capable of providing the same level of usability.

- <a name="h-nvim"></a>Neovim

  [Neovim](https://github.com/neovim/neovim) is a fork of Vim with much better extensibility, compared to the original Vim. Most of the old plugins are compatible with Neovim, so there's nothing to loss when I migrated to it.

  For some highlighted plugins, see the [vim plugins section](#h-vim-plugins). For real-life usage showcase (code completion, documentation viewer, git integration, linting etc.), see this screenshot.

  ![](/images/neovim.png)

- <a name="h-vim"></a>Vim

  Historically until the switch to Neovim I was an exclusive Vim user. It's still my fallback editor either when the power of Neovim is not required or when I'm on a machine with only Vim installed.

  The [config I use for Vim](https://gitlab.com/Akitaki/dotfiles/-/blob/4eefdd594ff7ae05db7082bc9746913d4f86acd4/_vimrc) is quite minimal now, and I'm able to type it out of my head. Using only Vim + GCC + GDB during programming exams is actually possible, and that's what I've been doing for the past two years.

- <a name="h-sublime"></a>Sublime Text (Warning: Non-FOSS)

  Despite my hate towards proprietary software, this is considered an honorable mention. It was what I've been using before diving into the command line, and it's an amazing piece of software, given that it's top-of-the-line UI responsiveness and low resource usage.

# <a name="h-vim-plugins"></a>Vim Plugins

[The list of nvim plugins](https://gitlab.com/Akitaki/dotfiles/-/blob/master/_config/nvim/init.vim) I use on a regular basis is quite long, and it's thus impossible to introduce all of them. Here I'll only list those I deem as must-haves.

- [vim-surround](https://github.com/tpope/vim-surround).

  It enables shortcuts to manipulate the parentheses, brackets, quotes and XML tags in an natural fashion. For example, pressing `cs"'` (reads: **c**hange **s**urrounding from **"** to **'**) inside

  ```
  "Hello world!"
  ```

  changes it to

  ```
  'Hello world!'
  ```

- [auto-pairs](https://github.com/jiangmiao/auto-pairs).

  By default Vim doesn't auto-close open parentheses, and thus this plugin is required. Similar effect can also be achieved [using a couple of lines in `.vimrc`](https://stackoverflow.com/a/34992101) if plugins is not an option.

- [coc.nvim](https://github.com/neoclide/coc.nvim).

  Full-featured LSP client for Neovim. This brings pretty much all the "intelligent" functionalities (code completion, refactoring, snippets, code linting) to Neovim, achieving IDE-like experience while remaining lightweight and staying in the terminal window.

- [vim-gitgutter](https://github.com/airblade/vim-gitgutter).

  Shows git diff near the line numbers and lets you jump between the edited parts. Additionally, staging / undoing hunks within the editor is also possible.

# <a name="h-net-comm"></a>Network and Communication

- <a name="h-telegram"></a>[Telegram](https://telegram.org/) Messaging Service (Warning: Non-FOSS)

  It's fairly feature-rich, it has open APIs, and has official clients for Linux. The downside is obvious, though: the server-side is not open sourced. It's still my favorite, and I've wrote several chat bots for this platform.

- <a name="h-qutebrowser"></a>[Qutebrowser](https://qutebrowser.org/)

  A keyboard-driven browser based on PyQt5, inspired by Vim. The key bindings feel like home to a Vimmer. The only thing I miss from Firefox/Chromium is the rich collection of extensions (some use cases can be covered with [custom userscripts](https://github.com/qutebrowser/qutebrowser/blob/master/doc/userscripts.asciidoc)).

- <a name="h-aria"></a>[Aria2](https://aria2.github.io/)

  A command line download utility, capable of downloading files with any protocol, and with built-in multi-connection download support. Downloading from a torrent magnet link is as easy as typing out

  ```
  $ aria2c 'magnet:?xt=urn:btih:248D0A1CD08284299DE78D5C1ED359BB46717D8C'
  ```

- <a name="h-links"></a>[Links](http://links.twibright.com/)

  Command line web browser. It's most useful when rescuing a system with GUI components broken - it's still possible to use Links to read the online manuals or forums. For example the "Wayland" entry on the Gentoo wiki (`links 'https://wiki.gentoo.org/wiki/Wayland'`) looks like this in Links. Clear and readable. The menubar is just one `Esc` away.

  ![](/images/links-browser.png)

# <a name="h-multimedia"></a>Video / Image Viewers

- <a name="h-mpv"></a>[mpv](https://mpv.io/)

Mpv is a minimal media player. Despite the simplicity of its UI, it's fairly powerful with [scripting ability](https://github.com/mpv-player/mpv/wiki/User-Scripts) and hardware acceleration support.

The usual way of using `mpv` is to simply invoke it from the command line like `mpv my-awesome-video.mp4`. There's also ways to open mpv for viewing videos from the browsers ([for Qutebrowser](https://qutebrowser.org/doc/faq.html), [for Chromium](https://github.com/Thann/play-with-mpv), [for Firefox](https://github.com/woodruffw/ff2mpv)).

- <a name="h-feh"></a>[feh](https://feh.finalrewind.org/)

A minimal image viewer that's usable without a mouse.

# <a name="h-docs"></a>Documents and Notes

- <a name="h-tex-md"></a>LaTeX and Markdown

  Seriously I prefer pencils and papers for their extreme flexibility, but that's out of scope in this post On a computer with a proper keyboard, nothing beats plain `*.txt` notes with personal notations.

  - **Markdown**, markup language suited for short notes.

    But hey, sometimes there's need for rendering / printing of these notes! That's where [Markdown](https://daringfireball.net/projects/markdown/) shines (or did shine at least), since it's a canonical way of turning conventional text documents into HTML markup. In fact, my blog posts are all written in Markdown.

    Despite its ongoing popularity, I've recently changed my mind and started to steer away from Markdown as far as possible, because [its downsides include lack of extensibility](https://www.ericholscher.com/blog/2016/mar/15/dont-use-markdown-for-technical-docs/). Why on earth would the idiomatic way of inserting custom blocks (for example a "warning box" in tutorials) be "just insert raw HTML" or "use this flavor-specific extension"? Why can't we all agree on [CommonMark](https://commonmark.org/) and stick to the formal spec?

  - **LaTeX**, the ugly language that produces beautiful documents.

    Typesetting assignments in LaTeX isn't a pleasant experience, to be honest, and one has to jump through multiple hoops before becoming a competent LaTeX writer. It's a shame that the best typesetting macro system we have so far is such an ugly thing.

    Being born in Taiwan and a Japanese language lover (reads: _otaku_), being able to easily process non-ascii CJK characters is a must. Using `CJKutf8` package partially solves the problem, but it requires surrounding every single piece of CJK strings with this ugly environment:

    ```tex
    \begin{CJK}{UTF8}{ipxm}??????????????????????????????????????????????????????\end{CJK}
    ```

    Instead, I recommend [XeTeX](https://www.tug.org/xetex/). After including these two lines of code, CJK characters work everywhere in the rest of the document. This prevents the document from being compiled correctly without `xelatex`, though.

    ```tex
    \usepackage{xeCJK}
    % Substitute the font with your favorite font
    \setCJKmainfont{Noto Serif CJK TC}
    ```

# <a name="h-languages"></a>Programming Languages

It's without doubt that programming languages count as software tools.

- [Rust](https://www.rust-lang.org/). Its distinctive ownership model saved me a lot of headache when writing asynchronous code. It's my go-to choice for **all** my programming tasks.
- C. The good old C. Not until recently did I start [appreciating the portability](https://nullprogram.com/blog/2017/03/30/) of the C (along with [the POSIX standard](https://pubs.opengroup.org/onlinepubs/9699919799/)). How come I used to be a guy who don't give a shit to C and steer directly to C++17 whenever possible?
- Ruby. It's really expressive. Making small-scale experiments is a breeze with it.

# Version History

- 0.1 @ 2021-02-17 | Initial release. Some entries aren't written yet, but I released this post anyway since I may never complete them.
- 0.2 @ 2021-02-17 | Mention scrot. List use cases of mpv. Indicate general requirements.

[^1]: Sadly though there seems to be no `chromium-bin`. It was once there, but [removed due to security and versioning problems](https://forums.gentoo.org/viewtopic-t-1076620-start-0.html).
