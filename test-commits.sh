PARENT=e7a254265f0c26c80fa1c04beb9eb14064f97d2f
CHILD=ff9301567e2702f2790bef14963975f99a96f766

PARENT_OUT=parent.txt
CHILD_OUT=child.txt

# Script assumes to be executed in sibling folder of analyzer and chrony

function build_comp_db {
	git clean -fdx
	./configure
	make -j 1 chronyd | tee build.log
	compiledb --parse build.log
}

function goto_chrony_dir {
	cd ../chrony
}

function goto_analyzer_dir {
	cd ../analyzer
}

function go_dir_up {
	cd ..
}

function checkout_and_build_commit {
	goto_chrony_dir
	git checkout $1
	build_comp_db
}

function run_goblint_parent {
	goto_analyzer_dir
	./goblint --conf conf/custom/chrony.json -v --disable incremental.load --enable incremental.save ../chrony &> $PARENT_OUT
}

function run_goblint_child {
	goto_analyzer_dir
	./goblint --conf conf/custom/chrony-incrpostsolver.json -v --enable incremental.load --disable incremental.save --enable incremental.reluctant.enabled ../chrony &> $CHILD_OUT
}

function do_parent {
	checkout_and_build_commit $PARENT
	run_goblint_parent
}

function do_child {
	checkout_and_build_commit $CHILD
	run_goblint_child
}

function do_parent_and_child {
	do_parent
	do_child
}

function check_for_issue_by_name_in_file {
	grep -i $1 $2
}

function check_file_for_fixpoint_issue {
	grep -i "Fixpoint" $1
}

function check_file_for_exception {
	grep -i "exception" $1
	grep -i "Called from" $1
}

function check_file_for_issues {
	check_file_for_fixpoint_issue $1
	check_file_for_exception $1
}

function check_parent_and_child {
	goto_analyzer_dir
	for i in $PARENT_OUT $CHILD_OUT; do
		check_file_for_issues $i
	done
	go_dir_up
}

function analyze_and_check_parent_and_child {
	do_parent_and_child
	check_parent_and_child
}

analyze_and_check_parent_and_child


