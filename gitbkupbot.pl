#!/usr/bin/perl

sub getNonArchivedLocalBranches {
    #Ignore arc_ branches
    print "=======================================\n";
    my($path) = @_;
    print "Getting non-archived local branches in $path\n";

    my(@ret, $string);
    @ret = ();

    $string = `cd $path && git branch`;
    my(@branches) = split(' ', $string);
    
    foreach $branch (@branches) {
        if ($branch ne '*') {
            if ($branch =~ m/arc_/) {
                print "Ignore $branch\n";
            }
            else {
                push(@ret, $branch);
            }
        }
    }
    return @ret;
}

sub getAllLocalBranches {
    print "=======================================\n";
    my($path) = @_;
    print "Getting all local branches in $path\n";
    
    my(@ret, $string);
    @ret = ();

    $string = `cd $path && git branch`;
    my(@branches) = split(' ', $string);
    
    foreach $branch (@branches) {
        if ($branch ne '*') {
            push(@ret, $branch);
        }
    }
    return @ret;
}

sub getRemoteBranches {
    print "=======================================\n";
    my($path) = @_;
    print "Getting all remote branches in $path\n";

    my(@ret, $string);
    @ret = ();

    $string = `cd $path && git branch -r`;
    my(@branches) = split(' ', $string);
    
    foreach $branch (@branches) {
        if ($branch ne '*') {
            if ($branch =~ m/origin\/(.*)/) {
                push(@ret, $1);
            }
            else {
                print "Unknown remote branch: $test.\nExit.\n";
                exit;
            }
        }
    }
    
    return @ret;
}

sub cmpRemoteLocal {
    my($remote, $local) = @_;
    my(%count);
    %count = ();

    foreach $branch (@{$remote}) {$count{$branch} = 2;}
    foreach $branch (@{$local}) {$count{$branch}++;}

    foreach $branch (keys %count) {
        if ($count{$branch} == 2) {
            fetchNewRemoteBranch($branch);
        }
        elsif ($count{$branch} == 1) {
            archiveLocalBranch($branch);
        }
    }
}

sub fetchNewRemoteBranch{
    print "=======================================\n";
    my($branch) = @_;
    print "$workPath\$Fetching: origin/$branch\n"; 

    system("cd $workPath && git fetch origin $branch:$branch");
}

sub archiveLocalBranch {
    print "=======================================\n";
    my($branch) = @_;
    print "Archiving:$branch -> arc_$branch\n";

    system("cd $workPath && git checkout $branch && git branch arc_$branch");
    system("cd $workPath && git checkout master && git branch -d $branch");
}

sub sync {
    my($branches) = @_;
    foreach $branch (@{$branches}) {
        print "=======================================\n";
        system("cd $workPath && git checkout $branch"); 

        print "---------------------------------------\n";
        system("cd $workPath && git pull origin $branch");

        print "---------------------------------------\n";
        system("cd $backupPath && git checkout -b $branch");
        if ($? >> 8 != 0) {
            system("cd $backupPath && git checkout $branch");                
        }
        system("cd $backupPath && git checkout $branch");

        print "---------------------------------------\n";
        system("rsync -rav --delete --exclude .git/ $workPath $backupPath");

        print "---------------------------------------\n";
        system("cd $backupPath && git clean -f -d && git add . && git commit -m \"backup\"");
    }
}

sub checkPath {
    for ($i = 0; $i < $#_ + 1; $i++) {
        if (substr($_[$i], -1, 1) ne "/") {
            $_[$i] = $_[$i] . "/";
        }
    }
}

sub getArrayDiff {
    my ($arr1, $arr2) = @_;
    my (@diff, %count);
    %count = ();

    foreach $item (@{$arr1}, @{$arr2}) {$count{$item}++;}
    foreach $item (keys %count) {
        if ($count{$item} != 2) {
            push @diff, $item;
        }
    }
    return @diff;
}

# MAIN
if ($#ARGV != 1) {
    print "Usage: gitbkupbot working-dir backup-dir\n";
    exit;
}

$workPath = $ARGV[0];
$backupPath  = $ARGV[1];

&checkPath($workPath, $backupPath);

@remote = getRemoteBranches($workPath);
@local = getNonArchivedLocalBranches($workPath);

cmpRemoteLocal(\@remote, \@local);

@branches = getAllLocalBranches($workPath);
sync(\@branches);
