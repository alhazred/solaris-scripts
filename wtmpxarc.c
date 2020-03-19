/*
 * wtmpxarc.c
 *  Copyright (c) 2001
 *       Bitt Faulk, except the parts that aren't (see the ``STEAL'' tag below)
 *
 * gcc -Wall -Wno-comments wtmpxarc.c -o wtmpxarc
 *
 * wtmpxarc [offset]
 *
 * rotates wtmpx file, leaving last offset days, or OFFSET if not specified
 *
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <utmpx.h>

/* this is the standard place in Solaris */
#define WTMPX "/var/adm/wtmpx"
/* must *end* in 6 X's for use with mktemp() and mkstemp()
 * must also be on the same filesystem as WTMPX above */
#define WTMPX_TMP "/var/adm/wtmpx.XXXXXX"
/* must end in .0 and be in the same filesystem as WTMPX */
#define WTMPX_ARC "/var/adm/wtmpx.0"
/* must be a single digit <-- lazy */
#define MAX_ARCHIVES (7)

#define OFFSET ((time_t)(45))
#define SECONDS_IN_DAY (24 * 60 * 60)

/* this is standard for Solaris, and probably most Unices */
#define WTMP_PERMS (0644)

#define TRUE (1)
#define FALSE (0)

/* translate a *digit* to its ascii representation */
#define ITOC(i) (i+'0')

void usage(int argc, char **argv, int err) {
	fprintf(stderr, "Usage: %s [days]\n", argv[0]);
	if (err >= 0) {
		exit(err);
	}
}

/* mv only works in the same filesystem */
int mv(const char *from, const char *to) {
	int ret, tmperrno;

	if ((ret = link(from, to)) < 0) {
		return(ret);
	}
	if ((ret = unlink(from)) < 0) {
		tmperrno = errno;
		unlink(to);   /* Try to move original file back */
		errno = tmperrno;
		return(ret);
	}
	return(TRUE);
}

/* mvf deletes the to file before mv-ing it.  Must be in the same filesystem */
int mvf(const char *from, const char *to) {
	if (unlink(to) < 0) {
		if (errno != ENOENT) {
			perror("Unable to unlink moving file's destination");
			return(FALSE);
		}
	}
	return(mv(from, to));
}

/* rotate_archives ... rotates the archives.  Go figure.
 *  It's also a lousy hack.  On *so* many levels. */
int rotate_archives(void) {
	int i;
	char *from, *to;
	int len;

	/* Algorithm taken from Solaris's /usr/lib/newsyslog
	 *  Not that it's a great algorithm.  I'm just defending
	 *  its lousiness by precedent.
	 */
	from = strdup(WTMPX_ARC);
	if (from == NULL) {
		perror("Unable to allocate memory for old archive filename");
		return(FALSE);
	}
	to = strdup(WTMPX_ARC);
	if (to == NULL) {
		perror("Unable to allocate memory for old archive filename");
		return(FALSE);
	}

	len = strlen(WTMPX_ARC) - 1;

	for (i = MAX_ARCHIVES; i>0; i--) {
		from[len] = ITOC(i-1);
		to[len] = ITOC(i);
		if (mvf(from, to) < 0) {
			if (errno != ENOENT) {
				perror("Unable to rotate archives");
				return(FALSE);
			}
		}
	}

	return(TRUE);
}

