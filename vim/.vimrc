"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set history=500

filetype plugin on
filetype indent on

" Auto read when a file is changed from the outside
set autoread
au FocusGained,BufEnter * silent! checktime

" Space is the leader: layout independent, and a thumb press on any keyboard.
" On Programmer Dvorak the usual ',' sits where QWERTY 'w' is, which is worse.
let mapleader = " "
nnoremap <Space> <Nop>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keep 7 lines visible above and below the cursor
set so=7

" Command-line completion: longest common prefix first, then a popup menu.
" This is what makes ":b <fragment><Tab>" a usable buffer picker.
set wildmenu
set wildmode=longest:full,full
set wildoptions=pum
set wildcharm=<C-z>

" Ignore compiled files in wildcard expansion
set wildignore=*.o,*.obj,*.a,*.so,*.d,*~,*.pyc
set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/__pycache__/*,*/build/*

" Always show current position
set ruler
set cmdheight=1

" Keep modified buffers loaded when they are not displayed. This is the
" setting that makes working out of buffers instead of :q/:e possible.
set hidden

" Let backspace delete over autoindent, line breaks and the insert start point
set backspace=eol,start,indent

" Let h/l and the arrow keys move across line boundaries
set whichwrap+=<,>,h,l

" Case-insensitive search unless the pattern contains a capital
set ignorecase
set smartcase

set hlsearch
set incsearch

" Don't redraw while executing macros
set lazyredraw

set magic

" No bells of any kind
set belloff=all

" Always reserve the sign column so text does not shift when a diagnostic
" sign appears or clears
set signcolumn=yes

set number
set relativenumber


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax enable

if has('termguicolors')
  set termguicolors
endif
set background=dark
let g:everforest_colors_override = {'bg0': ['#1a1a1a', '234'], 'bg1' : ['#232323', '235']}
colorscheme everforest

set encoding=utf8
set ffs=unix,dos,mac


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nobackup
set nowb
set noswapfile

" The only recovery path left with no swap and no backup. Undo history
" survives closing a file. install.sh creates ~/.vim/undo.
set undofile
set undodir=~/.vim/undo
set undolevels=1000


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Text, tab and indent
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

" Break wrapped lines at word boundaries rather than mid-word
set lbr

" Don't carry the comment leader onto a new line opened with o/O
autocmd FileType * setlocal formatoptions-=o


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Completion
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Popup menu even for a single match, don't insert until chosen
set completeopt=menuone,noselect,popup

" Cap popup height
set pumheight=12

" Fall back to syntax-based omni completion for filetypes without one.
" C/C++ and Python get a real language server instead, see after/plugin/lsp.vim
autocmd FileType * if &omnifunc ==# '' | setlocal omnifunc=syntaxcomplete#Complete | endif

" Tab accepts a match outright instead of cycling. The LSP plugin hard-codes
" 'noselect' in its buffers, so nothing is highlighted on the first press and
" Tab has to select the first match before taking it. pumvisible() is false
" with no popup open, so Tab still indents normally.
function! TabComplete() abort
    if !pumvisible()
        return "\<Tab>"
    endif
    return complete_info(['selected']).selected == -1 ? "\<C-n>\<C-y>" : "\<C-y>"
endfunction

inoremap <expr> <Tab>   TabComplete()
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Don't spam "match 1 of 12" in the message line
set shortmess+=c

" Diagnostics feel stale above this; it also drives CursorHold
set updatetime=300


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Moving around, windows and buffers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Visual mode * and # search for the current selection
vnoremap <silent> * y:let @/ = '\V' . escape(@", '\/')<CR>:set hlsearch<CR>n
vnoremap <silent> # y:let @/ = '\V' . escape(@", '\/')<CR>:set hlsearch<CR>N

" Clear search highlight
nnoremap <silent> <leader><CR> :nohlsearch<CR>

" Move between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Buffers. '[' and ']' are unshifted on the number row in Programmer Dvorak,
" which makes bracket pairs the cheapest prefix available on this layout.
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]B :blast<CR>
nnoremap <silent> [B :bfirst<CR>

" Jump to a buffer by name fragment; <C-z> opens the wildmenu popup
nnoremap <leader>b :buffer <C-z>
nnoremap <leader>l :ls<CR>

" Toggle to the alternate buffer, the buffer-workflow equivalent of Alt-Tab
nnoremap <silent> <leader><leader> :buffer #<CR>

" Close the current buffer without closing its window
nnoremap <silent> <leader>d :Bclose<CR>

set switchbuf=useopen,usetab

" Return to last edit position when opening files
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Status line
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set laststatus=2

" Short enough to stay readable in a vertical split, with room on the right
" for the LSP diagnostic counts. Filename tail only, not the full path.
set statusline=\ %{HasPaste()}%t\ %m%r%h%w%=%#ErrorMsg#%{LspDiagStatus()}%*%y\ \ %l:%c\ \ %P


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editing mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Delete trailing whitespace on save
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

autocmd BufWritePre *.txt,*.js,*.py,*.wiki,*.sh,*.coffee,*.c,*.cc,*.cpp,*.cxx,*.h,*.hh,*.hpp,*.hxx,*.vim,.vimrc,vimrc,*.md,*.json,*.yml,*.yaml call CleanExtraSpaces()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Spell checking
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ]s [s zg z= are the built-ins; this just toggles the mode
nnoremap <silent> <leader>s :setlocal spell!<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction

" Error and warning counts for the status line, e.g. "E3 W1 ".
function! LspDiagStatus() abort
    let c = lsp#lsp#ErrorCount()
    let s = ''
    if c.Error > 0 | let s .= 'E' . c.Error . ' ' | endif
    if c.Warn > 0  | let s .= 'W' . c.Warn . ' ' | endif
    return s
endfunction

" Don't close the window when deleting a buffer
command! Bclose call <SID>BufcloseCloseIt()
function! <SID>BufcloseCloseIt()
    let l:currentBufNum = bufnr("%")
    let l:alternateBufNum = bufnr("#")

    if buflisted(l:alternateBufNum)
        buffer #
    else
        bnext
    endif

    if bufnr("%") == l:currentBufNum
        new
    endif

    if buflisted(l:currentBufNum)
        execute("bdelete! ".l:currentBufNum)
    endif
endfunction
