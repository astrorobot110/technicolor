scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpo&vim

" グローバル変数 {{{1
" RGB値でのグレーがctermパレットのグレースケール以外にあった場合用
let s:gray2color = {
		\ '95': 59,
		\ '135': 102,
		\ '175': 145,
		\ '215': 188
		\ }

" ctermパレットからRGB値への変換用
let s:rgbValue = ['00', '5f', '87', 'af', 'd7', 'ff']

" cterm/guiのインバーター (めんどかった)
let s:targetDict = {'cterm': 'gui', 'gui': 'cterm'}

" vimが解釈する色名のリスト
let s:colorName = [
		\ 'none', 'bg', 'BackGround', 'fg', 'ForeGround', 'Black',
		\ 'DarkRed', 'DarkGreen', 'DarkYellow', 'Brown', 'DarkBlue', 'DarkMagenta', 'DarkCyan', 'Gray', 'Grey',
		\ 'DarkGray', 'DarkGrey', 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan', 'White',
		\ 'LightGray', 'LightGrey', 'lightRed', 'LightGreen', 'LightYellow', 'LightBlue', 'LightMagenta', 'LightCyan'
		\ ]

" gVimのみ解釈する色名のcterm近似色
let s:name2cterm = {
		\ 'orange': 214,
		\ 'purple': 129,
		\ 'violet': 213,
		\ 'seagreen': 29,
		\ 'slateblue': 62
		\ }

" highlightコマンド記述の構造テンプレ
let s:technicolorTemplate = {
		\ 'order': ['ctermfg', 'ctermbg', 'cterm', 'guifg', 'guibg', 'gui'],
		\ 'orderLength': [16, 16, 16, 16, 16, 0],
		\ 'head': 'highlight',
		\ 'headLength': 24,
		\ 'indent': '',
		\ 'space': "\t",
		\ 'isUppercase': 0,
		\ 'isStructured': 1
		\ }

" ハイライトテンプレに関して {{{2

