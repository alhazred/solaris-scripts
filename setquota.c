/*
** Programme non interactif pour mettre a jour le quota des utilisateurs
**
** Historique :
**   29/08/2005 - Creation - Jose-Marcio Martins da Cruz
**
** TODO :
**   - Set file count limits
**  
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/fs/ufs_quota.h>

#include <pwd.h>
#include <sys/types.h>

#include <unistd.h>
#include <errno.h>
#include <assert.h>
#include <sysexits.h>

void                usage(char *app);
uid_t               get_pwd(char *);

void                log_dqblk(struct dqblk *dqb, int verbose, char *user,
                              uid_t uid);

int                 open_quota_file(char *partition, int setlim);
int                 close_quota_file(int fd);
int                 set_quota(int fd, char *user, size_t slim, size_t hlim,
                              int setlim, int verbose);

/*
 *
 *
 *
 */
int
main(int argc, char **argv)
{
  uid_t               uid = 0;
  int                 fd = -1;
  char               *partition = NULL;
  char               *user = NULL;
  long                slim = 0, hlim = 0;
  int                 setlim = 0;
  char                fname[256] = "";
  int                 verbose = 0;
  char               *program = argv[0];
  int                 i;
	int                 result = EX_OK;

  /* decode command line options */
  {
    int                 c;

    while ((c = getopt(argc, argv, "p:f:s:h:wv")) != EOF)
    {
      switch (c)
      {
        case 'p':
          partition = optarg;
          break;
        case 's':
          if (optarg == NULL)
            exit(1);
          slim = strtol(optarg, NULL, 0);
          if (errno == ERANGE)
          {
            fprintf(stderr, "Soft limit value out of Range");
            result = EX_USAGE;
            goto end;
          }
          break;
        case 'h':
          if (optarg == NULL)
            exit(1);
          hlim = strtol(optarg, NULL, 0);
          if (errno == ERANGE)
          {
            fprintf(stderr, "Hard limit value out of Range");
            result = EX_USAGE;
            goto end;
          }
          break;
        case 'w':
          setlim = 1;
          break;
        case 'v':
          verbose++;
          break;
        default:
          usage(program);
          result = EX_USAGE;
          goto end;
          break;
      }
    }
  }

  if (slim > 0 || hlim > 0)
  {
    if (slim > 0 && hlim == 0)
      hlim = slim + 1000;
    if (hlim > 0 && slim == 0)
      slim = hlim - 1000;
    if (slim < 0)
      slim = 1;
    if (hlim < 0)
      hlim = 1;
  }

  if (partition == NULL)
  {
    fprintf(stderr, "--> ERROR : No partition specified\n\n");
    usage(program);
    result = EX_USAGE;
    goto end;
  }

  fd = open_quota_file(partition, setlim);
  if (fd < 0)
  {
    result = EX_OSERR;
    goto end;
  }

  if (argc - optind <= 0)
  {
    fprintf(stderr, "--> ERROR : No user specified\n\n");
    usage(program);
    result = EX_USAGE;
    goto end;
  }

  for (i = optind; i < argc; i++)
    (void) set_quota(fd, argv[i], slim, hlim, setlim, verbose);

  (void) close_quota_file(fd);

end:
  exit(result);
}

/*
**
**
**
*/
uid_t
get_pwd(char *user)
{
  struct passwd      *pwd;

  assert(user != NULL);

  if ((pwd = getpwnam(user)) != NULL)
    return pwd->pw_uid;

  return -1;
}

/*
**
*/
int
open_quota_file(char *partition, int setlim)
{
  char               *qfile = NULL;
  char               *fname = "quotas";
  int                 size;
  int                 fd;
  int                 mode;

  assert(partition != NULL);

  size = strlen(partition) + strlen(fname) + 2;
  if ((qfile = malloc(size)) == NULL)
  {
    fprintf(stderr, "malloc error : %s\n", strerror(errno));
    return -1;
  }

  mode = setlim != 0 ? O_RDWR : O_RDONLY;

  snprintf(qfile, size, "%s/%s", partition, fname);
  if ((fd = open(qfile, mode)) < 0)
  {
    fprintf(stderr, "Error opening %s file : %s\n", qfile, strerror(errno));
    exit(EX_IOERR);
  }

  return fd;
}

/*
**
*/
int
close_quota_file(int fd)
{

  return close(fd);
}

