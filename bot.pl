#!/usr/bin/perl

sub getLocalBranches {
    # Param: $workPath
    my(@ret, $string, $workPath);
    @ret = ();
    $workPath = $_[0];

    $string = `cd $workPath && git branch`;
    my(@branches) = split(' ', $string);
    
    foreach $branch (@branches) {
        if ($branch ne '*') {
            push(@ret, $branch);
        }
    }
    return @ret;
}

sub sync {
    # Param: $workPath, $backupPath, @branches
    foreach $branch (@_[2..$#_]) {
        my($workPath, $backupPath);
        $workPath = $_[0];
        $backupPath = $_[1];

        system("cd $workPath && git checkout $branch"); 
        print "---------------------------------------\n\n";

        system("cd $workPath && git pull origin $branch");
        print "---------------------------------------\n\n";

        system("cd $backupPath && git checkout $branch");
        print "---------------------------------------\n\n";

        system("rsync -rav --delete --exclude .git/ $workPath $backupPath");
        print "---------------------------------------\n\n";

        system("cd $backupPath && git add . && git commit -m \"backup\" && git clean -f -d");
        print "---------------------------------------\n\n";
    }
}

sub checkPath {
    # Param: @paths
    for ($i = 0; $i < $#_ + 1; $i++) {
        if (substr($_[$i], -1, 1) ne "/") {
            $_[$i] = $_[$i] . "/";
        }
    }
}

if ($#ARGV != 1) {
    print "Usage: gitbkup working-dir backup-dir\n";
    exit;
}

$workPath = $ARGV[0];
$backupPath  = $ARGV[1];

&checkPath($workPath, $backupPath);
sync($workPath, $backupPath, getLocalBranches($workPath));
