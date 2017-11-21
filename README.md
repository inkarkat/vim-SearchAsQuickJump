SEARCH AS QUICK JUMP   
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

I use the built-in search (/, ?, n and N) for two different purposes:
1. For quick mouseless navigation to a place not far away, or as a {motion}
   e.g. in d/{pattern}/.
2. For actual searches, when I'm looking for and examining all occurrences
   inside the buffer or even multiple windows.

Unfortunately, there's a tension in how to configure the search-related
settings: For quick searches, highlighting of matches is not important, as my
eyes are already focused on the target text, I just want to get there with the
fewest keystrokes, and figured that a search for "/:le" is faster than
"3fA4whhh". Because the search pattern is mostly incomplete, the highlighting
should not continue to distract after the search; it should be off (but
'incsearch' helps to recognize when enough of the pattern is typed to reach
the desired location). Likewise, the search pattern is useless in the search
history and as the last pattern for the n command, as I am unlikely to
repeat that search. On the other hand, for actual searches, history recall,
repeated search and highlighting of matches are vital and central to the task.

How can this be reconciled? This plugin sets up alternative mappings to the
 CR> key which normally concludes entering of the search pattern in
command-line mode. By pressing <S-CR>, a quick search is triggered instead of
a normal one. This quick search does not use search highlighting and the
search pattern is not added to the search history, so it can be used without
affecting the normal search. Likewise, in a non-search command-line, the
executed command (for example, a :substitute) does not affect the current
search pattern and search history.

Next / previous matches can be jumped to via separate mappings, but not via
the default n / N commands. (Even if the integration with the SearchRepeat
plugin is used; contrary to most other integrations, this quick search must be
explicitly activated via the gnq / gnQ mapping. )

### SEE ALSO

- Check out the SearchSpecial.vim plugin page ([vimscript #4948](http://www.vim.org/scripts/script.php?script_id=4948)) for a full
  list of special searches powered by it.

USAGE
------------------------------------------------------------------------------

    /{pattern}[/]<S-CR>     When a search via / or ? is sent off by pressing
    ?{pattern}[?]<S-CR>     <S-CR>, a quick forward / backward search is
                            performed. Matches will not be highlighted via
                            'hlsearch', and the search pattern will not be added
                            to the search history or used as the last pattern for
                            n / N search repeats.
                            Use this for a quick search without the formality and
                            persistence of a normal search, which can still be
                            obtained by concluding the pattern input with the
                            default <CR> at the end.
                            In the :... Ex command-line (and also >... debug
                            command-line), any change to the search pattern and
                            history is undone. For example, this is useful to do a
                            substitution without affecting the current search:
                            /foo<CR> :s/X/Y/<S-CR> n (keep searching for "foo")

    The special searches all start with 'go...' (mnemonic: "go once to special
    match"); and come in search forward (go...) and backward (gO...) variants.

    [count]goq / goQ        Search forward / backward to the [count]'th occurrence
                            of the quick search pattern. This is the equivalent to
                            the default n / N search repeat commands.

    The following commands are optional; cp. the SearchAsQuickJump-configuration
    section below.

    q*, q#                  Search forward / backward for the [count]'th
                            occurrence of the word nearest to the cursor.
    gq*, gq#                Like above, but don't put "\<" and "\>" around the
                            word. This makes the search also find matches that are
                            not a whole word.
    {Visual}q*              Do a quick search forward / backward for the [count]'th
    {Visual}q#              occurrence of the current selection, like the built-in
                            gstar and g# commands.

                            These mappings are based on the built-in star and
                            # commands. Like with them, 'ignorecase' is used,
                            'smartcase' is not.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-SearchAsQuickJump
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim SearchAsQuickJump*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the SearchSpecial.vim plugin ([vimscript #4948](http://www.vim.org/scripts/script.php?script_id=4948)), version 1.20 or
  higher.
- SearchRepeat.vim ([vimscript #4949](http://www.vim.org/scripts/script.php?script_id=4949)) plugin, version 2.00 or higher (optional)

INTEGRATION
------------------------------------------------------------------------------

If the SearchRepeat plugin is installed, a parallel set of "go now and for
next searches" mappings (starting with 'gn...' instead of 'go...') is
installed. These mappings have the same effect, but in addition re-program the
'n/N' keys to repeat this particular search (until another gn... search is
used).

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

If you don't want additional commands like the built-in '\*', 'g\*', '#' and
'g#' commands (but prefixed with 'q' and not affecting the current search),
use:

    :let g:SearchAsQuickJump_DefineStarCommands = 0

If you want to use different mappings, map your keys to the
 Plug>(SearchAsQuickJump...) mapping targets _before_ sourcing the script
(e.g. in your vimrc):

    cmap <S-CR> <Plug>(SearchAsQuickJump)

    nmap q* <Plug>(SearchAsQuickJumpStar)
    nmap q# <Plug>(SearchAsQuickJumpHash)
    nmap gq* <Plug>(SearchAsQuickJumpGStar)
    nmap gq# <Plug>(SearchAsQuickJumpGHash)
    xmap q* <Plug>(SearchAsQuickJumpStar)
    xmap q# <Plug>(SearchAsQuickJumpHash)

    nmap goq <Plug>(SearchAsQuickJumpNext)
    nmap gOq <Plug>(SearchAsQuickJumpPrev)

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-SearchAsQuickJump/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 1.10    RELEASEME
- ENH: Handle /.../{offset} (instead of just ignoring the {offset}).
  __You need to update to SearchSpecial.vim ([vimscript #4948](http://www.vim.org/scripts/script.php?script_id=4948)) version 1.20!__

##### 1.00    20-Nov-2017
- First published version.

##### 0.01    10-Jul-2009
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2009-2017 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat <ingo@karkat.de>
