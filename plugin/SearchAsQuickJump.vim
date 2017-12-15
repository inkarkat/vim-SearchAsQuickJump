" SearchAsQuickJump.vim: Quick search without affecting 'hlsearch', search pattern and history.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - SearchAsQuickJump.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/selection.vim autoload script
"   - SearchRepeat.vim autoload script (optional integration)

" Copyright: (C) 2009-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SearchAsQuickJump') || (v:version < 700)
    finish
endif
let g:loaded_SearchAsQuickJump = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration --------------------------------------------------------------

if ! exists('g:SearchAsQuickJump_DefineStarCommands')
    let g:SearchAsQuickJump_DefineStarCommands = 1
endif



"- mappings -------------------------------------------------------------------

nnoremap <silent> <Plug>(SearchAsQuickJumpNext) :<C-u>if ! SearchAsQuickJump#DoSearch(v:count1, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpPrev) :<C-u>if ! SearchAsQuickJump#DoSearch(v:count1, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>

" The quick search pattern should not pollute the normal search history.
" However, Vim always appends to the history, even if command-line mode is
" aborted via <Esc> or CTRL-C (probably to be able to go back and finish an
" aborted command). Thus, the quick search pattern has to be removed from the
" search history.
" To remove without side effects, we must ensure that the quick search pattern
" wasn't contained in the search history before. In such a case, the history
" item would be moved from its original position to the end of the history, and
" by deleting it, the item would completely disappear from the history!
" Thus, a history marker is appended to the entered search pattern by the
" mapping that triggers the quick jump, and later stripped off the search
" pattern. The marker should be a string that the user would never enter on his
" own, so that we can be reasonably sure that the resulting search pattern is
" not yet contained in the search history. We choose an obscure control
" character (CTRL-_ (0x1f) Unit Separator) which is not a valid Vim command in
" command-line mode.
cnoremap <SID>(NoHistoryMarker) <C-_><C-_>
" Note: This needs to correspond to s:NoHistoryMarkerLen in
" autoload/SearchAsQuickJump.vim
cnoremap <expr> <SID>(QuickSearch) SearchAsQuickJump#QuickSearch()
" If :cnoremap is used, the mapping doesn't trigger expansion of :cabbrev any
" more. The only way to work around this is by using :cmap and prepending a
" <Space> (which is considered part of the NoHistoryMarker and later removed
" with it).
cmap <silent> <Plug>(SearchAsQuickJump) <Space><SID>(NoHistoryMarker)<SID>(QuickSearch)
if ! hasmapto('<Plug>(SearchAsQuickJump)', 'c')
    cmap <S-CR> <Plug>(SearchAsQuickJump)
endif


if g:SearchAsQuickJump_DefineStarCommands
nnoremap <silent> <Plug>(SearchAsQuickJumpStar)  :<C-u>if ! SearchAsQuickJump#SearchCWord(1, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpHash)  :<C-u>if ! SearchAsQuickJump#SearchCWord(1, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpGStar) :<C-u>if ! SearchAsQuickJump#SearchCWord(0, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpGHash) :<C-u>if ! SearchAsQuickJump#SearchCWord(0, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
vnoremap <silent> <Plug>(SearchAsQuickJumpStar)  :<C-u>if ! SearchAsQuickJump#SearchSelection(ingo#selection#Get(), v:count1, 0, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
vnoremap <silent> <Plug>(SearchAsQuickJumpHash)  :<C-u>if ! SearchAsQuickJump#SearchSelection(ingo#selection#Get(), v:count1, 0, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'n')
    nmap q* <Plug>(SearchAsQuickJumpStar)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'n')
    nmap q# <Plug>(SearchAsQuickJumpHash)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGStar', 'n')
    nmap gq* <Plug>(SearchAsQuickJumpGStar)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGHash', 'n')
    nmap gq# <Plug>(SearchAsQuickJumpGHash)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'x')
    xmap q* <Plug>(SearchAsQuickJumpStar)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'x')
    xmap q# <Plug>(SearchAsQuickJumpHash)
endif
endif

onoremap <expr> / SearchAsQuickJump#OperatorPendingSearch('/')
onoremap <expr> ? SearchAsQuickJump#OperatorPendingSearch('?')

if ! hasmapto('<Plug>(SearchAsQuickJumpNext)', 'n')
    nmap goq <Plug>(SearchAsQuickJumpNext)
endif
if ! hasmapto('<Plug>(SearchAsQuickJumpPrev)', 'n')
    nmap gOq <Plug>(SearchAsQuickJumpPrev)
endif


"- Integration into SearchRepeat.vim -------------------------------------------

try
    call SearchRepeat#Define(
    \	'<Plug>(SearchAsQuickJumpNext)', '<Plug>(SearchAsQuickJumpPrev)',
    \   '/<S-CR>', 'q', 'quick', 'Quick search', '',
    \	2,
    \   {'hlsearch': 0}
    \)
catch /^Vim\%((\a\+)\)\=:E117:/	" catch error E117: Unknown function
endtry

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
