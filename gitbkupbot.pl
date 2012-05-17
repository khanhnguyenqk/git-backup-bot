#!/usr/bin/perl

sub getLocalBranches {
    my($workPath) = @_;
    my(@ret, $string);
    @ret = ();

    $string = `cd $workPath && git branch`;
    my(@branches) = split(' ', $string);
    
    foreach $branch (@branches) {
        if ($branch ne '*') {
            push(@ret, $branch);
        }
    }
    return @ret;
}

sub getRemoteBranches {
    my($workPath) = @_;
    my(@ret, $string);
    @ret = ();

    $string = `cd $workPath && git branch -r`;
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

sub sync {
    my($branches, $workPath, $backupPath) = @_;
    foreach $branch (@{$branches}) {
        print "=======================================\n";


        system("cd $workPath && git checkout $branch"); 
        print "---------------------------------------\n";
        system("cd $workPath && git pull origin $branch");
        print "---------------------------------------\n";
        system("cd $backupPath && git checkout $branch");
        print "---------------------------------------\n";
        system("rsync -rav --delete --exclude .git/ $workPath $backupPath");
        print "---------------------------------------\n";
        system("cd $backupPath && git add . && git commit -m \"backup\" && git clean -f -d");
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

if ($#ARGV != 1) {
    print "Usage: gitbkupbot working-dir backup-dir\n";
    exit;
}

$workPath = $ARGV[0];
$backupPath  = $ARGV[1];

&checkPath($workPath, $backupPath);
@remote = getRemoteBranches($workPath);
@local = getLocalBranches($workPath);
print getArrayDiff(\@remote, \@local); 
#@branches = getLocalBranches($workPath);
#sync(\@branches, $workPath, $backupPath);
