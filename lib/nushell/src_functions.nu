 def "src init" [
	--application (-a)
] {
	git init
	nix flake init
	fh add github:hcssmith/flake-lib
	if $application {
		fh add github:hcssmith/application-builders
	}
}

def "src github" [
	repo:string
	--owner (-o) = hcssmith
	] {
	git remote add origin $'git@github.com:($owner)/($repo).git'
}

def "src commit" [
	message: string
] {
	git commit -m $'"($message)"'
}

def "src push" [] {
	git push -u origin master
}