"	technicolorではハイライトの構造を確認するために…
"		1. 現在のカーソル位置から上に検索して、直近の空行の下にあるハイライトコマンドの構造
"		2. Normalグループの記述の構造
"		3. 辞書変数 `b:technicolorTemplate`による定義
"		4. 上記辞書変数 `s:technicolorTemplate`による定義
"	…の順に記述があるものを確認しています。
"	この場合、1.に該当するのにテンプレートとして機能しないケースが存在します。
"	そのために現在の行が参照してほしいテンプレートを…
"
"		> " technicolor		ctermfg=15		ctermbg=0		cterm=none		guifg=#FFFFFF		guibg=#000000	gui=none
"
"	…のように、行頭が `" technicolor` の行をハイライトコマンドの記述とみなして使用します。
"	この際 `guifg` `guibg`の記述に大文字が含まれているかどうかをチェックしています。
"	RGB値の記述の大文字、小文字の指定はここで行なえます。
"	`b:technicolorTemplate`は上記の `s:technicolorTemplate` の行をコピーして使うのが当座簡単かなとおもいます。
" }}}

"}}}

" technicolor#gui2cterm(): guiからctermへ変換 (システムカラーへは変換しない) {{{1
function! technicolor#gui2cterm(guiColor) abort
	if a:guiColor =~ '^#\?\x\{6}$'
		let rgbList = matchlist(a:guiColor, '\v^#(\x\x)(\x\x)(\x\x)')[1:3]
				\ ->map({_, val ->str2nr(val, 16)})

		if len(uniq(copy(rgbList))) == 1
			return s:gray2cterm(rgbList[0])
		endif

		return s:rgb2cterm(rgbList)
	elseif has_key(s:name2cterm, tolower(a:guiColor))
		return s:name2cterm[tolower(a:guiColor)]
	elseif match(s:colorName, '^'..a:guiColor..'$') > 0
		return a:guiColor
	else
		return 'none'
	endif
endfunction

" s:rgb2cterm(): RGB値からctermへ変換 {{{2
function! s:rgb2cterm(rgbList) abort
	for value in a:rgbList
		let ctermColor = get(l:, 'ctermColor', 0)*6
		if value >= 75
			let ctermColor += ((value-75)/40)+1
		endif
	endfor

	return ctermColor+16
endfunction
" }}}

" s:gray2cterm() RGB値がグレーになる場合 {{{2
function! s:gray2cterm(level) abort
	if a:level <= 3
		return 16
	elseif a:level >= 243
		return 231
	elseif has_key(s:gray2color, a:level)
		return s:gray2color[a:level]
	endif

	let step = sort([0, (a:level-3)/10, 23], 'n')[1]

	return step+232
endfunction
" }}}

" }}}

" technicolor#cterm2gui(): ctermからguiへ変換 {{{1
function! technicolor#cterm2gui(ctermColor) abort
	if a:ctermColor < 0 || a:ctermColor > 255
		return 'none'
	elseif a:ctermColor <= 15
		return s:term2sysRgb(a:ctermColor)
	elseif a:ctermColor >= 232
		return s:term2gray(a:ctermColor-232)
	elseif str2nr(a:ctermColor) > 0
		return s:term2rgb(a:ctermColor-16)
	elseif match(s:colorName, '^'..a:ctermColor..'$') > 0
		return a:ctermColor
	endif
	return 'none'
endfunction

" s:term2sysRgb(): xtermシステムカラーからRGB値へ変換 {{{2
function! s:term2sysRgb(termColor) abort
	if a:termColor == 7
		return '#c0c0c0'
	elseif a:termcolor == 8
		return '#808080'
	elseif a:termcolor < 7
		let value = '80'
	else
		let value = 'ff'
	endif

	let rgb = '#'

	for div in [1, 2, 4]
		let rgb .= (a:termColor/div)%2 == 0 ? '00' : value
	endfor

	return rgb
endfunction
" }}}

" s:term2gray(): xtermパレットのグレースケールからRGB値へ変換 {{{2
function! s:term2gray(termColor) abort
	let rgb = printf('%02x', a:termColor*10+8)
	return '#'..repeat(rgb, 3)
endfunction
" }}}

" s:term2rgb(): xtermカラーパレットからRGB値へ変換 {{{2
function! s:term2rgb(termColor) abort
	let rgb = '#'

	for div in [36, 6, 1]
		let rgb .= s:rgbValue[(a:termColor/div)%6]
	endfor

	return rgb
endfunction
" }}}

" }}}

" s:getStructure(): スクリプト内highlightの記述解析 {{{1
function! s:getStructure() abort
	let span = {
			\ 'start': line('.') == 1 ? 1 : search('^$', 'nb'),
			\ 'end': search('^$', 'n')
			\ }

	while get(l:, 'isMatch', -1) < 0
		let span.start += 1

		let isMatch = match(getline(span.start), '\v\c^\s*(hi(ghlight)?\!?|"\s?technicolor)', '')
		if span.start == line('.')
			let span.start = line('.')
			let span.end = line('.')+1

			break
		endif
	endwhile

	let normalGroup = search('^hi\(ghlight\)\?!\?\s\cnormal', 'nw')

	if isMatch >= 0
		let line = getline(span.start)
	elseif normalGroup >= 0
		let line = getline(normalGroup)
	endif

	if exists('line')
		let commands = split(line, '\S*\s*\zs')

		let technicolor = {
				\ 'isUppercase': 0,
				\ 'isStructured': 0,
				\ 'order': [],
				\ 'orderLength': []
				\ }

		for args in commands
			if args =~# '^\s*$'
				let indent = args
				let technicolor.indent = args

				continue

			elseif args =~# '^hi\(ghlight\)\?!\?'
				if !exists('indent')
					let technicolor.indent = ''
				endif

				let technicolor.head = matchstr(args, '^hi\(ghlight\)\?')
				let headText = args

			elseif exists('headText')
				if args =~# '\(link\|clear\)'
					let technicolor = get(b:, 'technicolorTemplate', s:technicolorTemplate)
					let technicolor.indent = matchstr(getline('.'), '^\s*')
					let technicolor.head = matchstr(headText, '^\S\+')

					let span.start = line('.')
					let span.end = line('.')+1

					break
				endif

				let technicolor.space = args[-1:]
				let headText .= args
				let technicolor.headLength = strdisplaywidth(headText)
				unlet headText

			elseif match(args, '^\S\+=\S\+\s\?') >= 0
				let key = matchstr(args, '\S\+\ze=')
				call add(technicolor.order, key)

				if args =~# '\s$'
					call add(technicolor.orderLength, strdisplaywidth(args))
				else
					call add(technicolor.orderLength, 0)
				endif

				if !technicolor.isUppercase && key =~? 'gui\(fg\|bg\)'
					let technicolor.isUppercase = matchstr(args, '=\zs#\x') =~# '\u'
				endif
			endif

			if !technicolor.isStructured && matchstr(args, '\s*$') != ' '
				let technicolor.isStructured = 1
			endif
		endfor
	else
		let technicolor = get(b:, 'technicolorTemplate', s:technicolorTemplate)
	endif

	let technicolor.span = span

	return technicolor
endfunction

" main {{{1
function! technicolor#main(args) abort
	if !exists('b:technicolor') || sort(values(b:technicolor.span) + [line('.')], 'n')[1] != line('.')
		let b:technicolor = s:getStructure()
	endif
	let tabstop = b:technicolor.space ==# "\t" ? &tabstop : 1

	let [env, ground, value] = matchlist(a:args, '\v(cterm|gui)(fg|bg|)\=(.+)')[1:3]
	let target = s:targetDict[tolower(env)]

	if ground != ''
		let targetValue = funcref(printf('technicolor#%s2%s', env, target))(value)
	else
		let targetValue = value
	endif

	let line = getline('.')

	let group = matchstr(line, 'hi\(ghlight\)\?!\? \zs\S*\ze')

	let output = b:technicolor.indent..b:technicolor.head..' '..group

	while strdisplaywidth(output) < b:technicolor.headLength
		let output .= b:technicolor.space
	endwhile

	let args = {}
	let index = 1
	while match(line, '\s\zs\S\+=\S\+', 0, index) >= 0
		let [argKey, argValue] = matchlist(line, '\s\zs\(\S\+\)=\(\S\+\)', 0, index)[1:2]
		let args[argKey] = argValue
		let index += 1
	endwhile

	let args[env..ground] = value
	let args[target..ground] = targetValue

	let index = 0
	while index < len(b:technicolor.order)
		if has_key(args, b:technicolor.order[index])
			let argKey = b:technicolor.order[index]
			let argValue = args[b:technicolor.order[index]]
			if argKey =~# 'gui\(fg\|bg\)' && b:technicolor.isUppercase
				let argValue = toupper(argValue)
			endif
			let currentArg = printf('%s=%s', argKey , argValue)
		else
			let currentArg = ''
		endif

		while strdisplaywidth(currentArg) < b:technicolor.orderLength[index]
			let currentArg .= b:technicolor.space
		endwhile

		let output .= currentArg
		let index += 1
	endwhile

	let output = substitute(output, '\s\+$', '', 'e')
	let column = match(output, 'hi\(ghlight\)\?!\? \zs')

	if line =~# '^\s*hi\(ghlight\)\?' || line ==# ''
		call setline(line('.'), output)
		if line ==# ''
			call setpos('.', [ bufnr(), line('.')+1, column+1, 0])
		endif
	else
		let currentLine = line('.')
		call append(currentLine-1, output)
		call setpos('.', [ bufnr(), currentLine, column+1, 0])
	endif
endfunction
" }}}

let &cpoptions = s:save_cpo

" vim: set fdm=marker:
