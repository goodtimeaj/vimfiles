" vim: ts=2 sts=2 sw=2 expandtab:
"
" Customizations are organized into logical sections. Mappings are organized
" by section.
"
" Thanks:
" @necolas
" @sickill
" @nelstrom
" @mathiasbynens
" @rtomayko

" =============================================================================
" Editing
" =============================================================================

" Enable mouse in all modes
set mouse=a

" =============================================================================
" Appearance
" =============================================================================

" Use console dialogs instead of popup dialogs
set guioptions+=c

" Inactive menu items are grey
set guioptions+=e

" Show menu bar
set guioptions+=m

" Hide toolbar
set guioptions-=T

" Don't use Aqua scrollbars
set guioptions-=rL

" Smooth fonts
set antialias

" Increase font size for (MacVim default: 11)
set guifont=Menlo\ Regular:h14

" Increase line-height (default: 0)
set linespace=1

" No visual or audio bells
set vb t_vb=

" Starting window position at top left
winpos 0 0

" Turn off the blinking cursor in normal mode
set gcr=n:blinkon0

" Tab tooltip format
set guitabtooltip=%F

" Tab label format
set guitablabel=%N\ %t\ %m
