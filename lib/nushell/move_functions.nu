def --env "mp" [
	--projects (-p) = ~/Projects
] {
	let p = ($projects | path expand)

	ls $'($p)' -s | where type == 'dir' | get name | to text | fzf --height 60% --layout reverse --border --tmux | cd $'($p)/($in)'
}
