#!/usr/bin/perl
$WORKING_PATH="./working-git";
$BACKUP_PATH="./backup-git";
$GIT_WORKING_PATH=$WORKING_PATH . "/.git";
$GIT_BACKUP_PATH=$BACKUP_PATH . "/.git";

sub getLocalBranches {
    @ret = ();

    $string = `git --git-dir $GIT_WORKING_PATH branch`;
    @branches = split(' ', $string);
    
    foreach $branch (@branches) {
        if ($branch ne '*') {
            push(@ret, $branch);
        }
    }
    return @ret;
}

sub sync {
    foreach $branch (@_) {
        system("git --git-dir $GIT_WORKING_PATH checkout $branch");
        system("git --git-dir $GIT_BACKUP_PATH checkout $branch");
        system("cp $WORKING_PATH/* $BACKUP_PATH");
        system("git --git-dir $GIT_BACKUP_PATH add .");
        system("git --git-dir $GIT_BACKUP_PATH commit -m \"backup\"");
    }
}

sync(getLocalBranches());
