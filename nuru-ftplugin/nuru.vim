
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Comment settings
setlocal commentstring=//%s
setlocal comments=://,s1:/*,mb:*,ex:*/

" Indentation
setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal expandtab
setlocal autoindent
setlocal smartindent

" File encoding
setlocal fileencoding=utf-8

nnoremap <buffer> <silent> <leader>r :w<CR>:!nuru "%"<CR>
nnoremap <buffer> <silent> <leader>R :w<CR>:botright split \| resize 15 \| terminal nuru "%"<CR>
nnoremap <buffer> <silent> <F5> :w<CR>:!nuru "%"<CR>

command! -buffer Nuru write | !nuru "%"
command! -buffer NuruTerm write | botright split | resize 15 | terminal nuru "%"
command! -buffer NuruRepl botright split | resize 15 | terminal nuru

let b:undo_ftplugin = "setlocal commentstring< comments< tabstop< shiftwidth< softtabstop< expandtab< autoindent< smartindent<"
