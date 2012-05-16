#!/usr/bin/perl
$WORKING_PATH="working-dir/";
$BACKUP_PATH="backup-dir/";

sub getLocalBranches {
    @ret = ();

    $string = `cd $WORKING_PATH && git branch`;
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
        print "---------------------------------------\n";
        system("cd $WORKING_PATH && git checkout $branch"); 
        print "---------------------------------------\n\n";

        print "---------------------------------------\n";
        system("cd $BACKUP_PATH && git checkout $branch");
        print "---------------------------------------\n\n";

        print "---------------------------------------\n";
        system("rsync -rav --delete --exclude .git/ $WORKING_PATH $BACKUP_PATH");
        print "---------------------------------------\n\n";

        print "---------------------------------------\n";
        system("cd $BACKUP_PATH && git add . && git commit -m \"backup\" && git clean -f -d");
        print "---------------------------------------\n\n";
    }
}

sync(getLocalBranches());
