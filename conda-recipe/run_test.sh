#!/bin/bash
set -euo pipefail

# Every binary and a helper script must be installed.
for prog in cd-hit cd-hit-est cd-hit-2d cd-hit-est-2d cd-hit-div cd-hit-454 clstr_rev.pl; do
    test -x "${PREFIX}/bin/${prog}"
done

# Usage exits with status 1 by design, so capture it before checking for -det.
cd-hit > usage.txt 2>&1 || true
grep -q -- "-det" usage.txt

# Deterministic synthetic families: 400 parents x 6 mutated children.
perl -e '
    srand(1); my @aa = split //, "ACDEFGHIKLMNPQRSTVWY"; my $n = 0;
    for my $f (1..400) {
        my @p = map { $aa[int rand 20] } 1..(80 + int rand 300);
        for my $c (1..6) {
            my @s = map { rand() < 0.07 ? $aa[int rand 20] : $_ } @p;
            print ">s", $n++, "\n", join("", @s), "\n";
        }
    }' > prot.fa
tr 'DEFHIKLMNPQRSVWY' 'AGTCAGTCAGTCAGTC' < prot.fa | sed 's/^>s/>d/' > dna.fa

# Multi-threaded runs with -det 1 must give identical .clstr files.
cd-hit -i prot.fa -o a -c 0.9 -n 5 -T 2 -det 1 > a.log
cd-hit -i prot.fa -o b -c 0.9 -n 5 -T 2 -det 1 > b.log
cmp a.clstr b.clstr
grep -q "(+OpenMP)" a.log

# With -g 1 the result must not depend on the thread count.
cd-hit -i prot.fa -o g1 -c 0.9 -n 5 -g 1 -T 1 -det 1 > /dev/null
cd-hit -i prot.fa -o g2 -c 0.9 -n 5 -g 1 -T 2 -det 1 > /dev/null
cmp g1.clstr g2.clstr

cd-hit-est -i dna.fa -o e -c 0.95 -n 8 -T 2 -det 1 > /dev/null
test -s e.clstr
