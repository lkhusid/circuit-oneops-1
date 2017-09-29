@test "ansible in path" {
	run which ansible
	[ "$status" -eq 0 ]
	[ "$output" = "/usr/bin/ansible" ]
}

@test "pip in path" {
	run which pip
	[ "$status" -eq 0 ]
}

@test "pip retry package" {
	run pip show retrying
	[ "$status" -eq 0 ]
}

@test "ansible roles directory" {
	run ls '/etc/ansible/roles'
	[ "$status" -eq 0 ]
}

@test "localhost host file" {
	run grep localhost /etc/ansible/hosts
	[ "$status" -eq 0 ]
}