int main (int argc, char **argv) {
	int wtmpx_cur, wtmpx_new, wtmpx_arc;
	struct utmpx wtmpx_rec;
	int wtmpx_rec_sz = sizeof(wtmpx_rec);
	time_t days, start_time;
	char *wtmpx_new_fn, *wtmpx_tmp_fn, *wtmpx_arc_fn;

	/* putrid argument checking.  but it works... */
	if (argc > 2) {
		usage(argc, argv, 1);
	}

	if (argc == 2) {
		days = (time_t) atoi(argv[1]);
	} else {
		days = OFFSET;
	}

	/* Open the current wtmpx for reading */
	wtmpx_cur = open(WTMPX, O_RDONLY);
	if (wtmpx_cur < 0) {
		perror("Unable to open wtmpx");
		exit(1);
	}

	/* generate a temporary filename for the new wtmpx and open it */
	wtmpx_new_fn = strdup(WTMPX_TMP);
	if (wtmpx_new_fn == NULL) {
		perror("Unable to allocate memory for temp filename");
		exit(1);
	}
	wtmpx_new = mkstemp(wtmpx_new_fn);
	if (wtmpx_new < 0) {
		perror("Unable to open replacement wtmpx");
		exit(1);
	}
	if (fchmod(wtmpx_new, WTMP_PERMS)) {  /* Fix permissions.  mkstemp() is lazy */
		perror("Unable to change permissions on temporary replacement wtmpx");
		/* exit(1)   /* Not a fatal error */
	}

	/* generate a temporary filename for the archive wtmpx and open it */
	wtmpx_arc_fn = strdup(WTMPX_TMP);
	if (wtmpx_arc_fn == NULL) {
		perror("Unable to allocate memory for temp filename");
		exit(1);
	}
	wtmpx_arc = mkstemp(wtmpx_arc_fn);
	if (wtmpx_arc < 0) {
		perror("Unable to open archive wtmpx");
		exit(1);
	}
	if (fchmod(wtmpx_arc, WTMP_PERMS)) {  /* Fix permissions.  mkstemp() is lazy */
		perror("Unable to change permissions on temporary archive wtmpx");
		/* exit(1)   /* Not a fatal error */
	}

	/* <STEAL SRC="http://www.netsys.com/sunmgr/1998-01/msg00153.html"
	 *        ALT="sun-managers mailing list"
	 *        SUBJECT="SUMMARY: wtmp and wtmpx purging"
	 *        FROM="MARK SAYER <MSAYER@cuscal.com.au>"
	 *        DATE="Tue, 27 Jan 1998 11:42:00 +1100">
	 */
	start_time = time(NULL) - (days * SECONDS_IN_DAY);

	while (read(wtmpx_cur, &wtmpx_rec, wtmpx_rec_sz) == wtmpx_rec_sz) {
		if (wtmpx_rec.ut_xtime >= start_time) {
			if (write(wtmpx_new, &wtmpx_rec, wtmpx_rec_sz) != wtmpx_rec_sz) {
				perror("Unable to write to new wtmpx");
				exit(1);
			}
		} else {
			if (write(wtmpx_arc, &wtmpx_rec, wtmpx_rec_sz) != wtmpx_rec_sz) {
				perror("Unable to write to archive wtmpx");
				exit(1);
			}
		}
	}
	/* </STEAL> */

	/* close all of the wtmpx files.  Now just move them around */
	close(wtmpx_cur);
	close(wtmpx_new);
	close(wtmpx_arc);

	/* Make a temporary filename for temporary storage of old wtmpx and open it */
	wtmpx_tmp_fn = strdup(WTMPX_TMP);
	if (wtmpx_tmp_fn == NULL) {
		perror("Unable to allocate memory for temp filename");
		exit(1);
	}
	mktemp(wtmpx_tmp_fn);
	if(wtmpx_tmp_fn == NULL) {
		perror("Unable to generate temporary filename");
		exit(1);
	}

	/* move old/current wtmpx to a temporary file */
	if (mv(WTMPX, wtmpx_tmp_fn) < 0) {
		perror("Unable to move old wtmpx file");
		exit(1);
	}

	/* move new wtmpx into place */
	if (mv(wtmpx_new_fn, WTMPX) < 0) {
		perror("Unable to move wtmpx file");
		mv(wtmpx_tmp_fn, WTMPX); /* Try to move old wtmpx back if it fails */
		exit(1);
	}

	/* we've moved the new one in place successfully.  no need to keep old one */
	if (unlink(wtmpx_tmp_fn) < 0) {
		perror("Unable to unlink temporary wtmpx");
		/* exit(1);   /* Not really a fatal error */
	}

	/* move the archive of older data to a standard place */
	if (mv(wtmpx_arc_fn, WTMPX_ARC) < 0) {
		if (errno == EEXIST) {   /* if it exists, we need to ... */
			rotate_archives();     /* rotate it back out of the way */
		} else {
			perror("Unable to move archive wtmp");
			exit(1);
		}
		if (mv(wtmpx_arc_fn, WTMPX_ARC) < 0) {
			perror("Unable to move archive wtmp");
			exit(1);
		}
	}

	exit(0);

}

/* $Author: wfaulk $ $Date: 2001/05/12 07:57:57 $
 * $RCSfile: wtmpxarc.c,v $ $Revision: 1.5 $
 */
