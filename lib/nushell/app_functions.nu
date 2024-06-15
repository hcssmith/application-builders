
def "app init-lua" [] {
which nvim | select path | get 0 | open $in.path | lines | where ($it | str contains 'init.lua') 
		| $in.0 | split column " " | select column5 | get 0 
		| $in.column5
}


def "app packpath" [
	init?: string
] {
	mut il = $init
	if ($il == null) {
		$il = (app init-lua)
	}
	open $il | lines | where ($it | str contains 'pack') 
		| $in.0 | split column " " | get 0 | select column3 
		| $in.column3 | str trim -r -l -c "'"	
	}

