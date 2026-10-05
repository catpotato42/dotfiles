vim9script
# Language server setup: completion and diagnostics for C/C++ and Python.
#
# This lives in after/plugin/ rather than .vimrc on purpose. Packages under
# pack/*/start are sourced AFTER .vimrc finishes, so g:LspOptionsSet() and
# g:LspAddServer() do not exist yet while .vimrc runs. after/plugin/ is sourced
# last, and the User LspSetup autocmd fires at VimEnter, later still.

var lspOpts = {
  # Completion
  autoComplete: true,
  # Also route manual <C-x><C-o> through the server. Without this, omnifunc
  # stays on the ftplugin default (ccomplete) and manual omni-completion
  # silently bypasses clangd.
  omniComplete: true,
  completionMatcher: 'fuzzy',
  noNewlineInCompletion: true,

  # Diagnostics: sign in the gutter, inline highlight, popup on cursor hold.
  # Virtual text is off because it reflows C++ lines that are already long.
  autoHighlightDiags: true,
  highlightDiagInline: true,
  showDiagWithSign: true,
  showDiagInPopup: true,
  showDiagWithVirtualText: false,

  # Signature help while typing a call
  showSignature: true,
  showSignatureDocs: true,

  # K falls through to 'keywordprg' (man) when the server has no hover text,
  # so taking K for LspHover does not cost man-page lookup in C.
  hoverFallback: true,

  usePopupInCodeAction: true,
  popupBorder: true,
}
autocmd User LspSetup g:LspOptionsSet(lspOpts)

var servers = [
  {
    name: 'clangd',
    filetype: ['c', 'cpp'],
    path: 'clangd',
    args: [
      '--background-index',
      '--clang-tidy',
      '--completion-style=detailed',
      '--header-insertion=never',
      '--pch-storage=memory',
    ],
    rootSearch: ['compile_commands.json', 'compile_flags.txt', '.clangd',
                 'CMakeLists.txt', '.git/'],
  },
  {
    name: 'pylsp',
    filetype: ['python'],
    path: 'pylsp',
    args: [],
    rootSearch: ['pyproject.toml', 'setup.py', 'setup.cfg', '.git/'],
    workspaceConfig: {
      pylsp: {
        plugins: {
          # ruff replaces pycodestyle/pyflakes/mccabe and is much faster
          ruff: {enabled: true},
          pycodestyle: {enabled: false},
          pyflakes: {enabled: false},
          mccabe: {enabled: false},
          jedi_completion: {include_params: true, fuzzy: true},
        },
      },
    },
  },
]
autocmd User LspSetup g:LspAddServer(servers)

# Buffer-local mappings, only in buffers a server actually attached to.
# gd is taken deliberately: the built-in gd is a textual search for the word
# under the cursor within the current function, not a semantic definition jump.
autocmd User LspAttached {
  nnoremap <buffer> <silent> gd      <Cmd>LspGotoDefinition<CR>
  nnoremap <buffer> <silent> gD      <Cmd>LspGotoDeclaration<CR>
  nnoremap <buffer> <silent> gi      <Cmd>LspGotoImpl<CR>
  nnoremap <buffer> <silent> gy      <Cmd>LspGotoTypeDef<CR>
  nnoremap <buffer> <silent> gr      <Cmd>LspShowReferences<CR>
  nnoremap <buffer> <silent> K       <Cmd>LspHover<CR>

  # Bracket pairs: cheap on Programmer Dvorak, [ and ] are unshifted there
  nnoremap <buffer> <silent> ]d      <Cmd>LspDiagNextWrap<CR>
  nnoremap <buffer> <silent> [d      <Cmd>LspDiagPrevWrap<CR>

  nnoremap <buffer> <silent> <leader>e  <Cmd>LspDiagCurrent<CR>
  nnoremap <buffer> <silent> <leader>E  <Cmd>LspDiag show<CR>
  nnoremap <buffer> <silent> <leader>rn <Cmd>LspRename<CR>
  nnoremap <buffer> <silent> <leader>c  <Cmd>LspCodeAction<CR>
  nnoremap <buffer> <silent> <leader>o  <Cmd>LspOutline<CR>
  nnoremap <buffer>          <leader>f  <Cmd>LspFormat<CR>
  xnoremap <buffer>          <leader>f  :LspFormat<CR>

  # clangd extension: jump between a .cpp and its header
  nnoremap <buffer> <silent> <leader>a <Cmd>LspSwitchSourceHeader<CR>
}
