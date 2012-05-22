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
                print "$branch \t";
            }
        }
    }
    print "\n";

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
            print "$branch \t";
        }
    }
    print "\n";

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
                if ($1 eq "HEAD") {
                    print "Ignore HEAD\n";
                }
                else {
                    push(@ret, $1);
                }
            }
            else {
                print "Unknown remote branch: $branch.\n";
            }
        }
    }

    #Clean up duplication (HEAD -> master and master)
    my %hash   = map { $_ => 1 } @ret;
    my @unique = keys %hash;

    foreach $branch (@unique) {
        print "$branch \t";
    }
    print "\n";
    
    return @unique;
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
    system("cd $workPath && git checkout master && git branch -D $branch");
    system("cd $backupPath && git checkout master && git branch -D $branch && git push origin :$branch");
}

sub sync {
    my($branches) = @_;
    foreach $branch (@{$branches}) {
        print "=======================================\n";
        system("cd $workPath && git checkout $branch"); 

        print "---------------------------------------\n";
        if (!($branch =~ m/arc_/)) {
            system("cd $workPath && git pull origin $branch");
        }

        print "---------------------------------------\n";
        system("cd $backupPath && git checkout -b $branch");
        if ($? >> 8 != 0) {
            system("cd $backupPath && git checkout $branch");                
        }
        system("cd $backupPath && git checkout $branch");

        print "---------------------------------------\n";
        print ("rsync -rav --delete --exclude .git/ $workPath $backupPath");

        system("rsync -rav --delete --exclude .git/ $workPath $backupPath");

        print "---------------------------------------\n";
        system("cd $backupPath && git add . && git add -u && git commit -m \"backup\"");
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

sub pushBackupToRemote {
    print "=======================================\n";
    print "Pushing backup git to remote\n"; 
    my(@branches);
    @branches = getAllLocalBranches($backupPath);
    foreach $branch (@branches) {
        print "---------------------------------------\n";
        print "Pushing $branch\n";
        system("cd $backupPath && git push origin $branch");
    }
}

sub gitFetchRemoteInfo {
    my($path) = @_;
    print "=======================================\n";
    print "Fetch remote branches info in $path\n";
    system("cd $path && git fetch && git remote prune origin");
}


# MAIN
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
printf "%02d:%02d:%02d %02d\/%02d\/%04d\n", $hour, $min, $sec, $mon + 1, $mday, $year + 1900;

if ($#ARGV != 1) {
    print "Usage: gitbkupbot working-dir backup-dir\n";
    exit;
}

$workPath = $ARGV[0];
$backupPath  = $ARGV[1];

&checkPath($workPath, $backupPath);

gitFetchRemoteInfo($workPath);

@remote = getRemoteBranches($workPath);
@local = getNonArchivedLocalBranches($workPath);

cmpRemoteLocal(\@remote, \@local);

@branches = getAllLocalBranches($workPath);
sync(\@branches);
pushBackupToRemote();

print "**************************************\n";
print "END OF BACKUP\n\n";