/*
**
**
*/
int
set_quota(int fd, char *user, size_t slim, size_t hlim, int setlim, int verbose)
{
  struct quotctl      qctl, *qp;
  struct dqblk        qdata;
  uid_t               uid;

  assert(user != NULL);
  assert(fd > 0);
  assert(slim >= 0);
  assert(hlim >= 0);

  memset(&qdata, 0, sizeof (qdata));
  memset(&qctl, 0, sizeof (qctl));

  if ((uid = get_pwd(user)) < 0)
  {
    fprintf(stderr, "User %s not found\n", user);
    return -1;
  }

  qp = &qctl;
  qp->op = Q_GETQUOTA;
  qp->uid = uid;
  qp->addr = (caddr_t) & qdata;

  if (ioctl(fd, Q_QUOTACTL, qp) < 0)
  {
    switch (errno)
    {
      case ESRCH:
        ;
        break;
      default:
        fprintf(stderr, "Error reading quotas for user %s (%d) : %s\n", user,
                uid, strerror(errno));
        return -1;
        break;
    }
  }

  if (verbose || setlim == 0)
    log_dqblk(&qdata, verbose, user, uid);

  if (setlim)
  {
    qp->op = Q_SETQLIM;
    qdata.dqb_bhardlimit = 2 * hlim;
    qdata.dqb_bsoftlimit = 2 * slim;

    fprintf(stdout, "Setting quotas for user %s (%d) %d/%d \n", user, uid, slim,
            hlim);
    if (ioctl(fd, Q_QUOTACTL, qp) < 0)
    {
      fprintf(stderr, "Error setting quotas for user %s (%d) : %s\n", user, uid,
              strerror(errno));
      return -1;
    }
  }

  return 0;
}

/*
 *
 *
 *
 */
#define Q_BHARDLIMIT   " absolute limit on disk blks alloc "
#define Q_BSOFTLIMIT   " preferred limit on disk blks "
#define Q_CURBLOCKS    " current block count "
#define Q_FHARDLIMIT   " maximum # allocated files + 1 "
#define Q_FSOFTLIMIT   " preferred file limit "
#define Q_CURFILES     " current # allocated files "
#define Q_BTIMELIMIT   " time limit for excessive disk use "
#define Q_FTIMELIMIT   " time limit for excessive files "

void
log_dqblk(struct dqblk *dqb, int verbose, char *user, uid_t uid)
{
	printf("Quota information for user %s uid=(%d)\n", user, uid);
	printf("  %-36s : %10d\n", Q_BHARDLIMIT, dqb->dqb_bhardlimit / 2);
	printf("  %-36s : %10d\n", Q_BSOFTLIMIT, dqb->dqb_bsoftlimit / 2);
	printf("  %-36s : %10d\n", Q_CURBLOCKS, dqb->dqb_curblocks / 2);
	printf("  %-36s : %10d\n", Q_FHARDLIMIT, dqb->dqb_fhardlimit);
	printf("  %-36s : %10d\n", Q_FSOFTLIMIT, dqb->dqb_fsoftlimit);
	printf("  %-36s : %10d\n", Q_CURFILES, dqb->dqb_curfiles);
	printf("  %-36s : %10d\n", Q_BTIMELIMIT, dqb->dqb_btimelimit);
	printf("  %-36s : %10d\n", Q_FTIMELIMIT, dqb->dqb_ftimelimit);
	printf("  Blocks information converted to 1024 bytes block size\n");
}

/*
 *
 *
 *
 */
void
usage(char *app)
{
  int                 i;
  char               *s;

  fprintf(stdout, "Usage :\n");
  fprintf(stdout,
          "  %s [-w] [-v] -p filesystem [-s softlim] [-h hardlim] user [user...]\n",
          app);

  s = " Options\n"
    "  -w : Set values (default is read values only)\n"
    "  -v : verbose\n"
    "  -p : filesystem\n"
    "  -u : user to set/read quota\n"
    "  -s : Soft limit (KBytes)\n" "  -h : Hard limit (KBytes)\n";
  fprintf(stdout, s);
}

/*
 *  This script is submitted to BigAdmin by a user of the BigAdmin community.
 *  Sun Microsystems, Inc. is not responsible for the
 *  contents or the code enclosed. 
 * 
 * 
 *  Copyright 2006 Sun Microsystems, Inc. ALL RIGHTS RESERVED
 *  Use of this software is authorized pursuant to the
 *  terms of the license found at
 *  http://www.sun.com/bigadmin/common/berkeley_license.html
 *
 */


