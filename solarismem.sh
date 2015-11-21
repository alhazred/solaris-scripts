#/bin/sh
#
# korolev-ia [at] yandex.ru
# fast eye to memory on solaris
# v1.0 29.09.2009

kstat -n system_pages | nawk 'BEGIN{ "/usr/bin/pagesize" | getline pgsize ; } /physmem/ { print "Physical memory = " $2 * pgsize/1073741824 "Gb"}'

kstat -n system_pages | nawk 'BEGIN{ "/usr/bin/pagesize" | getline pgsize ; } /pp_kernel/ { print "Kernel memory = " $2 * pgsize/1073741824 "Gb"}'

ipcs -mb | awk '/^m/ {sm=sm+$7}END{ print "Shared memory " sm/1073741824 "Gb"}'

kstat -n system_pages | nawk 'BEGIN{ "/usr/bin/pagesize" | getline pgsize ; } /freemem/ { print "Free memory = " $2 * pgsize/1073741824 "Gb"}'