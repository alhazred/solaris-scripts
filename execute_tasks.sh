#!/usr/bin/ksh
#
# ----------------------------------------------------------------------
#H# execute_tasks.sh
#H#
#H# Function: execute one or more tasks defined in include files
#H#           This is only a wrapper script with a framework to execute tasks
#H#           You need at least one include file with task definitions for this script to do something useful
#H# 
#h# Usage:    execute_tasks.sh [-v|--verbose] [-q|--quiet] [-f|--force] [-o|--overwrite] [-y|--yes] [-n|--no] [-l|--logfile filename]
#h#               [-d{:dryrun_prefix}|--dryrun{:dryrun_prefix}] [-D|--debugshell] [-t fn|--tracefunc fn] [-L] 
#h#               [-T|--tee] [-V|--version] [--var name=value] [--appendlog] [--nologrotate] [--noSTDOUTlog] [--disable_tty_check] [--nobackups]
#h#               [--print_task_template [filename]] [--create_include_file_template [filename]] [--list [taskmask]] [--list_tasks [taskmask]]
#h#               [--list_task_groups [groupmask]] [--list_default_tasks] [--abort_on_error] [--abort_on_task_not_found] [--abort_on_duplicates]
#h#               [--checkonly] [--check] [--singlestep] [--unique] [--trace] [--info] [--print_includefile_help] [-i|--includefile [?]filename] 
#h#               [--no_init_tasks[ [--no_finish_tasks] [--only_list_tasks] [--disabled_tasks task1[...,task#]] 
#H#               [task1] [... task#] [-- parameter_for_init_tasks]
#h#
#H# Parameter:
#H#   task#
#H#      - \"task#\" can be a task to execute, a task group with multiple tasks to execute, the default task group \"all\" or \"ALL\", 
#H#        a pattern for tasks to execute, or an input file with a list of tasks to execute
#H#
#H#        Tasks
#H#        -----
#H#
#H#        Each task is simply a function in one of the include files. There must be a function for every task to execute 
#H#        in one of the include files. The function name must start with \"task_\" but NOT with \"task_dummy\" or \"task_template\".
#H#        To execute the function \"task_mytask01\" you can use the script parameter \"task_mytask01\" or \"mytask01\".
#H#        If the function for a task is defined in more then one include file only the function defined
#H#        in the last include file read will be used (use the parameter \"--abort_on_duplicates\" to abort the script if 
#H#        duplicate task definitions are found).
#H#
#H#        Parameter for a task are supported; the format for tasks with parameter is: 'task#:parameter1[:...[:parameter#]]'
#H#        Whitespaces (blanks or tabs) in the parameter for a task are not supported. 
#H#
#H#        The task names can be used with or without the leading \"task_\".
#H#        In case a task and a task group use the same name the script will use the task group. To use the task
#H#        instead use the task name with the leading \"task_\".
#H#
#H#
#H#        Patterns
#H#        --------
#H#
#H#        You can also use pattern with \"*\" and \"?\" -- e.g use \"check*\" to execute all tasks beginning with \"check\".
#H#
#H#
#H#        Task groups
#H#        -----------
#H#
#H#        Task groups are variables with a list of tasks to execute. These variables must be defined in the include files. 
#H#        To define a task group use the statement
#H#
#H#          TASK_GROUP_<groupname>=\"task1 [... [task#]]\"
#H#
#H#        in one of the include files.
#H#        The prefix \"TASK_GROUP_\" is mandatory for task groups; \"<groupname>\" can be any string that is allowed 
#H#        for variable names in the shell executing the script. To execute the tasks in a task group use the script 
#H#        parameter \"<groupname>\". E.g. to execute all tasks in the task group \"TASK_GROUP_include1\" use the
#H#        script parameter \"include1\".
#H#        
#H#        Parameter for a task group are not possible but the tasks in a task group can be defined with parameter.
#H#        To use parameter define the task like this
#H#
#H#          task#:parameter1[:...[:parameter#]]
#H#
#H#        Note: Whitespaces in the parameter for a task in a task group are not allowed.
#H#        Comments in task group definitions are allowed; comments must start with a hash \"#\" in the first column. 
#H#        So to add comments to a task group use a task group definition with line breaks, e.g.:
#H#        
#H#TASK_GROUP_mytaskgroup001=\"# comment 1
#H## comment 2
#H## ...
#H##I# This line will be used as task info line and printed by the script
#H##I# This line also ...
#H#        task1 task2 task3
#H#task4:parameter1 task5:parameter1:parameter2 task8
#H#[...] 
#H#  task9
#H#  \"
#H#        
#H#        Lines starting with the prefix \"#I#\" in a task group definition will be printed if one of the parameter 
#H#        \"--list\", \"--list_tasks\", or \"--list_task_groups\" together with the parameter \"-v\" is used.
#H#
#H#
#H#        Task group \"all\" 
#H#        ----------------
#H#
#H#        To execute all defined tasks in all used include files use the parameter \"all\"; the tasks will then be executed 
#H#        in alphabetical order. If the parameter \"all\" is found all other task parameter will be ignored.
#H#        Add the statement \"DISABLE_THE_PARAMETER_ALL=${__TRUE}\" to an include file to disable the parameter \"all\"
#H#        (this setting can NOT be reverted in other include files).
#H#
#H#        To change the list of tasks that should be executed for an include file if the parameter \"all\" is used create
#H#        a variable called \"DEFAULT_TASKS\" with the list of tasks to execute for \"all\" separated by white spaces in the include file .
#H#        If the variable \"DEFAULT_TASKS\" is defined in at least one include file it will be used for the parameter \"all\".
#H#        If the variable \"DEFAULT_TASKS\" is defined in more then one include file the contents of the variables will be concatenated.
#H#        
#H#        Use the statement \"DEFAULT_TASKS=all\" in an include file to add all tasks defined in an include file to the variable 
#H#        \"DEFAULT_TASKS\" if that variable is defined in another include file.
#H#        Add the statement \"DEFAULT_TASKS=none\" to an include file to suppress the warning about a missing definition for DEFAULT_TASKS 
#H#        for that include file.
#H#        The use of the variable \"DEFAULT_TASK\" is also neccessary to change the order for executing the tasks.
#H#        Be carefull if using include files with and without a defined variable \"DEFAULT_TASKS\"; execute the script with the parameter
#H#         \"--only_list_tasks\" to check which tasks would be executed.
#H#
#H#        To define tasks that should not be executed if the parameter \"all\" is used create a variable called \"NO_DEFAULT_TASKS\"
#H#        in the include file with the task names. If a task is defined in the variable DEFAULT_TASKS and NO_DEFAULT_TASKS it will not 
#H#        be executed if \"all\" is used. You may also use patterns with \"*\" and \"?\" (like \"check_*\" or \"*003\") in the list of tasks
#H#        to ignore for \"all\".
#H#        If the variable \"NO_DEFAULT_TASKS\" is defined in more then one include file the contents of the variables will be concatenated.
#H#
#H#
#H#        Task group \"ALL\" 
#H#        ----------------
#H#
#H#        Use the parameter \"ALL\" to override the DEFAULT_TASKS settings from the include files and ignore the setting for
#H#        DISABLE_THE_PARAMETER_ALL from all include files. If the parameter \"ALL\" is found all other task parameter will be ignored.
#H#        Use the parameter \"ALL\" only if really neccessary -- in principle you should never use this parameter.
#H#
#H#
#H#        Disable tasks
#H#        -------------
#H#
#H#        To disable one or more tasks add the tasks to the variable DISABLED_TASKS in one of the include files - the tasks in that 
#H#        variable will not be executed. DISABLED_TASKS can be set and changed in any function or task in the include files. This can 
#H#        be used to dynamically disable tasks.
#H#        To not override DISABLED_TASKS defined in other include files always add new tasks to the variable, e.g.:
#H#
#H#          DISABLED_TASKS=\"\${DISABLED_TASKS} [new_disabled_tasks]\"
#H#
#H#        To disable one or more tasks via the parameter use the parameter \"--disabled_tasks\".
#H#
#H#
#H#        Input files with tasks list
#H#        ---------------------------
#H#
#H#        To use an input file with the list of tasks to execute use a filename with at least one slash \"/\", 
#H#        e.g. \"./mytasklist\"
#H#        Each line in that file must contain either a comment starting with a hash \"#\" or one task or task group to execute; e.g.:
#H#
#H##
#H## sample task input file 
#H##
#H## with the list of the tasks to execute, e.g.
#H##
#H##   use one blank to separate the parameter from the tasks; multiple parameter are possible;
#H##   blanks or colons (:) in the parameter values are not possible)
#H##
#H#mytask0
#H#mytask1 parameter1 parameter2
#H##
#H## task groups can also be used, e.g.:
#H##   parameter for the tasks are not possible if using task groups
#H##
#H#mytask_group0
#H##
#H## patterns with \"*\" and \"?\" can also be used to define tasks to execute, e.g. :
#H##   parameter for the tasks are not possible if using patterns
#H##
#H#check*
#H#
#H#        Empty lines and lines beginning with a \"#\" in an input file are ignored.
#H#
#H#        Special tasks
#H#        -------------
#H#        
#H#        The function \"init_tasks\" will always be executed before the first task is executed if defined in 
#H#        one of the include files. If \"init_tasks\" ends with a return code not equal \"${__TRUE}\" the 
#H#        script execution will be aborted without executing any of the tasks (use the parameter \"--no_init_tasks\" to 
#H#        disable the execution of the function \"init_tasks\").
#H#
#H#        The function \"finish_tasks\" will always be executed after the last task is executed if defined 
#H#        in one of the include files (use the parameter \"--no_finish_tasks\" to disable the execution of the
#H#        function \"finish_tasks\"). The return code of the function finish_tasks will be ignored.
#H#
#H#        If either \"init_tasks\" or \"finish_tasks\" are defined in more then one include file only the definition
#H#        from the last include file read is used.
#H#
#H#
#H#   -- parameter_for_init_tasks
#H#        All parameter following the separator \"--\" are parameter for the function \"init_tasks\" defined in the include file(s).
#H#        Use the variable \"PARAMETER_FOR_INIT_TASKS\" in the function \"init_tasks\"to read the parameter.
#H#        These parameter will be ignored by this script ${REAL_SCRIPTNAME##*/}. 
#H#
#H#   --includefile
#H#      - name of an include file to use; the parameter can be used multiple times
#H#        The parameter is optional; without the parameter \"--includefile\" the script only reads the 
#H#        default include file
#H#        The default include file for the script 
#H#          \"${REAL_SCRIPTNAME##*/} \"
#H#        is 
#H#          \"${DEFAULT_INCLUDE_FILE_NAME}\"
#H#        this file is searched in the current directory and in the directory with this script 
#H#          \"${REAL_SCRIPTDIR}\"
#H#
#H#        Note: The name of the default include file depends on the script name (which can also be a symbolic link)
#H#
#H#        Use a leading question mark for the filenames of optional include files, e.g. \"-i ?my_optional_file\".
#H#        Optional include files are only used if they exist.
#H#        use \"--includefile none\" to delete the list of include files (including the default include file and 
#H#        optional include files)
#H#        The script will not read the default include file if the parameter \"--includefile\" is used 
#H#        for at least one mandatory include file.
#H#        The default include file will be read if the parameter \"--includefile\" is only used for 
#H#        optional include files.
#H#        To read additional include files before reading the default include file add the parameter 
#H#        \"--includefile default\" after all other include files.
#H#        The format \"--includefile:filename\" is also supported for this parameter
#H#
#H#   --print_includefile_help
#H#        only show the help text for all include files (these are all lines beginning with the prefix \"#H#\" in the 
#H#        1st column in all include files read)
#H#   --print_task_template
#H#      - print the template for a new task definition to the file \"filename\" and exit. If \"filename\" is missing 
#H#        the template is written to STDOUT
#H#   --list [pattern1[...[pattern#]]
#H#      - list all defined tasks and task groups and exit; use \"-v --list \" to print also the usage help for each task 
#H#        if defined and the task group info for each task group if defined
#H#        use one or more patterns with \"*\" and \"?\" (pattern) to only list tasks and task groups matching one of the pattern.
#H#        The script will add a leading \"*\" and a trailing \"*\" to every pattern without a \"*\" and a \"?\".
#H#        e.g. the pattern \"check\" will list all tasks and task groups matching the pattern \"*check*\"; 
#H#        the pattern \"check*\" will only match the tasks and task groups matching the patterns with \"check*\".
#H#   --list_tasks
#H#      - like the parameter \"--list\" but only list the tasks and do not list the task groups
#H#   --list_task_groups [pattern1[...[pattern#]]
#H#      - list all defined task groups and exit; 
#H#        pattern# are (optional) patterns with \"*\" and \"?\" to list only the task groups that match one of the pattern.
#H#        see the description for the parameter \"--list\" for details regarding the supported pattern.
#H#   --list_default_tasks
#H#      - list only the tasks that would be executed if the parameter \"all\" is used
#H#   --create_include_file_template 
#H#      - create an include file template and exit. If \"filename\" is missing the default include file will be created.
#H#   --abort_on_error
#H#      - abort the task execution if a task fails, default: continue the task execution after a task failed
#H#   --abort_on_task_not_found
#H#      - abort the task execution if a task is not defined, default: continue the task execution with the next task
#H#   --abort_on_duplicates
#H#       - do not start the task execution if one or more tasks are defined multiple times; default: use the
#H#         task definition found in the last include file read and ignore the other definitions
#H#         use \"++abort_on_duplicates\" to suppress the warnings for duplicate task definitions
#H#   --checkonly
#H#      - check if all requested tasks exist and exit
#H#   --check
#H#      - check if all requested tasks exist before executing the tasks; exit if one or more tasks are missing
#H#   --singlestep
#H#      - execute the steps in single step mode
#H#   --unique
#H#      - execute every task only once
#H#   --trace
#H#      - enable trace for all tasks to execute
#H#        to enable trace for only one task if multiple tasks are executed use the parameter \"-t task_<taskname>\"
#H#        Tracing will only work if the function for the task starts like this
#H#
#H#function task_taskname {
#H#  typeset __FUNCTION="task_taskname"
#H#  \${__DEBUG_CODE}
#H#  \${__FUNCTION_INIT}
#H#        
#H#   --info
#H#      - enable verbose mode for the tasks to execute
#H#   --no_init_tasks
#H#      - do not execute the function \"init_tasks\"
#H#   --no_finish_tasks
#H#      - do not execute the function \"finish_tasks\"
#H#   --only_list_tasks
#H#      - only list the tasks that would be executed; init_tasks and finish_tasks will also 
#H#        not be executed. This parameter will not process the list of disabled tasks.
#H#        To check which tasks would be executed considering the disabled tasks defined in the 
#H#        include files or the parameter for the script use the parameter \"-d\".
#H#        
#H#   --disabled_tasks
#H#        Add one or more tasks to the list of disabled tasks; use blanks or commas to separate tasks; 
#H#        pattern for the disabled tasks are supported. This parameter can be used more then once
#H#        Use \"--disabled_tasks none\" to delete the list of disabled tasks defined with this parameter
#H#        also supported is the format \"--disabled_tasks:task[...]\"
#H#
#H#   -h - print the script usage; use -h and -v one or more times to print more help text        
#H#   -v - verbose mode; use -v -v to also print the runtime system messages 
#H#        (or set the environment variables VERBOSE to 0 and VERBOSE_LEVEL to the level)
#H#   -q - quiet mode (or set the environment variable QUIET to 0)
#H#   -f - force execution (or set the environment variable FORCE to 0 )
#H#   -o - eanble overwrite mode (or set the environment variable OVERWRITE to 0 )
#H#   -y - answer \"yes\" to all questions
#H#   -n - answer \"no\" to all questions
#H#   -l - logfile to use; use "-l none" to not use a logfile at all
#H#        the default logfile is /var/tmp/${SCRIPTNAME}.log
#H#        also supported is the format \"-l:filename\"
#H#   -d - dryrun mode, default dryrun_prefix is: \"${DEFAULT_DRYRUN_PREFIX} \"
#H#        Use the parameter \"-d:<dryrun_prefix>\" or the syntax
#H#        \"PREFIX=<new dryrun_prefix> ${REAL_SCRIPTNAME}\" 
#H#        to change the dryrun prefix
#H#        The script will run in dryrun mode if the environment variable PREFIX
#H#        is set. To disable that behaviour use the parameter \"+d\"
#H#        Note: Is dryrun mode disabled? ${__TRUE_FALSE[${DRYRUN_MODE_DISABLED}]}
#H#   -D - start a debug shell and continue the script afterwards
#H#   -t - trace the function fn
#H#        also supported is the format \"-t:fn[,...,fn#]\"
#H#   -L - list all defined functions and end the script
#H#   -T - copy STDOUT and STDERR to the file /var/tmp/${SCRIPTNAME}.$$.tee.log 
#H#        using tee; set the environment variable __TEE_OUTPUT_FILE before 
#H#        calling the script to change the file used for the output of tee
#H#   -V - print the script version and exit; use \"-v -V\" to print the 
#H#        template version also
#H#   --var 
#H#      - set the variable \"name\" to the value \"value\"
#H#        also supported is the format \"--var:<varname>=<value>\"
#H#   --appendlog
#H#      - append the messages to the logfile (default: overwrite an existing logfile)
#H#        This parameter also sets --nologrotate
#H#   --nologrotate
#H#      - do not create a backup of an existing logfile
#H#   --noSTDOUTlog
#H#      - do not write STDOUT/STDERR to a file if /dev/tty is not a a device
#H#   --nobackups
#H#      - do not create backups
#H#   --disable_tty_check
#H#      - disable the check if we do have a tty
#H#   --nocleanup
#H#      - do no house keeping at script end
#H#
#U# Parameter that toggle a switch from true to false or vice versa can
#U# be used with the plus sign (+) instead of minus (-) to invert the usage, e.g.
#U# 
#U# The parameter \"-v\" enables the verbose mode; the parameter \"+v\" disables the verbose mode.
#U# The parameter \"--quiet\" enables the quiet mode; the parameter \"++quiet\" disables the quiet mode.
#U#
#U# All parameter are processed in the given order, e.g.
#U#
#U#  execute_tasks.sh -v +v
#U#    -> verbose mode is now off
#U#
#U#  execute_tasks.sh +v -v
#U#    -> verbose mode is now on
#U#
#U# Parameter are evaluated after the evaluation of environment variables, e.g
#U#
#U# VERBOSE=0  execute_tasks.sh
#U#     -> verbose mode is now on
#U#
#U# VERBOSE=0  execute_tasks.sh +v
#U#     -> verbose mode is now off
#U#
#U# 
#U# To disable one or more of the house keeping tasks you might set some variables
#U# either before starting the script or via the parameter \"--var name=value\"
#U# 
#U# The defined variables are
#U# 
#U#  NO_EXIT_ROUTINES=0       # do not execute the exit routines if set to 0
#U#  NO_TEMPFILES_DELETE=0    # do not delete temporary files if set to 0
#U#  NO_TEMPDIR_DELETE=0      # do not delete temporary directories if set to 0
#U#  NO_FINISH_ROUTINES=0     # do not execute the finish routines if set to 0
#U#  NO_UMOUNT_MOUNTPOINTS=0  # do not umount temporary mount points if set to 0
#U#  NO_KILL_PROCS=0          # do not kill the processes if set to 0
#U#  
### Predefined Return codes:
###
###   2     Invalid parameter found
### 200     Script aborted for unknown reason; EXIST signal received
### 201	    Script aborted for unknown reason, QUIT signal received
### 202     This script must be executed by root only
### 203     internal error
### 250     ${SCRIPTNAME} aborted by CTRL-C
### 253     Can not create backups of the log files
### 254     ${SCRIPTNAME} aborted by the user
###
### ---------------------------------

### Note: The format of the entries for the history list should be
### 
###       #V#   <date> v<version> <comment>
#V#
#V# History:  
#V#   11.01.2019 v1.0.0 /bs
#V#     initial release
#V#
#V#   17.05.2019 v1.1.0 /bs
#V#     the script failed executing all tasks if the global variable "i" was used in one of the tasks -- fixed
#V#     added support for a list of tasks that should not be executed if the parameter \"all\" is used (variable NO_DEFAULT_TASKS)
#V#     the script now lists also all defined task groups if the parameter --list is used
#V#
#V#   29.05.2019 v1.1.1 /bs
#V#     the script did not support task parameter beginning with a slash "/" -- fixed
#V#
#V#   10.07.2019 v1.1.2 /bs
#V#     the script now also prints the number of tasks if the paramete "--list" is used
#V#
#V#   16.07.2019 v1.1.3 /bs
#V#     added the parameter \"--list_default_tasks\"
#V#
#V#   16.08.2019 v1.1.4 /bs
#V#     NO_DEFAULT_TASK now also supports the full task name, e.g. task_this_is_my_task001 and this_is_my_task001 are okay now
#V#    the parameter "--list -v " now supports variables in the usage help string
#V#
#V#   12.08.2019 v1.1.5 /bs
#V#     improved the output for task groups when using the parameter  --list 
#V#
#V#   24.08.2109 v1.2.0 /bs
#V#     added the variable DISABLED_TASKS
#V#
#V#   30.09.2019 v1.3.0 /bs
#V#     added optional include files
#V#     added the parameter --info
#V#
#V#   25.10.2019 v1.3.1 /bs
#V#     the script now only prints a small usage help if the parameter -h is used
#V#     (use --help to get the long usage help like before)
#V#
#V#   01.11.2019 v1.3.2 /bs
#V#     the messages about tasks that are not part of the default tasks is now only an info message and not a warning
#V#
#V#   10.11.2019 v1.3.3 /bs
#V#     removed the prefix "task_" from the task names in the output
#V#
#V#   07.01.2020 v1.4.0 /bs
#V#     added the parameter --no_init_tasks and --no_finish_tasks
#V#     corrected some minor typos in the code and comments
#V#
#V#   14.01.2020 v1.5.0 /bs
#V#     added support for parameter for the function init_tasks ( [-- parameter_for_init_tasks] )
#V#     the parameter "--create_include_file_template" did not work due to a typo -- fixed
#V#     input files with the list of tasks to execute did only work for filenames with absolute path -- fixed
#V#     the parameter handling for tasks defined in input files with list of tasks to execute was buggy -- fixed
#V#
#V#   15.01.2020 v1.5.1 /bs
#V#     their was an error in the code to process exclude masks for tasks using joker (* or ?) -- fixed
#V#     the parameter "print_task_template" now supports a file for the task template
#V#     the function BackupFile was buggy -- fixed
#V#
#V#   06.02.2020 v1.5.2 /bs
#V#     added the parameter "--print_includefile_help"
#V#
#V#   13.02.2020 v1.5.3 /bs
#V#      added the variables STARTTIME_IN_SECONDS amd STARTTIME_IN_HUMAN_READABLE_FORMAT
#V#      added the variables ENDTIME_IN_SECONDS and ENDTIME_IN_HUMAN_READABLE_FORMAT
#V#      added the variables RUNTIME_IN_SECONDS and RUNTIME_IN_HUMAN_READABLE_FORMAT
#V#      the script now prints the start time, the runtime in seconds and in human readable format, and the return code at script end
#V#
#V#   26.06.2020 v1.5.4 /bs
#V#     the variable FILES_TO_REMOVE was overwritten in the function DebugShell -- fixed
#V#
#V#   04.07.2020 v1.6.0 /bs
#V#     added the variables STDIN_IS_TTY, STDOUT_IS_TTY, STDERR_IS_TTY
#V#     added the variables STDIN_DEVICE, STDOUT_DEVICE, STDERR_DEVICE
#V#     added the variable RUNNING_IN_A_CONSOLE_SESSION
#V#     added the variable STDOUT_IS_A_PIPE
#V#     added the variable STDIN_IS_A_PIPE
#V#     added the variable PARENT_PROCECSS_EXECUTABLE
#V#     switch_to_background did not work in Solaris -- fixed
#V#     switch_to_background now ends with an error if running in an unknown OS
#V#     added the parameter --disable_tty_check
#V#     added the parameter nobackups
#V#     added the parameter -o / --overwrite
#V#     DEBUG_SHELL_CALLED was not set to ${__TRUE} in DebugShell -- fixed
#V#
#V#   04.07.2020 v1.6.0 /bs
#V#     the new code from 1.6.0 did not work correct if /tmp was mounted with the option noexec -- fixed
#V#
#V#   06.07.2020 v1.6.1 /bs
#V#     the script now prints the tasks names without the leading task_ if the parameter --list_default_tasks is used
#V#     code to get STDIN_DEVICE and STDOUT_DEVICE rewritten
#V#
#V#   11.07.2020 v1.6.2 /bs
#V#     added the parameter --list_tasks
#V#     added the parameter --list_task_groups
#V#
#V#   07.08.2020 v1.6.3 /bs
#V#     added the function read_file_section
#V#
#V#   17.10.2020 v2.0.0 /bs
#V#     added support for comments in task groups
#V#     added support for task group infos 
#V#     slightly enhanced the pattern usage of the parameter --list, --list_tasks, and list_task_groups
#V#     added the parameter --only_list_tasks
#V#     added the parameter --abort_on_duplicates
#V#     added the parameter --disabled_tasks
#V#     added a lot of new debug messages (printed if the parameter "-v" is used)
#V#     added more details to the usage help printed with the parameter --help
#V#     the handling of the variable DEFAULT_TASKS changed if more then one
#V#       include file is used (see the script usage)
#V#
#T# ---------------------------------------------------------------------
#T#
#T# History of the script template
#T#
#T#   28.04.2016 v1.0.0 /bs
#T#     initial release
#T#
#T#   ...
#T#
#T#   08.11.2017 v2.0.0 /bs
#T#     initial public release
#T#
#T#   24.11.2017 v2.1.0 /bs
#T#     added the parameter -T (use tee to save the script output)
#T#     added the function KillProcess
#T#     the script now supports a timeout for each pid to kill at script end
#T#       (see the comments for the function KillProcess)
#T#     the cleanup function now supports parameter for the exit routines
#T#     the cleanup function now supports parameter for the finish routines
#T#     added the variable INSIDE_CLEANUP_ROUTINE
#T#     added the variable INSIDE_FINISH_ROUTINE
#T#     the parameter -t and the DebugShell aliase for tracing now support
#T#       the variable ${.sh.func} if running in ksh93
#T#     the parameter -t and the DebugShell aliase for tracing now add the statements 
#T#       typeset __FUNCTION=<function_name> ; ${__DEBUG_CODE};
#T#     to a function if neccessary and "typeset -f" is supported by the shell used
#T#     added the variable ${ENABLE_DEBUG}; if ${ENABLE_DEBUG} is not ${__TRUE} the DebugShell
#T#       and the parameter -D are disabled
#T#     added the variable ${USAGE_HELP}
#T#     added the function show_extended_usage_help
#T#     added the parameter -L / --listfunctions
#T#     Read_APPL_PARAMS_entries rewritten using an array for the RCM entries
#T#
#T#   07.12.2017 v2.1.1 /bs
#T#     the aliase use now only one line
#T#     LogRotate now aborts the script if it can not create backups of the
#T#       existing log file
#T#
#T#   10.12.2017 v2.2.0 /bs
#T#     added the parameter --var, the parameter --var is disabled if the variable
#T#       ${ENABLE_DEBUG} is not ${__TRUE}
#T#
#T#   19.01.2018 v2.2.1 /bs
#T#     the script now uses /var/tmp/${SCRIPTNAME}.$$.STDOUT_STDERR if it can not
#T#     write to the file /var/tmp/${SCRIPTNAME}.STDOUT_STDERR
#T#
#T#   29.01.2018 v2.2.2 /bs
#T#     the script now uses /var/tmp/${SCRIPTNAME}.log.$$ if it can not
#T#     write to the file /var/tmp/${SCRIPTNAME}.log
#T#     the script now uses /var/tmp/${SCRIPTNAME}.STDOUT_STDERR.$$ if it can not
#T#     write to the file /var/tmp/${SCRIPTNAME}.STDOUT_STDERR
#T#
#T#   09.02.2018 v2.2.3 /bs
#T#     added the parameter --appendlog
#T#     added the parameter --noSTDOUTlog
#T#
#T#   10.02.2018 v2.2.4 /bs
#T#     added the parameter --nologrotate
#T#
#T#   14.02.2018 v2.2.5 /bs
#T#     the script now converts the logfile name to a fully qualified name
#T#     in the previous version the script created additional empty logfiles - fixed
#T#
#T#   01.04.2018 v3.0.0 /bs
#T#     the parameter --var can now be used in this format also: --var:<var>=<value>
#T#     the parameter --tracefunc can now be used in this format also: --tracefunc:fn[..,fn]
#T#     the parameter --logfile can now be used in this format also: --logfile:<logfile>
#T#     the script now prints also the template version if the parameter -v and -V are used
#T#     the script now prints also the template history if the parameter "-h -v -v" are used
#T#     the version of the script and the version of the template are now dynamically 
#T#       retrieved from the source code of the script while executing the script
#T#     the parameter "-d" overwrote the value of the environment variable PREFIX -- fixed
#T#     added more details to the usage help for the parameter \"-h\"
#T#     added the DebugShell function editfunc
#T#     added the DebugShell function savefunc
#T#     added the DebugShell function restorefunc
#T#     added the DebugShell function clearsavedfunc
#T#     added the DebugShell function savedfuncs
#T#     added the DebugShell function viewsavedfunc
#T#     the function DebugShell now prints the return code of every executed command
#T#     the function DebugShell did not handle "." commands with errors correct - fixed
#T#     set_debug now preserves existing debug definitions if the parameter starts with a "+"
#T#     the output of the DebugShell alias vi#T#   25.07.2018 v3.0.1 /bsew_debug is now more human readable
#T#     the parameter --appendlog now also sets --nologrotate
#T#
#T#   25.07.2018 v3.1.0 /bs
#T#     added the parameter --nocleanup
#T#     added the variables
#T#       NO_EXIT_ROUTINES     # do not execute the exit routines if set to 0
#T#       NO_TEMPFILES_DELETE  # do not delete temporary files if set to 0
#T#       NO_TEMPDIR_DELETE    # do not delete temporary directories if set to 0
#T#       NO_FINISH_ROUTINES   # do not execute the finish routines if set to 0
#T#       NO_KILL_PROCS        # do not kill the processes if set to 0
#T#     renamed the variable KSH_VERSION to __KSH_VERSION because KSH_VERSION is a 
#T#       readonly variable in mksh
#T#
#T#   16.08.2018 v3.2.0 /bs
#T#     the default parameter processing now stops if the parameter "--" is found
#T#     added code to umount temporary mount points at script end
#T#     added the variable
#T#       NO_UMOUNT_MOUNTPOINTS # do not umount temporary mount points at script end
#T#     the cleanup function for the house keeping now does nothing in dry-run mode 
#T#     added the function switch_to_background to switch the process with the 
#T#       script into the background; 
#T#       this functionwas tested in Linux (RHEL), Solaris 10, AIX, and MacOS
#T#
#T#   03.11.2018 v3.2.1 /bs
#T#     corrected a minor bug in the cleanup function
#T#     switch_to_background disabled in the DebugShell
#T#     added the variable DEBUG_SHELL_CALLED
#T#     script called the finish functions twice -- fixed
#T#     the script now also evaluates ${..} in help text marked with #U# 
#T#         (-> printed with -h -v)
#T#     corrected some spelling errors
#T#
#T#   16.11.2018 v3.2.2 /bs
#T#     added the variable SYSTEMD_IS_USED 
#T#     added the alias __getparameter to process parameter with values
#T#
#T#   08.02.2019 v3.2.3 /bs
#T#     added support for ksh88 (ksh88 does not know "typeset -A" for arrays)
#T#
#T#   12.04.2019 v3.2.3 /bs
#T#     the script did not get the ksh version used correct in all cases
#T#
#T#
# ----------------------------------------------------------------------
#
#

# read the template version from the source file
#
TEMPLATE_VERSION="$(  grep "^#T#" $0 | grep " v[0-9]" | tail -1 | awk '{ print $3};' )"
: ${TEMPLATE_VERSION:=can not find the template version -- please check the source code of $0}

# read the script version from the source file
#
SCRIPT_VERSION="$( grep "^#V#" $0 | grep " v[0-9]" | tail -1 | awk '{ print $3};' )"
: ${SCRIPT_VERSION:=can not find the script version -- please check the source code of $0}

# list of supported include file versions
#
SUPPORTED_INCLUDE_FILE_VERSIONS="1.0.0.0"


# hardcoded script / template versions (not used anymore)
#

# TEMPLATE_VERSION="3.0.0"

# SCRIPT_VERSION="1.0.0"


# USAGE_HELP contains additional text that is written by the script if 
# executed with the parameter -h
#
USAGE_HELP=""

# enviroment variables used by the script
#
ENV_VARIABLES="
PREFIX
__DEBUG_CODE
__TEE_OUTPUT_FILE
USE_ONLY_KSH88_FEATURES
BREAK_ALLOWED
EDITOR
PAGER
LOGFILE
NOHUP_STDOUT_STDERR_FILE

FORCE
QUIET
VERBOSE
VERBOSE_LEVEL
OVERWRITE

RCM_SERVICE
RCM_FUNCTION
RCM_USERID
RCM_PASSWORD
"


# define constants
#
__TRUE=0
__FALSE=1

__TRUE_FALSE[0]="true"
__TRUE_FALSE[1]="false"

# dryrun mode disabled?
# To enable dryrun mode set DRYRUN_MODE_DISABLED to ${__FALSE}
#
# dryrun mode only works if you prefix all commands that change something whith ${PREFIX}!
#
# DRYRUN_MODE_DISABLED=${__TRUE}
DRYRUN_MODE_DISABLED=${__FALSE}

# dryrun prefix (parameter -d)   
#
DEFAULT_DRYRUN_PREFIX="echo "

# : ${PREFIX:=${DEFAULT_DRYRUN_PREFIX} }
: ${PREFIX:=}



# DebugShell will do nothing, and the parameter -D and --var are not usable 
# if ENABLE_DEBUG is ${__FALSE} 
#
ENABLE_DEBUG=${__TRUE}
#ENABLE_DEBUG=${__FALSE}

# variable for debugging
#
# use "eval ... >&2" for your debug code and use STDERR for all output!
#
# e.g. 
#
#   __DEBUG_CODE="eval echo \*\*\*  Starting the function \$0, parameter are: \'\$*\'>&2" ./scriptt_mini.sh
#
if [ ${ENABLE_DEBUG} = ${__TRUE} ] ; then
: ${__DEBUG_CODE:=}
else
  __DEBUG_CODE=""
fi

# list of functions with enabled debug code
#
__FUNCTIONS_WITH_DEBUG_CODE=""

# list of saved functions
#
__LIST_OF_SAVED_FUNCTIONS=""

# set this variable to ${__TRUE} to change the default to "tty check is disabled"
#

DISABLE_TTY_CHECK=${DISABLE_TTY_CHECK:=${__FALSE}}

RUNNING_IN_TERMINAL_SESSION=${__TRUE}

# check tty
#
if [ ${DISABLE_TTY_CHECK} = ${__FALSE} ] ; then
  tty -s && RUNNING_IN_TERMINAL_SESSION=${__TRUE} || RUNNING_IN_TERMINAL_SESSION=${__FALSE}
fi

# disable the tty check if the parameter --disable_tty_check is used
#
if [[  \ $*\  == *\ --disable_tty_check\ * ]] ; then
  RUNNING_IN_TERMINAL_SESSION=${__TRUE}
fi

# file for STDOUT and STDERR if the parameter -t/--tee is used
#
: ${__TEE_OUTPUT_FILE:=/var/tmp/${0##*/}.$$.tee.log}

# -----------------------------------------------------------------------------
# use the parameter -T or --tee to automatically call the script and pipe
# all output into a file using tee

if [ "${__PPID}"x = ""x ] ; then
  __PPID=$PPID ; export __PPID  
  if [[ \ $*\  == *\ -T* || \ $*\  == *\ --tee\ * ]] ; then
    echo "Saving STDOUT and STDERR to \"${__TEE_OUTPUT_FILE}\" ..."
    exec  $0 $@ 2>&1 | tee -a "${__TEE_OUTPUT_FILE}"
    __MAINRC=$?
    echo "STDOUT and STDERR saved in \"${__TEE_OUTPUT_FILE}\"."
    exit ${__MAINRC}
  fi
fi

: ${__PPID:=$PPID} ; export __PPID


# -----------------------------------------------------------------------------
# check for the parameter -q / --quiet
#
  if [[ \ $*\  == *\ -q* || \ $*\  == *\ --quiet\ * ]] ; then
    QUIET=${__TRUE}
  fi
  
# -----------------------------------------------------------------------------
#### __KSH_VERSION - ksh version (either 88 or 93)
####   If the script is not executed by ksh the shell is compatible to
###    ksh version ${__KSH_VERSION}
####
__KSH_VERSION=88 ; f() { typeset __KSH_VERSION=93 ; } ; f ;

# check if "typeset -f" is supported
#
typeset -f f | grep __KSH_VERSION >/dev/null && TYPESET_F_SUPPORTED="yes" || TYPESET_F_SUPPORTED="no"

unset -f f

# check if $0 in a function defined with "function f { ... }" is the function name
#
function f {
  echo $0
}

[ "$( f )"x = "f"x ] && TRACE_FEATURE_SUPPORTED="yes" || TRACE_FEATURE_SUPPORTED="no"

unset -f f

# use ksh93 features?
#
if [ "${__KSH_VERSION}"x = "93"x ] ; then
  USE_ONLY_KSH88_FEATURES=${USE_ONLY_KSH88_FEATURES:=${__FALSE}}
else
  USE_ONLY_KSH88_FEATURES=${USE_ONLY_KSH88_FEATURES:=${__TRUE}}
fi

# alias to install the trap handler
#
# Note: USR1 and USR2 are different values in the various Unix OS!
#

# supported signals
#

# general signals
#
#  Number	KSH name	Comments
#  0	    EXIT	    This number does not correspond to a real signal, but the corresponding trap is executed before script termination.
#  1	    HUP	        hangup
#  2	    INT	        The interrupt signal typically is generated using the DEL or the ^C key
#  3	    QUIT	    The quit signal is typically generated using the ^[ key. It is used like the INT signal but explicitly requests a core dump.
#  9	    KILL	    cannot be caught or ignored
#  10	    BUS	        bus error
#  11	    SEGV	    segmentation violation
#  13	    PIPE	    generated if there is a pipeline without reader to terminate the writing process(es)
#  15	    TERM	    generated to terminate the process gracefully
#  16	    USR1	    user defined signal 1, this value is different in other Unix OS!
#  17	    USR2	    user defined signal 2, this value is different in other Unix OS!
#  -	    DEBUG	    KSH only: This is no signal, but the corresponding trap code is executed before each statement of the script.
#
# signals in Solaris
#  24       SIGTSTP		stop a running process (like CTRL-Z)
#  25       SIGCONT		continue a stopped process in the background
#
# signals in Linux
#  20       SIGTSTP		stop a running process (like CTRL-Z)
#  18       SIGCONT		continue a stopped process in the background
#
# signals in AIX
#  18       SIGTSTP		stop a running process (like CTRL-Z)
#  19       SIGCONT		continue a stopped process in the background
#
# signals in MacOS (Darwin)
#  18       SIGTSTP		stop a running process (like CTRL-Z)
#  19       SIGCONT		continue a stopped process in the background
#
# 
#
# Note: The usage of the variable LINENO is different in the various ksh versions
#
alias __settraps="
  trap 'signal_hup_handler    \${LINENO}' 1 ;\
  trap 'signal_break_handler  \${LINENO}' 2 ;\
  trap 'signal_quit_handler   \${LINENO}' 3 ;\
  trap 'signal_exit_handler   \${LINENO}' 15 ;\
  trap 'signal_usr1_handler   \${LINENO}' USR1 ;\
  trap 'signal_usr2_handler   \${LINENO}' USR2  ;\
"


# alias to reset all traps to the defaults
#
alias __unsettraps="
  trap - 1 ;\
  trap - 2 ;\
  trap - 3 ;\
  trap - 15 ;\
  trap - USR1 ;\
  trap - USR2 ;\
"

__FUNCTION_INIT="eval __settraps"

# variables used for the logfile handling
#
# the log functions save all messages in the variable LOG_MESSAGE_CACHE until the logfile to use is konwn
#
LOGFILE_FOUND=${__FALSE}
LOG_MESSAGE_CACHE=""

# variables for the trap handler
#
# The INSIDE_* variables are set to ${__TRUE} while the handler is active and 
# then back to ${__FALSE} after the handler is done
#
INSIDE_DIE=${__FALSE}
INSIDE_DEBUG_SHELL=${__FALSE}
INSIDE_CLEANUP_ROUTINE=${__FALSE}
INSIDE_FINISH_ROUTINE=${__FALSE}
#
INSIDE_USR1_HANDLER=${__FALSE}
INSIDE_USR2_HANDLER=${__FALSE}
INSIDE_BREAK_HANDLER=${__FALSE}
INSIDE_HUP_HANDLER=${__FALSE}
INSIDE_EXIT_HANDLER=${__FALSE}
INSIDE_QUIT_HANDLER=${__FALSE}

# the variable DEBUG_SHELL_CALLED Is set to TRUE everytime the function DebugShell is executed
#
DEBUG_SHELL_CALLED=${__FALSE}


# set BREAK_ALLOWED to ${__FALSE} to disable CTRL-C, to ${__TRUE} to abort the script with CTRL-C
# and to "DebugShell" to call the DebugShell if the CTRL-C signal is catched
#
BREAK_ALLOWED="${BREAK_ALLOWED:=DebugShell}"
# BREAK_ALLOWED=${__FALSE}
# BREAK_ALLOWED=${__TRUE}

# current hostname
#
CUR_HOST="$( hostname )"
CUR_SHORT_HOST="${CUR_HOST%%.*}"

CUR_OS="$( uname -s )"

# script name and directory
#
typeset -r SCRIPTNAME="${0##*/}"
typeset SCRIPTDIR="${0%/*}"
if [ "${SCRIPTNAME}"x = "${SCRIPTDIR}"x ] ; then
  SCRIPTDIR="$( whence ${SCRIPTNAME} )"
  SCRIPTDIR="${SCRIPTDIR%/*}"
fi  
REAL_SCRIPTDIR="$( cd -P ${SCRIPTDIR} ; pwd )"
REAL_SCRIPTNAME="${REAL_SCRIPTDIR}/${SCRIPTNAME}"


WORKING_DIR="$( pwd )"
LOGDIR="/var/tmp"
LOGFILE="${LOGFILE:=${LOGDIR}/${SCRIPTNAME}.log}"


CUR_SHELL="$( head -1 "${REAL_SCRIPTNAME}" | cut -f1 -d " " | cut -c3- )"

# use either vi or nano as editor if no default editor is set
#
: ${EDITOR:=$( which vi 2>/dev/null )}
: ${EDITOR:=$( which nano 2>/dev/null )}

# use less or more as pager if no default pager is set
#
: ${PAGER:=$( which less 2>/dev/null )}
: ${PAGER:=$( which more 2>/dev/null )}

SYSTEMD_IS_USED=${__FALSE}
READLINK=""

#
# if either STDIN, STDOUT, or STDERR goes to a real tty
# device this variable will be true
#
# So this is not really a bullet proof solution!
#
RUNNING_IN_A_CONSOLE_SESSION="unknown"

STDOUT_IS_A_PIPE="unknown"
STDIN_IS_A_PIPE="unknown"

[ -t 0 ] &&  STDIN_IS_TTY=${__TRUE} ||  STDIN_IS_TTY=${__FALSE}
[ -t 1 ] && STDOUT_IS_TTY=${__TRUE} || STDOUT_IS_TTY=${__FALSE}
[ -t 2 ] && STDERR_IS_TTY=${__TRUE} || STDERR_IS_TTY=${__FALSE}
 
STDIN_DEVICE="unknown"
STDOUT_DEVICE="unknown"
STDERR_DEVICE="unknown"

PARENT_PROCECSS_EXECUTABLE=""

case "${CUR_OS}" in

  CYGWIN* )
    set +o noclobber
    __SHELL_FIELD=9
    AWK="awk"
    ;;

  Linux )
    __SHELL_FIELD=8
    ID="id"
    AWK="awk"
    TAR="tar"
    READLINK="$( which readlink 2>/dev/null )"
    ps -p 1 | grep systemd >/dev/null && SYSTEMD_IS_USED=${__TRUE} || SYSTEMD_IS_USED=${__FALSE}

    [ -p /proc/$$/fd/1 ] && STDOUT_IS_A_PIPE=${__TRUE} || STDOUT_IS_A_PIPE=${__FALSE}
    [ -p /proc/$$/fd/0 ]  && STDIN_IS_A_PIPE=${__TRUE}  || STDIN_IS_A_PIPE=${__FALSE}

    TMPFILE1="/var/tmp/${SCRIPTNAME}.1.$$"
    TMPFILE2="/var/tmp/${SCRIPTNAME}.2.$$"

#
# a workaround is neccessary to get the device/file used for STDOUT and STDIN in some circumstances
#        
    echo "( ls -l /proc/$$/fd/0 2>/dev/null || echo unknown  ; ls -l /proc/$$/fd/1 2>/dev/null || echo unknown ) >${TMPFILE1}"  >"${TMPFILE2}"
    if [ $? -eq 0 ] ; then
      chmod 755 "${TMPFILE2}"
      ksh -c "${TMPFILE2}" 2>/dev/null
      if [ $? -eq 0 -a -r "${TMPFILE1}" ] ; then
        STDIN_DEVICE="$(  head -1 "${TMPFILE1}" 2>/dev/null | awk '{ print $NF }' )"
        STDOUT_DEVICE="$( tail -1 "${TMPFILE1}" 2>/dev/null | awk '{ print $NF }' )"
      fi      
      \rm -f "${TMPFILE1}" "${TMPFILE2}"  2>/dev/null
    fi
    
#    STDIN_DEVICE="$( ls -l /proc/$$/fd/0 | awk '{ print $NF }' )"

    [[ ${STDIN_DEVICE} == /dev/tty* ]] &&  RUNNING_IN_A_CONSOLE_SESSION=${__TRUE} ||  RUNNING_IN_A_CONSOLE_SESSION=${__FALSE}

    [[ ${STDIN_DEVICE} == /dev/pts/* || ${STDIN_DEVICE} == /dev/tty* ]] &&  STDIN_IS_TTY=${__TRUE} ||  STDIN_IS_TTY=${__FALSE}
  
    [[ ${STDOUT_DEVICE} == /dev/pts/* || ${STDOUT_DEVICE} == /dev/tty* ]] && STDOUT_IS_TTY=${__TRUE} || STDOUT_IS_TTY=${__FALSE}
    [[ ${STDOUT_DEVICE} == /dev/tty* ]] &&  RUNNING_IN_A_CONSOLE_SESSION=${__TRUE} 

    STDERR_DEVICE="$( ls -l /proc/$$/fd/2 | awk '{ print $NF }' )"
    [[ ${STDERR_DEVICE} == /dev/pts/* || ${STDERR_DEVICE} == /dev/tty* ]] && STDERR_IS_TTY=${__TRUE} || STDERR_IS_TTY=${__FALSE}
    [[ ${STDERR_DEVICE} == /dev/tty* ]] &&  RUNNING_IN_A_CONSOLE_SESSION=${__TRUE} 

    PARENT_PROCECSS_EXECUTABLE="$( readlink -f /proc/$(ps -o ppid:1= -p $$)/exe )"    
    ;;
      
  SunOS )
    __SHELL_FIELD=9
    AWK="nawk"
    ID="/usr/xpg4/bin/id"
    TAR="/usr/sfw/bin/gtar"    
    READLINK="$( whence readlink )" || \
      [ -x /opt/csw/gnu/readlink ] && READLINK="/opt/csw/gnu/readlink"

    RUNNING_IN_A_CONSOLE_SESSION=${__FALSE} 

    [ -p /proc/$$/fd/1 ] && STDOUT_IS_A_PIPE=${__TRUE} || STDOUT_IS_A_PIPE=${__FALSE}
    [ -p /proc/$$/fd/0 ]  && STDIN_IS_A_PIPE=${__TRUE}  || STDIN_IS_A_PIPE=${__FALSE}

    CUR_MAJOR_DEV="$( ls -ld /proc/$$/fd/0 | awk '{ print $5 }' )"    
    [ "${CUR_MAJOR_DEV}"x = "0,"x ] && RUNNING_IN_A_CONSOLE_SESSION=${__TRUE} 

    CUR_MAJOR_DEV="$( ls -ld /proc/$$/fd/1 | awk '{ print $5 }' )"    
    [ "${CUR_MAJOR_DEV}"x = "0,"x ] && RUNNING_IN_A_CONSOLE_SESSION=${__TRUE} 
 
    CUR_MAJOR_DEV="$( ls -ld /proc/$$/fd/2 | awk '{ print $5 }' )"    
    [ "${CUR_MAJOR_DEV}"x = "0,"x ] && RUNNING_IN_A_CONSOLE_SESSION=${__TRUE} 

    ;;

  AIX )
    __SHELL_FIELD=9
    AWK="awk"
    ID="id"
    TAR="tar"    
    ;;
    
  * )
    AWK="awk"
    ID="id"
    TAR="tar"    
    ;;

esac

#### __SHELL - name of the current shell executing this script
####
__SHELL="$( ps -f -p $$ | grep -v PID | tr -s " " | cut -f${__SHELL_FIELD} -d " " )"
__SHELL=${__SHELL##*/}

: ${__SHELL:=ksh}

CUR_USER_ID="$( ${ID} -u )"
CUR_USER_NAME="$( ${ID} -un )"

CUR_GROUP_ID="$( ${ID} -g )"
CUR_GROUP_NAME="$( ${ID} -gn )"


# parameter -f
#
: ${FORCE:=${__FALSE}}

# parameter -q
#
: ${QUIET:=${__FALSE}}

# parameter -v
#
: ${VERBOSE:=${__FALSE}}

# VERBOSE_LEVEL is increased by one for every -v found in the parameter
#
: ${VERBOSE_LEVEL:=0}

# parameter -o
#
: ${OVERWRITE:=${__FALSE}}

# parameter -L
#
LIST_FUNCTIONS_AND_EXIT=${__FALSE}

# parameter --nologrotate
#
ROTATE_LOG=${__TRUE}

# for Logrotating once each month for scripts running each day use
#
# [ $( date "+%d" ) = 1 ] && ROTATE_LOG=${__TRUE} || ROTATE_LOG=${__FALSE}

# for Logrotating once a week (1 = monday) for scripts running each day use
#
# [ $( date "+%u" ) = 1 ] && ROTATE_LOG=${__TRUE} || ROTATE_LOG=${__FALSE}

# parameter --nocleanup
#
NO_CLEANUP=${__FALSE}

# parameter --nobackups
#
NO_BACKUPS=${__FALSE}

# parameter --appendlog
#
APPEND_LOG=${__FALSE}

# parameter --noSTDOUTlog
#
LOG_STDOUT=${__TRUE}

# parameter -y and -n (used in the function AskUser)
#
# answer all questions with Yes (if "y") or No (if "n") else ask the user
#
__USER_RESPONSE_IS=""

# user input in the function AskUser
#
USER_INPUT=""
LAST_USER_INPUT=""

# do not print the user input in the function AskUser
#
__NOECHO=${__FALSE}

# use /dev/tty instead of STDIN and STDOUT in the function AskUser
#
__USE_TTY=${__FALSE}

# stty settings (used in die to reset the stty settings if neccessary)
#
__STTY_SETTINGS=""

# allow a debug shell in the function AskUser
#
__DEBUG_SHELL_IN_ASKUSER=${__TRUE}

# variables for the house keeping
#
# directories to remove at script end
#
DIRS_TO_REMOVE=""

# files to remove at script end
#
FILES_TO_REMOVE=""

# processes to kill at script end
#
PROCS_TO_KILL=""

# timeout in seconds to wait after "kill" before issueing a "kill -9" for a 
# still running process, use -1 for the KILL_PROC_TIMEOUT to disable "kill -9"
#
KILL_PROC_TIMEOUT=0

# cleanup functions to execute at script end
# Use "function_name:parameter1[[...]:parameter#] to add parameter for a function
# blanks or tabs in the parameter are NOT allowed
#
CLEANUP_FUNCTIONS=""

# mount points to umount at script end
#
MOUNTS_TO_UMOUNT=""

# finish functions to execute at script end
# Use "function_name:parameter1[[...]:parameter#] to add parameter for a function
# blanks or tabs in the parameter are NOT allowed
#
FINISH_FUNCTIONS=""

# ----------------------------------------------------------------------
# variable for print_runtime_variables
#
# format:
#
#  #msg  - message to print (replacing "_" with " "; 
#          do NOT use blanks in the lines starting with #)
#  else	 - variablename, print the name and value
#
RUNTIME_VARIABLES="

#constants
__TRUE
__FALSE

#signal_handling:
BREAK_ALLOWED
INSIDE_DIE
INSIDE_DEBUG_SHELL
INSIDE_CLEANUP_ROUTINE
INSIDE_FINISH_ROUTINE
INSIDE_USR1_HANDLER
INSIDE_USR2_HANDLER
INSIDE_BREAK_HANDLER
INSIDE_HUP_HANDLER
INSIDE_EXIT_HANDLER
INSIDE_QUIT_HANDLER
DEBUG_SHELL_CALLED

#Parameter:
ALL_PARAMETER
NOT_USED_PARAMETER
FORCE
QUIET
VERBOSE
VERBOSE_LEVEL
USAGE_HELP
LIST_FUNCTIONS_AND_EXIT
APPEND_LOG
LOG_STDOUT
NO_BACKUPS
__USER_RESPONSE_IS

#Hostname_variables:
CUR_HOST
CUR_SHORT_HOST
CUR_OS

#Scriptname_and_directory:
SCRIPTNAME
SCRIPTDIR
REAL_SCRIPTDIR
REAL_SCRIPTNAME

#Current_environment:
CUR_SHELL
EDITOR
PAGER
WORKING_DIR
LOGFILE
LOGFILE_FOUND
LOG_MESSAGE_CACHE
ROTATE_LOG
RUNNING_IN_TERMINAL_SESSION
DISABLE_TTY_CHECK
__KSH_VERSION
USE_ONLY_KSH88_FEATURES
TYPESET_F_SUPPORTED
TRACE_FEATURE_SUPPORTED
AWK
ID
__PPID
NOHUP_STDOUT_STDERR_FILE
__SHELL

#Variables_for_the_function_AskUser:
USER_INPUT
LAST_USER_INPUT
__NOECHO
__USE_TTY
__STTY_SETTINGS
__DEBUG_SHELL_IN_ASKUSER

#User_and_group:
CUR_USER_ID
CUR_USER_NAME
CUR_GROUP_ID
CUR_GROUP_NAME

#RCM_variables:
RCM_SERVICE
RCM_FUNCTION
RCM_HOSTID
RCM_HOSTID_FILE
RCM_DBQUERY
RCM_DBGET_FILE
RCM_USERID
RCM_PASSWORD

#Housekeeping:
CLEANUP_FUNCTIONS
FILES_TO_REMOVE
DIRS_TO_REMOVE
PROCS_TO_KILL
KILL_PROC_TIMEOUT
FINISH_FUNCTIONS
MOUNTS_TO_UMOUNT
NO_CLEANUP
NO_EXIT_ROUTINES
NO_TEMPFILES_DELETE
NO_TEMPDIR_DELETE
NO_FINISH_ROUTINES
NO_KILL_PROCS
NO_UMOUNT_MOUNTPOINTS

#Debugging
__DEBUG_CODE
__FUNCTION_INIT
DEFAULT_DRYRUN_PREFIX
PREFIX
ENABLE_DEBUG
__TEE_OUTPUT_FILE
__LIST_OF_SAVED_FUNCTIONS

"


# ----------------------------------------------------------------------

### start of comments and variables for RCM environments
###
### ignore the comments and variables in this section if not using RCM
#
# Variables set by make_appls.pl from the RCM methods:
# 
# export RCM_SERVICE=Oracle
# export RCM_FUNCTION=clt_sw.11.2.0.4
# epxort RCM_IVERSION=11.2.0.4
# export RCM_ISERVER=dbkpinst1.rze.de.db.com
# export RCM_IPATH=/usr/sys/inst.images/Linux/Oracle/rdbms11g
#

# values for the function Read_APPL_PARAMS_entries and Retrieve_file_from_Jamaica
#
RCM_SERVICE="${RCM_SERVICE:=veritas}"
RCM_FUNCTION="${RCM_FUNCTION:=vcsscripts}"

RCM_HOSTID_FILE="/var/db/var/hostid"
RCM_HOSTID="$( cat "${RCM_HOSTID_FILE}" 2>/dev/null )"

RCM_DBQUERY="/usr/db/RCM/Utility/dbquery"
RCM_DBGET_FILE="/usr/db/RCM/Utility/dbgetfile"

RCM_USERID="${RCM_USERID:=}"
RCM_PASSWORD="${RCM_PASSWORD:=}"

FOUND_APPL_PARAM_ENTRY_KEYS=""
typeset RCM_APPL_PARAMS_KEY
typeset RCM_APPL_PARAMS_VAL
RCM_APPL_PARAMS_KEY[0]=0

###  end of comments and variables for RCM environments

# ----------------------------------------------------------------------
# add variables for print_runtime_variables
#
# format:
#
#  #msg  - message to print (replacing "_" with " ")
#  else	 - variablename, print the name and value
#
APPLICATION_VARIABLES="
"

# ----------------------------------------------------------------------

[ -r /sys/class/dmi/id/product_name ] && SYSTEM_PRODUCT_NAME="$( < /sys/class/dmi/id/product_name )" || SYSTEM_PRODUCT_NAME=""
[ -r /sys/class/dmi/id/sys_vendor ] && SYSTEM_PRODUCT_VENDOR="$( < /sys/class/dmi/id/sys_vendor )" || SYSTEM_PRODUCT_VENDOR=""

if [[ ${SYSTEM_PRODUCT_NAME} == VMware* || ${SYSTEM_PRODUCT_VENDOR} == VMware* ]] ; then

    HPYERVISOR_VENDOR="VMware"
    RUNNING_ON_A_VIRTUAL_MACHINE=${__TRUE}
    THIS_IS_A_VMWARE_MACHINE=${__TRUE}

elif [[ ${SYSTEM_PRODUCT_NAME} == VirtualBox* || ${SYSTEM_PRODUCT_VENDOR} == innotek* ]] ; then

    HPYERVISOR_VENDOR="VirtualBox"
    RUNNING_ON_A_VIRTUAL_MACHINE=${__TRUE}
    THIS_IS_A_VMWARE_MACHINE=${__FALSE}

elif [[ ${SYSTEM_PRODUCT_VENDOR} == QEMU* ]] ; then

    HPYERVISOR_VENDOR="qemu"
    RUNNING_ON_A_VIRTUAL_MACHINE=${__TRUE}
    THIS_IS_A_VMWARE_MACHINE=${__FALSE}

else
    HPYERVISOR_VENDOR=""
    RUNNING_ON_A_VIRTUAL_MACHINE=${__FALSE}
    THIS_IS_A_VMWARE_MACHINE=${__FALSE}
fi

# ----------------------------------------------------------------------
# internal functions
#

# ----------------------------------------------------------------------
# RotateLog
#
# create up to 10 backups of one or more files
#
# usage: RotateLog [file1 [... [file#]]]
#
# returns: ${__TRUE} - a new backup was created
#
function RotateLog {
  typeset __FUNCTION="RotateLog"
  ${__DEBUG_CODE} 
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  typeset THIS_LOGFILES="${LOGFILE}"
  typeset THIS_LOGFILE=""
  typeset i
  
  [ $# -ne 0 ] && THIS_LOGFILES="$*"
  if [ "${THIS_LOGFILES}"x != ""x ] ; then
    for THIS_LOGFILE in "${THIS_LOGFILES}" ; do
      for i in 8 7 6 5 4 3 2 1 0  ; do
        if [ -r "${THIS_LOGFILE}.${i}" ] ; then
          mv -f "${THIS_LOGFILE}.${i}" "${THIS_LOGFILE}.$(( i + 1 ))" || THISRC=${__FALSE}
        fi
      done
      if [ -r "${THIS_LOGFILE}" ] ; then
        mv -f "${THIS_LOGFILE}" "${THIS_LOGFILE}.0"  || THISRC=${__FALSE}
      fi
    done
  fi

  return ${THISRC}
}

# ----------------------------------------------------------------------
# general functions
#


# ----------------------------------------------------------------------
# LogMsg
#
# write a message to STDOUT and to the log file if the variable QUIET is not ${__TRUE}
#
# usage: LogMsg [msg1] [...] [msg#]
#
# returns: ${__TRUE} - the message was written
#
# note: LogMsg calls the function RotateLog if neccessary
#
function LogMsg {
  typeset __FUNCTION="LogMsg"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  
  [[ ${QUIET} = ${__TRUE} ]] && return

  typeset THISMSG=""
  typeset TEMPVAR="${LOGFILE}"

  if [ ${LOGFILE_FOUND}x = ${__TRUE}x -a "${LOGFILE}"x != ""x ] ; then 
    if [ ${ROTATE_LOG}x = ${__TRUE}x  ] ; then
      ROTATE_LOG=${__FALSE}
      RotateLog 
      if [ $? -ne 0 ] ; then
        LOGFILE=""
        LogError "Existing logfile(s) are:"
        LogMsg "-" "$( ls -l "${TEMPVAR}"* )"
        die 253 "Can not create backups of the log files"
      fi
    fi
    if [ ${APPEND_LOG}x = ${__FALSE}x ] ; then
      echo >"${LOGFILE}"
      APPEND_LOG=${__TRUE}
    fi
  fi
 
  if [ "$1"x = "-"x ] ; then
    shift
    THISMSG="$*"
  else
    THISMSG="[$( date +"%d.%m.%Y %H:%M" ) ${THISSCRIPT}] $*"
  fi
  
  echo "${THISMSG}"  

# make sure all messages go to the correct log file if the parameter -l is used
#
  if [ "${LOGFILE}"x != ""x ] ; then
    if [ ${LOGFILE_FOUND}x = ${__TRUE}x ] ; then
      if [ "${LOG_MESSAGE_CACHE}"x != ""x ] ; then
        echo "${LOG_MESSAGE_CACHE}" >>"${LOGFILE}"
        LOG_MESSAGE_CACHE=""
      fi  
      [ "${LOGFILE}"x != ""x ] && echo "${THISMSG}" >>"${LOGFILE}"
    else
      LOG_MESSAGE_CACHE="${LOG_MESSAGE_CACHE}
${THISMSG}"
    fi
  fi
}

# ----------------------------------------------------------------------
# LogOnly
#
# write a message only to the log file if the variable QUIET is not ${__TRUE}
#
# usage: LogOnly [msg1] [...] [msg#]
#
# returns: ${__TRUE} - the message was written
#
# note: the message is written using the function LogMsg
#
function LogOnly {
  typeset __FUNCTION="LogOnly"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
	
  LogMsg "$*" >/dev/null  
}

# ----------------------------------------------------------------------
# LogInfo
#
# write an INFO: message to STDERR and the logfile if the variable VERBOSE is ${__TRUE}
# and if the variable QUIET is not ${__TRUE}
#
# usage: LogInfo [msg1] [...] [msg#]
#
# returns: ${__TRUE} - the message was written
#
# note: the message is written using the function LogMsg
#
function LogInfo {
  typeset __FUNCTION="LogInfo"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
	
  [ ${VERBOSE} = ${__TRUE} ] && LogMsg "INFO: $*" >&2
}


# ----------------------------------------------------------------------
# LogMoreInfo
#
# write an INFO: message to STDERR and the logfile if the variable VERBOSE is ${__TRUE}
# and if the variable QUIET is not ${__TRUE}
#
# usage: LogMoreInfo {loglevel} [msg1] [...] [msg#]
#
# returns: ${__TRUE} - the message was written
#
# default for "loglevel" is "1" (-> print the message if the parameter -v is used at least two times)
#
# note: the message is written using the function LogMsg
#
function LogMoreInfo {
  typeset __FUNCTION="LogMoreInfo"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset CUR_LEVEL=""
  
  if [[ $1 == [0-9]* ]] ; then
    CUR_LEVEL="$1"
    shift
  else
    CUR_LEVEL="1"
  fi
    
  [ ${VERBOSE_LEVEL} -gt ${CUR_LEVEL} ] && LogMsg "INFO: $*" >&2
}


# ----------------------------------------------------------------------
# LogRuntimeInfo
#
# internal sub routine for info messages from the runtime system
#
# returns: ${__TRUE} - message printed
#          ${__FALSE} - message not printed
#
function LogRuntimeInfo {
  typeset __FUNCTION="LogRuntimeInfo"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__FALSE}

  if [ ${VERBOSE_LEVEL} -gt 1 ] ; then
    LogInfo "$*"
    THISRC=$?
  fi

  return ${THISRC}
}

# ----------------------------------------------------------------------
# LogError
#
# write an ERROR: message to STDERR and the logfile if the variable QUIET is not ${__TRUE}
#
# usage: LogError [msg1] [...] [msg#]
#
# returns: ${__TRUE} - the message was written
#
# note: the message is written using the function LogMsg
#
function LogError {
  typeset __FUNCTION="LogError"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  if [ "$1"x = "-"x ] ; then	
    shift
    LogMsg "-" "ERROR: $*" >&2
    THISRC=$?
  else
    LogMsg "ERROR: $*" >&2
    THISRC=$?
  fi

  return ${THISRC}
}

# ----------------------------------------------------------------------
# LogWarning
#
# write an WARNING: message to STDOUT and the logfile if the variable QUIET is not ${__TRUE}
#
# usage: LogWarning [msg1] [...] [msg#]
#
# returns: ${__TRUE} - the message was written
#
# note: the message is written using the function LogMsg
#
function LogWarning  {
  typeset __FUNCTION="LogWarning"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  if [ "$1"x = "-"x ] ; then	
    shift
    LogMsg "-" "WARNING: $*" >&2
    THISRC=$?
  else
    LogMsg "WARNING: $*" >&2
    THISRC=$?
  fi
  
  return ${THISRC}
}

# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# __activate_logfile
#
# activate the logfile 
# set the semaphor for LogMsg to flush all messages to the logfile
#
# usage: __activate_logfile
#
# returns: ${__TRUE} - logfile activated
#          ${__FALSE} - error creating the log file
#
function __activate_logfile  {
  typeset __FUNCTION="__activate_logfile"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  typeset OLOGFILE=""
  
  if [ "${LOGFILE}"x != ""x  ] ; then
    LogMsg "### The logfile used is ${LOGFILE}"

    if [ ${LOGFILE_PARAMETER_FOUND} = ${__TRUE} ] ; then
      LOGDIR="$( cd $( dirname "${LOGFILE}" ) ; pwd )"
      LOGFILE="${LOGDIR}/$( basename "${LOGFILE}" )"
    fi

    LOGFILE_FOUND=${__TRUE}
  
    OLOGFILE="${LOGFILE}"
    touch "${LOGFILE}" 2>/dev/null >/dev/null 
    if [ $? -ne 0 ] ; then
      OLOGFILE="${LOGFILE}"
      LOGFILE="${LOGFILE}.$$"
      LogError "Can not write to the file ${OLOGFILE} - now using the log file ${LOGFILE}"
      THISRC=${__FALSE}
    else
      [ ! -s "${LOGFILE}" ] && rm "${LOGFILE}"
    fi
  fi
  return ${THISRC}
}

# ----------------------------------------------------------------------
# curtimestamp
#
# write the current date and time to STDOUT in a format that can be 
# used for filenames
#
# usage: curtimestamp
#
# returns: nothing
#
function curtimestamp {
  typeset __FUNCTION="curtimestamp"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
	
  date +%Y.%m.%d.%H_%M_%S_%s 
}
  
# ----------------------------------------------------------------------
# executeCommandAndLog
#
# execute a command and write STDERR and STDOUT also to the logfile
#
# usage: executeCommandAndLog command parameter
#
# returns: the RC of the executed command (even if a logfile is used!)
#
function executeCommandAndLog {
  typeset __FUNCTION="executeCommandAndLog"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
	
  set +e
  typeset THISRC=0

  LogInfo "### Executing \"$@\" " || LogOnly "### Executing \"$@\" "

  if [ "${LOGFILE}"x != ""x -a -f "${LOGFILE}" ] ; then
    # The following trick is from
    # http://www.unix.com/unix-dummies-questions-answers/13018-exit-status-command-pipe-line.html#post47559
    exec 5>&1
    tee -a "${LOGFILE}" >&5 |&
    exec >&p
    eval "$*" 2>&1
    THISRC=$?
    exec >&- >&5
    wait

    LogInfo "### The RC is ${THISRC}" || LogOnly  "### The RC is ${THISRC}"

  else
    eval "$@"
    THISRC=$?
  fi

  return ${THISRC}
}


#### --------------------------------------
#### KillProcess
####
#### Kill one or more processes
####
#### usage: KillProcess pid [...pid]
####
#### returns: ${__TRUE} -- all processes killed
####          ${__FALSE} -- at least one process not killed
#### 
#### notes:
####  The format for pid is "pid[:timeout_in_seconds]"
####
####  timeout_in_seconds is the time to wait after kill before a "kill -9"
####  is issued if the process is still running; use "pid:-1" to disable
####  the "kill -9" for a process
####  Default timeout for all PIDs is KILL_PROC_TIMEOUT
####
function KillProcess {
  typeset __FUNCTION="KillProcess"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  
  typeset THISRC=${__TRUE}
  
  typeset CUR_PID=""
  typeset CUR_KILL_PROC_TIMEOUT=""
  typeset PROCS_TO_KILL="$*"
  
  for CUR_PID in ${PROCS_TO_KILL} ; do

    if [[ ${CUR_PID} == *:* ]] ; then
      CUR_KILL_PROC_TIMEOUT="${CUR_PID#*:}"
      CUR_PID="${CUR_PID%:*}"
    else
      CUR_KILL_PROC_TIMEOUT="${KILL_PROC_TIMEOUT}"
    fi
  
    LogRuntimeInfo "Killing the process ${CUR_PID} (Timeout is ${CUR_KILL_PROC_TIMEOUT} seconds) ..."
    ps -p ${CUR_PID} >/dev/null
    if [ $? -eq 0 ] ; then
      LogRuntimeInfo "$( ps -fp ${CUR_PID} ) "
      kill ${CUR_PID}
      if [  ${CUR_KILL_PROC_TIMEOUT} != -1 ] ; then
        if [  ${CUR_KILL_PROC_TIMEOUT} != 0 ] ; then
          LogRuntimeInfo "Waiting up to ${CUR_KILL_PROC_TIMEOUT} second(s) ..."
          i=0
          while [ $i -lt ${CUR_KILL_PROC_TIMEOUT} ] ; do
            sleep 1
            ps -p ${CUR_PID} 2>/dev/null >/dev/null || break
            (( i = i + 1 ))
          done
        fi
        
        ps -p ${CUR_PID} 2>/dev/null >/dev/null
        if [ $? -eq 0 ] ; then
          LogRuntimeInfo "Process ${CUR_PID} is still alive after kill - now using kill -9 ..."
          kill -9 ${CUR_PID}
          ps -p ${CUR_PID} 2>/dev/null >/dev/null
          if [ $? -eq 0 ] ; then
            LogError "The process ${CUR_PID} is still alive after kill -9"
            THISRC=${__FALSE}
          else
            LogRuntimeInfo "Process ${CUR_PID} killed with kill -9"                  
          fi
        else
          LogRuntimeInfo "Process ${CUR_PID} killed"
        fi
      else
#
# kill -9 is disabled for this PID
#
        ps -p ${CUR_PID} 2>/dev/null >/dev/null
        if [ $? -eq 0 ] ; then
          LogRuntimeInfo "Process \"${CUR_PID}\" is still alive after kill (kill -9 is disabled)."
          THISRC=${__FALSE}       
        else
          LogRuntimeInfo "Process \"${CUR_PID}\" killed"
        fi
      fi
    else
      LogRuntimeInfo "Process ${CUR_PID} is not runninng"
    fi
  done

  ${__FUNCTION_EXIT}
  return ${THISRC}
}



# ---------------------------------------
# BackupFile
#
# create a backup of a file if it exists
#
# usage: BackupFile sourcefile backupfile [backupfile_extension]
#
# returns:  ${__TRUE} - backup created or original file does not exist
#           ${__FALSE} - error creating the backup
#
# Note: No backup will be created if the varaible ${NO_BACKUPS} is ${__TRUE}
#
function BackupFile {
  typeset THISRC=${__TRUE}

  typeset CUR_TIME="$( date +%Y.%m.%d-%H:%M:%S.%s )"
  typeset BACKUP_EXT=""
  typeset CUR_OUTPUT=""
  
  if [ ${NO_BACKUPS} -eq ${__TRUE} ] ; then
    LogInfo "Backups are disabled via parameter \"--no-backup\" -- will not create a backup of the file \"$1\" "
  else
    if [ $# -eq 3 ] ; then
      BACKUP_EXT="$3"
      shift
    else
      BACKUP_EXT="$$.${CUR_TIME}"
    fi
    
    if [ $# -eq 2 ] ; then
      if [ -f "$1" ] ; then
        LogMsg "Creating a backup of the file \"$1\" in \"$2.${BACKUP_EXT}\" ..."
        CUR_OUTPUT="$( cp -p "$1" "$2.${BACKUP_EXT}" 2>&1 )" || THISRC=${__FALSE}
        LogMsg "-" "${CUR_OUTPUT}"
      fi
    fi
  fi
  return ${THISRC}
}

# ----------------------------------------------------------------------
# __evaluate_fn
#
# Evaluate the parameter fn of the various DebugShell aliase
#
# Usage: executed by DebugShell - do not call this function in your code!
#
# returns: write the evaluated string to STDOUT
#
function __evaluate_fn {
  typeset CUR_FN=""
  typeset THIS_FN=""
  typeset NEW_FN=""
  typeset REAL_FN=""
 
#  "printf" "The parameter are: \"$*\" \n"
  
  typeset DEFINED_FUNCTIONS=" $("typeset" +f ) "
  set -f
  
  for CUR_FN in $* ; do
    case ${CUR_FN} in 
      *\** | *\?* )
       for THIS_FN in ${DEFINED_FUNCTIONS} ; do
         [[ " ${THIS_FN} " == *\ ${CUR_FN}\ * ]] && NEW_FN="${NEW_FN} ${THIS_FN} "
       done
       ;;
      
      all )
        NEW_FN="${NEW_FN} ${DEFINED_FUNCTIONS} "
        ;;
        
      * )
        NEW_FN="${NEW_FN} ${CUR_FN} "
        ;;
    esac
  done

  for CUR_FN in  ${NEW_FN} ; do
    [[ ${REAL_FN} == *\ ${CUR_FN}\ * ]] && continue
    REAL_FN="${REAL_FN} ${CUR_FN}"
  done
  
  echo "${REAL_FN}"
}
  
# ----------------------------------------------------------------------
# __DebugShell
#
# Open a simple debug shell
#
# Usage: executed by DebugShell - do not call this function in your code!
#
# returns: ${__TRUE}
#
# Input is always read from /dev/tty; output always goes to /dev/tty
# so DebugShell is only allowed if STDIN is a tty.
#
function __DebugShell {
  typeset __FUNCTION="__DebugShell"

  [ ${ENABLE_DEBUG}x != ${__TRUE}x ] && return 0
  
  [ ${INSIDE_DEBUG_SHELL}x = ${__TRUE}x ] && return 0
  INSIDE_DEBUG_SHELL=${__TRUE}

  if [ ${RUNNING_IN_TERMINAL_SESSION} != ${__TRUE} ] ; then
    LogError "DebugShell can only be used in interactive sessions"
    INSIDE_DEBUG_SHELL=${__FALSE}
    return ${__FALSE}
  fi

  DEBUG_SHELL_CALLED=${__TRUE}

  __settraps
  
  "typeset" THISRC=${__TRUE}
  "typeset" CMD_PARAMETER=""
  "typeset" FUNCTION_LIST=""
  "typeset" CUR_STATEMENT=""
  "typeset" CUR_VALUE=""
  "typeset" ADD_CODE=""

  "typeset" FUNC_SAVE_VAR=""
  "typeset" FUNC_SAVE_CONTENT=""
  
  "typeset" USER_INPUT=""
  "typeset" USER_INPUT1=""
  "typeset" CUR_CMD=""
  "typeset" CUR_FUNCTION_CODE=""
  "typeset" HASHCODE1=""
  "typeset" HASHCODE2=""
  
  "typeset" __TMP__STTY_SETTINGS="$( stty -g )"
            
  "typeset" TMP_FILE1="/tmp/${SCRIPTNAME}.DebugShell.$$.1.tmp"
  "typeset" TMP_FILE2="/tmp/${SCRIPTNAME}.DebugShell.$$.2.tmp"
  FILES_TO_REMOVE="${FILES_TO_REMOVE} ${TMP_FILE1} ${TMP_FILE2}"
 
  [ -r "${TMP_FILE1}" ] && rm "${TMP_FILE1}"
  [ -r "${TMP_FILE2}" ] && rm "${TMP_FILE2}"
#  ${USER_INPUT%% *}
  
  stty echo
  while "true" ; do
    "printf" "\n ------------------------------------------------------------------------------- \n"
    "printf" "${SCRIPTNAME} - debug shell - enter a command to execute (\"exit\" to leave the shell)\n"
    "printf" "Current environment: ksh version: ${__KSH_VERSION} | change function code supported: ${TYPESET_F_SUPPORTED} | tracing feature using \$0 supported: ${TRACE_FEATURE_SUPPORTED}\n"
    "printf" ">> "
    set -f
    "read" USER_INPUT
    set +f

    CMD_PARAMETER="${USER_INPUT#* }"
    [ "${CMD_PARAMETER}"x = "${USER_INPUT}"x ] && CMD_PARAMETER=""
    CUR_CMD="${USER_INPUT%% *}"

    case "${USER_INPUT}" in
    
      "help" )
         "printf" "
vars                      - print the runtime variable values

functions / funcs         - list all defined functions 
functions fn / funcs fn   - list functions matching the pattern fn

func fn                   - view the source code for the function fn (supported by this shell: ${TYPESET_F_SUPPORTED})
savedfuncs                - list the saved functions (supported by this shell: ${TYPESET_F_SUPPORTED})
editfunc fn               - edit the source code for the function fn (supported by this shell: ${TYPESET_F_SUPPORTED})
savefunc fn               - save the source code of the function fn (supported by this shell: ${TYPESET_F_SUPPORTED})
viewsavedfunc fn          - view the source code of the saved function fn (supported by this shell: ${TYPESET_F_SUPPORTED})
restorefunc fn            - restore the source code of the function fn (supported by this shell: ${TYPESET_F_SUPPORTED})
clearsavedfunc fn         - delete the saved source code of the function fn (supported by this shell: ${TYPESET_F_SUPPORTED})

verbose                   - toggle the verbose switch (Current value: ${VERBOSE})

view_debug                - view the current trace settings 
clear_debug               - clear the tracing for all functions
set_debug fn              - enable tracing for the functions fn; use \"+fn\" to preserve existing settings
add_debug_code fn         - enable debug code for the functions fn (supported by this shell: ${TYPESET_F_SUPPORTED})

exit                      - exit the debug shell
quit                      - end the script using die
abort                     - abort the script using kill -9

!<code>                   - execute the instructions \"<code>\"
<code>                    - execute the instructions using \"eval <code>\"

Notes:

\"fn\" can be one or more function names or pattern; use \"functions fn\" to test the value of \"fn\"

"        ;;

      "exit" )
        "break";
        ;;

      "quit" )
        INSIDE_DEBUG_SHELL=${__FALSE}
        die 254 "${SCRIPTNAME} aborted by the user"
        ;;

      "abort" )
        LogMsg "${SCRIPTNAME} aborted with \"kill -9\" by the user"
        INSIDE_DEBUG_SHELL=${__FALSE}
        "kill" -9 $$
        ;;

      "verbose" )
        [ ${VERBOSE} = ${__TRUE} ] && VERBOSE=${__FALSE} || VERBOSE=${__TRUE}
        "printf" "The verbose switch is now ${__TRUE_FALSE[${VERBOSE}]} \n"
        ;;

      "vars" | "variables" )
        print_runtime_variables 
        ;;

      "savedfuncs" )
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi
         if [ "${__LIST_OF_SAVED_FUNCTIONS}"x = ""x ] ; then
            "printf" "There are no saved functions\n"
         else
            "printf"  "Saved functions are: \n${__LIST_OF_SAVED_FUNCTIONS} \n"
         fi
         continue
         ;;
      
      "savefunc "* | "saveFunc "* )
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi
         FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"

         for CUR_VALUE in ${FUNCTION_LIST} ; do
         
           CUR_FUNCTION_CODE="$( "typeset" -f "${CUR_VALUE}" 2>/dev/null )"
           if [ $? -ne 0 ] ; then
             "printf" "The function ${CUR_VALUE} is not defined\n"
             continue
           fi
           
           FUNC_SAVE_VAR="__FUNCTION_${CUR_VALUE}"
           eval FUNC_SAVE_CONTENT="\$${FUNC_SAVE_VAR}"
           if [ "${FUNC_SAVE_CONTENT}"x != ""x ] ; then
             "printf" "The function ${CUR_VALUE} is already saved\n"
             continue
           fi

           "printf" "Saving the current code for the function ${CUR_VALUE} ...\n"
           eval ${FUNC_SAVE_VAR}="\${CUR_FUNCTION_CODE}"
           __LIST_OF_SAVED_FUNCTIONS="${__LIST_OF_SAVED_FUNCTIONS} ${CUR_VALUE} "
         done      
         ;;

      "restorefunc "* | "restfunc "* | "restFunc "* )
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi

         FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"
         
         for CUR_VALUE in ${FUNCTION_LIST} ; do
           FUNC_SAVE_VAR="__FUNCTION_${CUR_VALUE}"
           eval FUNC_SAVE_CONTENT="\$${FUNC_SAVE_VAR}"
           if [ "${FUNC_SAVE_CONTENT}"x = ""x ] ; then
             "printf" "There is no saved code for the function ${CUR_VALUE}\n"
             continue
           fi

           "printf" "Restoring the code for the function ${CUR_VALUE} ...\n"

           "echo" "${FUNC_SAVE_CONTENT}" >"${TMP_FILE1}"
            eval . "${TMP_FILE1}"
         done
         ;;

      "viewsavedfunc "* | "viewsavedFunc "*)
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi

         if [ "${PAGER}"x = ""x ] ; then
           "printf" "No valid editor found (set the variable PAGER before calling this script)\n"
           continue
         fi

         if [ ! -x "${PAGER}" ] ; then
           "printf" "${PAGER} not found or not executable (check the variable PAGER)\n"
           continue
         fi

         FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"
         
         for CUR_VALUE in ${FUNCTION_LIST} ; do
           FUNC_SAVE_VAR="__FUNCTION_${CUR_VALUE}"
           eval FUNC_SAVE_CONTENT="\$${FUNC_SAVE_VAR}"
           if [ "${FUNC_SAVE_CONTENT}"x = ""x ] ; then
             "printf" "There is no saved code for the function ${CUR_VALUE}\n"
             continue
           fi

           "printf" "Viewing the code for the saved function ${CUR_VALUE} ...\n"

           "echo" "${FUNC_SAVE_CONTENT}" >"${TMP_FILE1}"
           ${PAGER} "${TMP_FILE1}"
         done
         ;;

      "clearsavedfunc "* | "clearsavedFunc "* )
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi

         FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"
         
         for CUR_VALUE in ${FUNCTION_LIST} ; do
           FUNC_SAVE_VAR="__FUNCTION_${CUR_VALUE}"
           eval FUNC_SAVE_CONTENT="\$${FUNC_SAVE_VAR}"
           if [ "${FUNC_SAVE_CONTENT}"x = ""x ] ; then
             "printf" "There is no saved code for the function ${CUR_VALUE}\n"
             continue
           fi
           "printf" "Deleting the saved code for the function ${CUR_VALUE} ...\n"
           __LIST_OF_SAVED_FUNCTIONS=" ${__LIST_OF_SAVED_FUNCTIONS% ${CUR_VALUE} *} ${__LIST_OF_SAVED_FUNCTIONS#* ${CUR_VALUE} }"
           unset FUNC_SAVE_VAR

         done           
         ;;


      "editfunc "* | "editFunc "* )
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi

         if [ "${EDITOR}"x = ""x ] ; then
           "printf" "No valid editor found (set the variable EDITOR before calling this script)\n"
           continue
         fi

         if [ ! -x "${EDITOR}" ] ; then
           "printf" "${EDITOR} not found or not executable (check the variable EDITOR)\n"
           continue
         fi

         FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"
         
         for CUR_VALUE in ${FUNCTION_LIST} ; do
           USER_INPUT1=""
           
           FUNC_SAVE_VAR="__TMP_FUNCTION_${CUR_VALUE}"
           eval CUR_FUNCTION_CODE="\$${FUNC_SAVE_VAR}"
           [ "${CUR_FUNCTION_CODE}"x = ""x ] && CUR_FUNCTION_CODE="$( "typeset" -f "${CUR_VALUE}" 2>/dev/null )"

           if [ "${CUR_FUNCTION_CODE}"x = ""x ] ; then
             "printf" "The function \"${CUR_VALUE}\" is not defined\n"
             "printf" "Create a new function \"${CUR_VALUE}\" (y/N)? " 
             "read" USER_INPUT1
             if [ "${USER_INPUT1}"x = "y"x ] ; then
               CUR_FUNCTION_CODE="$( typeset -f function_template | sed "s/function_template/${CUR_VALUE}/g" )"
             else
               "printf" "New function \"${CUR_VALUE}\" not created.\n"
               "continue"
             fi
             
           else
             CUR_FUNCTION_CODE="# delete the existing function defintion 
unset -f ${CUR_VALUE}

${CUR_FUNCTION_CODE}
"
           fi
           "echo" "${CUR_FUNCTION_CODE}" >"${TMP_FILE1}"

           HASHCODE1="$( cksum "${TMP_FILE1}" 2>/dev/null | cut -f1 -d " "  )"
           [ "${HASHCODE1}"x = ""x ] && HASHCODE1="$( <"${TMP_FILE1}" )"

           while true ; do
             ${EDITOR} "${TMP_FILE1}"

             HASHCODE2="$( cksum "${TMP_FILE1}" 2>/dev/null | cut -f1 -d " "  )"
             [ "${HASHCODE2}"x = ""x ] && HASHCODE2="$( <"${TMP_FILE1}" )"

             if [ "${HASHCODE1}"x = "${HASHCODE2}"x -a "${USER_INPUT1}"x = ""x  ] ; then
               "printf" "No changes found in the edited source code.\n"
               break
             else               
               "printf" "Checking the new source code for \"${CUR_VALUE}\" using the shell ${CUR_SHELL} now ...\n"
               ${CUR_SHELL} -x -n "${TMP_FILE1}"
               if [ $? -ne 0 ] ; then
                 "printf" "Syntax Errors found in the new source code for \"${CUR_VALUE}\" - edit again (Y/n)? "
                 "read" USER_INPUT1
                 [ "${USER_INPUT1}"x != "n"x ] && continue
                  "printf" "New source code for \"${CUR_VALUE}\" ignored\n"
                 break
               fi                 
               "printf" "Enabling the new source code for \"${CUR_VALUE}\" now ...\n"
               . "${TMP_FILE1}"

               eval  ${FUNC_SAVE_VAR}="\$( typeset -f  ${CUR_VALUE} )"
               break
             fi
           done
         done
         ;;

      "func "* | "viewfunc "* | "viewFunc "* )
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi
         
         FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"
         
         for CUR_VALUE in ${FUNCTION_LIST} ; do

           FUNC_SAVE_VAR="__TMP_FUNCTION_${CUR_VALUE}"
           eval CUR_FUNCTION_CODE="\$${FUNC_SAVE_VAR}"
           [ "${CUR_FUNCTION_CODE}"x = ""x ] && CUR_FUNCTION_CODE="$( "typeset" -f "${CUR_VALUE}" 2>/dev/null )"

           "typeset" +f "${CUR_VALUE}" 2>/dev/null 1>/dev/null
           if [ $? -ne 0 ] ; then
             "printf" "The function ${CUR_VALUE} is not defined\n\n"
             "continue"
           else
             "printf" "${CUR_FUNCTION_CODE}\n"      
           fi
         done
         ;;

      "functions" | "func" | "funcs" )
        "typeset" +f | grep -v "^__"

        ;;

      "functions "* | "func "* | "funcs "* )
        "printf" "$( __evaluate_fn "${CMD_PARAMETER}" )\n"
        ;;
         
      "add_debug_code"* )
         if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
           "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
           continue
         fi
         
         FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"
         
         for CUR_VALUE in ${FUNCTION_LIST} ; do
           "typeset" +f "${CUR_VALUE}" 2>/dev/null 1>/dev/null
           if [ $? -ne 0 ] ; then
             "printf" "The function ${CUR_VALUE} is not defined\n"
             "continue"
           fi

           if [[ $( "typeset" -f "${CUR_VALUE}" 2>&1 ) == *\$\{__DEBUG_CODE\}* ]] ; then
             "printf" "The function ${CUR_VALUE} is already debug enabled\n"
             "continue"
           fi
           "printf" "Adding debug code to the function ${CUR_VALUE} ...\n"   
            if [ ${USE_ONLY_KSH88_FEATURES} = 0 ] ; then
              ADD_CODE=" typeset __FUNCTION=${CUR_VALUE}; "
            else
              ADD_CODE="  "
            fi
            eval "$( typeset -f  "${CUR_VALUE}" | sed "1 s/{/\{ ${ADD_CODE}\\\$\{__DEBUG_CODE\}\;/" )"	                    
          done
          ;;

      view_debug | viewdebug )
        if [ "${TRACE_FEATURE_SUPPORTED}"x != "yes"x ] ; then
          "printf" "Warning: The tracing features using \$0 are not supported by this shell\n"
        fi
        
        if [ "${__FUNCTIONS_WITH_DEBUG_CODE}"x != ""x ] ; then
          "printf" "Debug code is currently enabled for these functions: \n${__FUNCTIONS_WITH_DEBUG_CODE}\n"
          [ ${VERBOSE} = ${__TRUE} ] && "printf" "The current debug code for all functions (\$__DEBUG_CODE) is:\n${__DEBUG_CODE}\n" 
        else
          "printf" "Debug code is currently enabled for no function\n"
        fi        
        ;;

      clear_debug | cleardebug )
        if [ "${TRACE_FEATURE_SUPPORTED}"x != "yes"x ] ; then
          "printf" "Warning: The tracing features using \$0 are not supported by this shell\n"
        fi
        "printf" "Clearing the debug code now ...\n"
        __DEBUG_CODE=""
        __FUNCTIONS_WITH_DEBUG_CODE=""
        ;;
          
      "debug "* | "set_debug "* | "setdebug "* )
        if [ "${TRACE_FEATURE_SUPPORTED}"x != "yes"x ] ; then
          "printf" "Warning: The tracing features using \$0 are not supported by this shell\n"
        fi

        if [ "${CMD_PARAMETER}"x != ""x ] ; then
          "printf" "Enabling debug code for the function(s) \"${CMD_PARAMETER}\" now\n"
          CUR_STATEMENT="[ 0 = 1 "

          if [ "${__KSH_VERSION}"x = "93"x -a ${USE_ONLY_KSH88_FEATURES} = ${__FALSE} ] ; then
            CUR_STATEMENT="__FUNCTION=\"\${.sh.fun}\" ; ${CUR_STATEMENT}"
          fi

          if [[ ${CMD_PARAMETER} == +* ]] ; then
# preserve existing settings          
            "printf" "Current settings for debug code (${__FUNCTIONS_WITH_DEBUG_CODE}) are preserved.\n"
            FUNCTION_LIST="${__FUNCTIONS_WITH_DEBUG_CODE} $( __evaluate_fn "${CMD_PARAMETER#*+}" )"
          else
# overwrite existing settings          
            "printf" "Current settings for debug code are overwritten.\n"
            FUNCTION_LIST="$( __evaluate_fn "${CMD_PARAMETER}" )"
          fi

          __FUNCTIONS_WITH_DEBUG_CODE=""
          for CUR_VALUE in ${FUNCTION_LIST} ; do
            [[ ${CUR_VALUE} == +* ]] && CUR_VALUE="${CUR_VALUE#*+}"
            
            if [[ ${__FUNCTIONS_WITH_DEBUG_CODE} == *\ ${CUR_VALUE}\ * ]] ; then
              "printf" "Debug code is already enabled for the function ${CUR_VALUE}\n"
              continue
            fi

            "printf" "Enabling debug code for the function \"${CUR_VALUE}\" ...\n"
            __FUNCTIONS_WITH_DEBUG_CODE="${__FUNCTIONS_WITH_DEBUG_CODE} ${CUR_VALUE} "
            CUR_STATEMENT="${CUR_STATEMENT} -o \"\$0\"x = \"${CUR_VALUE}\"x -o \"\${__FUNCTION}\"x = \"${CUR_VALUE}\"x "

            if ! "typeset" +f "${CUR_VALUE}" >/dev/null ; then
              "printf" "WARNING: The function \"${CUR_VALUE}\" is not defined\n"
               continue
            fi
 
            if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
              "printf" "\"typeset -f\" required for \"${CUR_CMD}\" is NOT supported by this shell\n"
               continue
            fi

            if [[ $( "typeset" -f "${CUR_VALUE}" 2>&1 ) != *\$\{__DEBUG_CODE\}* ]] ; then
              "printf" "Adding debug code to the function ${CUR_VALUE} ...\n"           
              ADD_CODE=" typeset __FUNCTION=${CUR_VALUE}; "
              eval "$( typeset -f  "${CUR_VALUE}" | sed "1 s/{/\{ ${ADD_CODE}\\\$\{__DEBUG_CODE\}\;/" )"	                    
            fi
          done
          CUR_STATEMENT="eval ${CUR_STATEMENT} ] && printf \"\n*** Enabling trace for the function \${__FUNCTION:=\$0} ...\n\" >&2 && set -x "
          __DEBUG_CODE="${CUR_STATEMENT}"

        else
          "printf" " ${USER_INPUT}: Parameter missing\n"
        fi 
        ;;

      "" )
        :
        ;;

      * )
        if [ "${USER_INPUT}"x = "."x -o "${USER_INPUT}"x = "!."x ] ; then
            "printf" "\".\" without parameter is useless\n"
            continue          
        elif [ "${USER_INPUT}"x = "function"x ] ; then
          continue
        fi
        
        if [[ ${USER_INPUT} = .\ * || ${USER_INPUT} = !.\ * ]] ; then
          eval "CUR_FUNCTION_CODE=${CMD_PARAMETER}"
          if [ "${CUR_FUNCTION_CODE}"x != "${CMD_PARAMETER}"x ] ; then
            "printf" "File to source in is \"${CUR_FUNCTION_CODE}\" \n"
          fi
          
          if [ ! -r "${CUR_FUNCTION_CODE}" ] ; then
            "printf" "The file \"${CUR_FUNCTION_CODE}\" does not exist or is not readable\n"
            continue
          fi    
          "printf" "Checking the file \"${CUR_FUNCTION_CODE}\" for errors using the shell ${CUR_SHELL} ...\n"
          ${CUR_SHELL} -x -n "${CUR_FUNCTION_CODE}"
          if [ $? -ne 0 ] ; then
            "printf" "There is a syntax error in the file \"${CUR_FUNCTION_CODE}\" \n"
            continue
          fi
        fi

        if [[ ${USER_INPUT} = !* ]] ; then
          "printf" "Executing now \"${USER_INPUT#*!}\" ...\n"
          ${USER_INPUT#*!}
        else
          "printf" "Executing now \"eval ${USER_INPUT}\" ...\n"
          "eval" ${USER_INPUT}
        fi
        "printf" "\n---------\nRC is $?\n"    
        ;;
    esac
  done </dev/tty >/dev/tty 2>&1

  [ "${__TMP__STTY_SETTINGS}"x != ""x ] &&  stty ${__TMP__STTY_SETTINGS}

  INSIDE_DEBUG_SHELL=${__FALSE}

  "return" ${THISRC}
}

# ----------------------------------------------------------------------
# DebugShell
#
# this is a wrapper function for __DebugShell
#
# Usage: DebugShell
#
# returns: ${__TRUE}
#
# Input is always read from /dev/tty; output always goes to /dev/tty
# so DebugShell is only allowed if STDIN is a tty.
#
function DebugShell {
  typeset __FUNCTION="DebugShell"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  
  typeset THISRC=${__TRUE}

  while true ; do
    __DebugShell $*
    THISRC=$?
    [ ${INSIDE_DEBUG_SHELL}x = ${__FALSE}x ]  && break
    INSIDE_DEBUG_SHELL=${__FALSE}
  done
  
  return ${THISRC}
}

# ----------------------------------------------------------------------
# __enable_trace_for_functions
#
# enable trace for functions
#
# Usage: __enable_trace_for_functions
#
# returns: ${__TRUE}
#
function __enable_trace_for_functions {
  typeset __FUNCTION="__enable_trace_for_functions"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  
  typeset THISRC=${__TRUE}
  typeset FUNCTIONS_TO_TRACE="$*"
  typeset CUR_STATEMENT=""
  typeset CUR_VALUE=""
  typeset ADD_CODE=""
  
  if [ "${FUNCTIONS_TO_TRACE}"x != ""x ] ; then
    CUR_STATEMENT="[ 0 = 1 "

    if [ "${__KSH_VERSION}"x = "93"x -a ${USE_ONLY_KSH88_FEATURES} = ${__FALSE} ] ; then
      CUR_STATEMENT="__FUNCTION=\"\${.sh.fun}\" ; ${CUR_STATEMENT}"
    fi

    __FUNCTIONS_WITH_DEBUG_CODE=""
    FUNCTION_LIST="$( __evaluate_fn "${FUNCTIONS_TO_TRACE}" )"
    for CUR_VALUE in ${FUNCTION_LIST} ; do
      LogMsg "Enabling trace for the function \"${CUR_VALUE}\" ..."

      if [[ ${__FUNCTIONS_WITH_DEBUG_CODE} == *\ ${CUR_VALUE}\ * ]] ; then
        "printf" "Debug code is already enabled for the function ${CUR_VALUE}"
        continue
      fi
    
      CUR_STATEMENT="${CUR_STATEMENT} -o \"\$0\"x = \"${CUR_VALUE}\"x -o \"\${__FUNCTION}\"x = \"${CUR_VALUE}\"x  "

       __FUNCTIONS_WITH_DEBUG_CODE="${__FUNCTIONS_WITH_DEBUG_CODE} ${CUR_VALUE} "

      if ! typeset +f "${CUR_VALUE}" >/dev/null ; then
        LogMsg "The function \"${CUR_VALUE}\" is not defined"
        continue
      fi

      if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
        :
      elif [[ $( typeset -f "${CUR_VALUE}" 2>&1 ) != *\$\{__DEBUG_CODE\}* ]] ; then
        LogMsg "Adding debug code to the function \"${CUR_VALUE}\" ..."           
        ADD_CODE=" typeset __FUNCTION=${CUR_VALUE}; "
        eval "$( typeset -f  "${CUR_VALUE}" | sed "1 s/{/\{ ${ADD_CODE}\\\$\{__DEBUG_CODE\}\;/" )"	                    
      else
        LogMsg "\"${CUR_VALUE}\" already contains debug code."      
      fi
    done
    CUR_STATEMENT="eval ${CUR_STATEMENT} ] && printf \"\n*** Enabling trace for the function \${__FUNCTION:=\$0} ...\n\" >&2 && set -x "
    if [ "${__DEBUG_CODE}"x != ""x ] ; then
      if [[ "${__DEBUG_CODE}" == *\; ]] ; then
        __DEBUG_CODE="${__DEBUG_CODE}  ${CUR_STATEMENT}"
      else
        __DEBUG_CODE="${__DEBUG_CODE} ; ${CUR_STATEMENT}"
      fi
    else
      __DEBUG_CODE="${CUR_STATEMENT}"
    fi
  
    if [ "${TRACE_FEATURE_SUPPORTED}"x != "yes"x ] ; then
      LogWarning "The tracing features are only supported using the local variable __FUNCTION by this shell"
    fi
  
    if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
      LogWarning "\"typeset -f\" is not supported by this shell - can not check or add the debug code to the functions"
    fi

  fi
  
  return ${THISRC}
}

# ----------------------------------------------------------------------
# show_script_usage
#
# write the script usage to STDOUT
#
# usage: show_script_usage
#
# returns: ${__TRUE} - the message was written
#
# note: the function writes all lines from the script that start with
#       "#H#" without the "#H#"
#
function show_script_usage {
  typeset __FUNCTION="show_script_usage"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  typeset HELPMSG=""
  typeset REGEX=""
  
  if [ ${SHORT_HELP} = ${__TRUE} ]; then
    REGEX="^#h#"
  else
    REGEX="^#H#|^#h#"
  fi
  
  HELPMSG="$( egrep "${REGEX}" "${REAL_SCRIPTNAME}" | cut -c4- | sed "s/create_image.sh/${SCRIPTNAME}/g" )"
   
  eval echo \""${HELPMSG}"\"

  if [ "${USAGE_HELP}"x != ""x ] ; then
    echo "${USAGE_HELP}"
  fi

  if [ "${ENABLE_DEBUG}"x = "${__TRUE}x" ] ; then
    echo "
Current environment: ksh version: ${__KSH_VERSION} | change function code supported: ${TYPESET_F_SUPPORTED} | tracing feature using \$0 supported: ${TRACE_FEATURE_SUPPORTED}
"
  else
    echo "
Note: The parameter -D and --var are disabled
"
  fi
  
# execute the function show_extended_usage_help if defined and the parameter
# -v was found
#
  if [ ${VERBOSE} = ${__TRUE} ] ; then  
    if typeset -f show_extended_usage_help 2>/dev/null  >/dev/null ; then
      show_extended_usage_help
    fi
  fi
  
  return ${THISRC}
}

# ----------------------------------------------------------------------
# general exit routine
#      

# ----------------------------------------------------------------------
# cleanup
#
# Housekeeping tasks (in this order):
#
#   - execute the cleanup functions
#   - kill temporary processes 
#   - remove temporary files 
#   - remove temporary directories
#   - execute the finish functions
#
# usage: cleanup
#
# returns: 0
#
function cleanup {
  typeset __FUNCTION="cleanup"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset CUR_DIR=""
  typeset CUR_FILE=""
  typeset CUR_PID=""
  typeset CUR_KILL_PROC_TIMEOUT=""
  typeset CUR_FUNC=""
  typeset CUR_DEV0=""
  typeset CUR_DEV1=""
  typeset CUR_MOUNT=""
  typeset CUR_MOUNT1=""
  typeset i=0
  typeset ROUTINE_PARAMETER=""
  
  cd /
  
  LogRuntimeInfo "Housekeeping process started ...." 
  if [ $? -ne 0 -a "${PREFIX}"x != ""x ] ; then
    LogMsg "-"
    LogMsg "*** Housekeeping is starting ..."
  fi
  
  if [ "${CLEANUP_FUNCTIONS}"x != ""x -a "${NO_EXIT_ROUTINES}"x != "${__TRUE}"x ] ; then
    LogRuntimeInfo "Executing the cleanup functions \"${CLEANUP_FUNCTIONS}\" ..."
  
    for CUR_FUNC in ${CLEANUP_FUNCTIONS} ; do

      ROUTINE_PARAMETER="${CUR_FUNC#*:}"
      CUR_FUNC="${CUR_FUNC%%:*}"
      [ "${CUR_FUNC}"x = "${ROUTINE_PARAMETER}"x ] && ROUTINE_PARAMETER="" || ROUTINE_PARAMETER="$( IFS=: ; printf "%s " ${ROUTINE_PARAMETER}  )"
    
      typeset +f "${CUR_FUNC}" 2>/dev/null >/dev/null${CUR_KILL_PROC_TIMEOUT}
      if [ $? -eq 0 ] ; then
        LogRuntimeInfo "Executing the cleanup function \"${CUR_FUNC}\" (Parameter are: \"${ROUTINE_PARAMETER}\") ..."
        INSIDE_CLEANUP_ROUTINE=${__TRUE}
        ${PREFIX} ${CUR_FUNC} ${ROUTINE_PARAMETER}
        INSIDE_CLEANUP_ROUTINE=${__FALSE}
      else
        LogRuntimeInfo "The cleanup function \"${CUR_FUNC}\" is not defined - ignoring this entry"
      fi
    done
  else
    LogRuntimeInfo "No cleanup functions defined or cleanup functions disabled"
  fi

  if [ "${PROCS_TO_KILL}"x != ""x -a "${NO_KILL_PROCS}"x != "${__TRUE}"x ] ; then
    LogRuntimeInfo "Stopping the processes to kill \"${PROCS_TO_KILL}\" ..."
    ${PREFIX} KillProcess ${PROCS_TO_KILL}
  else
    LogRuntimeInfo "No processes to kill defined or process killing disabled"
  fi
  
  if [ "${FILES_TO_REMOVE}"x != ""x -a "${NO_TEMPFILES_DELETE}"x != "${__TRUE}"x ] ; then
    LogRuntimeInfo "Removing the temporary files \"${FILES_TO_REMOVE}\" ..." 
    for CUR_FILE in ${FILES_TO_REMOVE} ; do
      if [ -f "${CUR_FILE}" ] ; then
        LogRuntimeInfo "Removing the file \"${CUR_FILE}\" ..."
        ${PREFIX} rm -f "${CUR_FILE}"
      else
        LogRuntimeInfo "The file \"${CUR_FILE}\" does not exist."
      fi
    done
  else
    LogRuntimeInfo "No files to delete defined or files deleting disabled"
  fi
  
  if [ "${DIRS_TO_REMOVE}"x != ""x -a "${NO_TEMPDIR_DELETE}"x != "${__TRUE}"x ] ; then
    LogRuntimeInfo "Removing the temporary directories \"${DIRS_TO_REMOVE}\" ..."
    for CUR_DIR in ${DIRS_TO_REMOVE} ; do
      if [ -d "${CUR_DIR}" ] ; then
        LogRuntimeInfo "Removing the directory \"${CUR_DIR}\" ..."
        ${PREFIX} rm -rf "${CUR_DIR}"
      else
        LogRuntimeInfo "The directory \"${CUR_DIR}\" does not exist"
      fi
    done
  else
    LogRuntimeInfo "No directories to remove defined or directory removing disabled"
  fi

  if [ "${MOUNTS_TO_UMOUNT}"x != ""x -a "${NO_UMOUNT_MOUNTPOINTS}"x != "${__TRUE}"x ] ; then
    LogRuntimeInfo "Umounting the mount points to umount \"${MOUNTS_TO_UMOUNT}\" ..."
    for CUR_MOUNT in ${MOUNTS_TO_UMOUNT} ; do
      if [[ ${CUR_MOUNT} != /* ]] ; then
        LogRuntimeInfo "\"${CUR_MOUNT}\" is not a mount point"
        continue
      fi

      if [ ! -d "${CUR_MOUNT}" ] ; then
        LogRuntimeInfo "\"${CUR_MOUNT}\" does not exist"
        continue
      fi

      CUR_MOUNT1="${CUR_MOUNT%/*}" 
      [ "${CUR_MOUNT1}"x = ""x ] && CUR_MOUNT1="/"
      CUR_DEV0="$( df -h ${CUR_MOUNT}  2>/dev/null | tail -1 | awk '{ print $1 };' )"
      CUR_DEV1="$( df -h ${CUR_MOUNT1} 2>/dev/null | tail -1 | awk '{ print $1 };' )"
      if [ "${CUR_DEV1}"x != "${CUR_DEV0}"x ] ; then
        LogRuntimeInfo "Umounting \"${CUR_MOUNT}\" ..."
        ${PREFIX} umount "${CUR_MOUNT}"
      else
        LogRuntimeInfo "\"${CUR_MOUNT}\" is not mounted"
      fi
    done
  else
    LogRuntimeInfo "No mount points to umount configured"
  fi
  
  if [ "${FINISH_FUNCTIONS}"x != ""x  -a "${NO_FINISH_ROUTINES}"x != "${__TRUE}"x ] ; then
    LogRuntimeInfo "Executing the finish functions \"${FINISH_FUNCTIONS}\" ..."
    for CUR_FUNC in ${FINISH_FUNCTIONS} ; do

      ROUTINE_PARAMETER="${CUR_FUNC#*:}"
      CUR_FUNC="${CUR_FUNC%%:*}"
      [ "${CUR_FUNC}"x = "${ROUTINE_PARAMETER}"x ] && ROUTINE_PARAMETER="" || ROUTINE_PARAMETER="$( IFS=: ; printf "%s " ${ROUTINE_PARAMETER}  )"

      typeset +f "${CUR_FUNC}" 2>/dev/null >/dev/null
      if [ $? -eq 0 ] ; then
        LogRuntimeInfo "Executing the finish function \"${CUR_FUNC}\" (Parameter are: \"${ROUTINE_PARAMETER}\") ..."
        INSIDE_FINISH_ROUTINE=${__TRUE}
        ${PREFIX} ${CUR_FUNC} ${ROUTINE_PARAMETER}
        INSIDE_FINISH_ROUTINE=${__FALSE}
      else
        LogRuntimeInfo "The finish function \"${CUR_FUNC}\" is not defined - ignoring this entry"
      fi
    done
  else
    LogRuntimeInfo "No finish functions defined or finish functions disabled"
  fi
  
  return 0
}

# ----------------------------------------------------------------------
# die
#
# do the housekeeping and end the script 
#
# usage: die [script_returncode] [end_message]
#
# returns: the function ends the script
#
# default returncode is 0; there is no default for end_message
#
function die {
  typeset __FUNCTION="die"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  __unsettraps

  typeset THISRC=$1
  [ "${THISRC}"x = ""x ] && THISRC=0
  
  INSIDE_DIE=${__TRUE}


  if [ "${__STTY_SETTINGS}"x != ""x ] ; then
    LogRuntimeInfo "Resetting the tty ..."
    stty ${__STTY_SETTINGS}
    __STTY_SETTINGS=""
  fi
  
  if [ ${NO_CLEANUP}x = ${__TRUE}x ] ; then
    LogRuntimeInfo "House keeping is disabled"
  else
    cleanup
  fi
  
  if [ $# -ne 0 ] ; then
    shift
    if [ $# -ne 0 ] ; then
      if [ ${THISRC} = 0 ] ; then
        LogMsg "$*"
      else
        LogError "$*! RC=${THISRC}"
      fi
    fi      
  fi

  if [ "${PREFIX}"x != ""x ] ; then
    LogMsg "-"
    LogMsg "*** Running in dry-run mode -- no changes were done. The dryrun prefix used was \"${PREFIX}\" "
    LogMsg "-"
  fi

  if [ "${LOGFILE}"x != ""x -a -f "${LOGFILE}" ] ; then
    LogMsg "### The logfile used was ${LOGFILE}"
  fi

  ENDTIME_IN_SECONDS="$( date +%s )"
  ENDTIME_IN_HUMAN_READABLE_FORMAT="$( date "+%d.%m.%Y %H:%M:%S" )"

  if isNumber ${STARTTIME_IN_SECONDS} -a isNumber ${ENDTIME_IN_SECONDS}  ; then
    (( RUNTIME_IN_SECONDS = ENDTIME_IN_SECONDS - STARTTIME_IN_SECONDS ))
    RUNTIME_IN_HUMAN_READABLE_FORMAT="$( echo ${RUNTIME_IN_SECONDS} | awk '{printf("%d:%02d:%02d:%02d\n",($1/60/60/24),($1/60/60%24),($1/60%60),($1%60))}'  )"
  else
    RUNTIME_IN_SECONDS="?"
    RUNTIME_IN_HUMAN_READABLE_FORMAT=""
  fi

  LogMsg "### The start time was ${STARTTIME_IN_HUMAN_READABLE_FORMAT}, the script runtime is (day:hour:minute:seconds) ${RUNTIME_IN_HUMAN_READABLE_FORMAT} (= ${RUNTIME_IN_SECONDS} seconds)"

  LogMsg "### ${SCRIPTNAME} ended at ${ENDTIME_IN_HUMAN_READABLE_FORMAT} (The PID of this process is $$; the RC is ${THISRC})"

  
  exit ${THISRC}
}


# ----------------------------------------------------------------------
# signal_exit_handler
#
# signal handler for the signal EXIT
#
# usage: the function is called via the signal only
#
# returns: the function ends the script using the function die
#
function signal_exit_handler {  
  typeset __FUNCTION="signal_exit_handler"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  
  typeset SIGNAL_LINENO=$1
  LogRuntimeInfo "Signal handler for the signal EXIT called"
  
  [ ${INSIDE_EXIT_HANDLER} = ${__TRUE} ] && return
  INSIDE_EXIT_HANDLER=${__TRUE}
  
  if [ ${INSIDE_DIE} = ${__FALSE} ] ; then
    die 200 "Script aborted for unknown reason; EXIT signal received"
  fi  

  INSIDE_EXIT_HANDLER=${__FALSE}
}

# ----------------------------------------------------------------------
# signal_quit_handler
#
# signal handler for the signal QUIT
#
# usage: the function is called via the signal only
#
# returns: 
#
function signal_quit_handler {  
  typeset __FUNCTION="signal_quit_handler"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
 
  typeset SIGNAL_LINENO=$1
  LogRuntimeInfo "Signal handler for the signal QUIT called"
 
  [ ${INSIDE_QUIT_HANDLER} = ${__TRUE} ] && return
  INSIDE_QUIT_HANDLER=${__TRUE}

  if [ ${INSIDE_DIE} = ${__FALSE} ] ; then
    die 201 "Script aborted for unknown reason, QUIT signal received"
  fi  
  
  INSIDE_QUIT_HANDLER=${__FALSE}
}

# ----------------------------------------------------------------------
# signal_usr1_handler
#
# signal handler for the signal USR1
#
# usage: the function is called via the signal only
#
# returns: n/a
#
function signal_usr1_handler {
  typeset __FUNCTION="signal_usr1_handler"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset SIGNAL_LINENO=$1
  LogRuntimeInfo "Signal handler for the signal USR1 called in line ${SIGNAL_LINENO}"

  [ ${INSIDE_USR1_HANDLER} = ${__TRUE} ] && return
  INSIDE_USR1_HANDLER=${__TRUE}

  LogMsg "Signal USR1 received while in line ${SIGNAL_LINENO}" >&2
  DebugShell
  
  INSIDE_USR1_HANDLER=${__FALSE}
}

# ----------------------------------------------------------------------
# signal_usr2_handler
#
# signal handler for the signal USR2
#
# usage: the function is called via the signal only
#
# returns: n/a
#
function signal_usr2_handler {
  typeset __FUNCTION="signal_usr2_handler"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset SIGNAL_LINENO=$1
  LogRuntimeInfo "Signal handler for the signal USR2 called in line ${SIGNAL_LINENO}"

  [ ${INSIDE_USR1_HANDLER} = ${__TRUE} ] && return
  INSIDE_USR2_HANDLER=${__TRUE}

#  LogMsg "Signal USR2 received while in line ${SIGNAL_LINENO}" >&2
#  DebugShell
  
  INSIDE_USR2_HANDLER=${__FALSE}
}


# ----------------------------------------------------------------------
# signal_hup_handler
#
# signal handler for the signal HUP
#
# usage: the function is called via the signal only
#
# returns: n/a
#
function signal_hup_handler {
  typeset __FUNCTION="signal_hup_handler"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset SIGNAL_LINENO=$1
  LogRuntimeInfo "Signal handler for the signal HUP called in line ${SIGNAL_LINENO}"

  [ ${INSIDE_USR1_HANDLER} = ${__TRUE} ] && return
  INSIDE_HUP_HANDLER=${__TRUE}

#  LogMsg "Signal HUP received while in line ${SIGNAL_LINENO}" >&2
#  DebugShell
  
  INSIDE_HUP_HANDLER=${__FALSE}
}

# ----------------------------------------------------------------------
# signal_break_handler
#
# signal handler for the signal break (CTRL-C)
#
# usage: the function is called via the signal only
#
# returns: n/a
#
function signal_break_handler {
  typeset __FUNCTION="signal_break_handler"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset SIGNAL_LINENO=$1
  LogRuntimeInfo "Signal handler for the signal BREAK called in line ${SIGNAL_LINENO}"

  if [ ${INSIDE_BREAK_HANDLER} = ${__TRUE} ] ; then
    INSIDE_BREAK_HANDLER=${__FALSE}
    return
  fi

  LogMsg "Signal BREAK received while in line ${SIGNAL_LINENO}" >&2
  
  INSIDE_BREAK_HANDLER=${__TRUE}
  
  if [ "${BREAK_ALLOWED}"x = "DebugShell"x ] ; then
    if [ ${ENABLE_DEBUG}x = ${__TRUE}x ]  ; then
      LogMsg "*** DebugShell called via CTRL_C"
      DebugShell
    fi
  elif [ ${BREAK_ALLOWED} = ${__FALSE} ] ; then
    LogRuntimeInfo "CTRL-C is disabled for ${SCRIPTNAME}"
  else
    die 250 "${SCRIPTNAME} aborted by CTRL-C"
  fi
  
  INSIDE_BREAK_HANDLER=${__FALSE}
}

# ----------------------------------------------------------------------
#

# ----------------------------------------------------------------------
# print_runtime_variables
#
# print the current values of the runtime variables
#
# usage: print_runtime_variables 
#
# returns: ${__TRUE}
#
function print_runtime_variables {
  typeset __FUNCTION="print_runtime_variables"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
	
  typeset THISRC=${__TRUE}
  typeset CUR_VAR=""
  typeset CUR_VALUE=""
  typeset CUR_MSG=""
  
  for CUR_VAR in ${RUNTIME_VARIABLES} ${APPLICATION_VARIABLES} ; do
    if [[ ${CUR_VAR} == \#* ]] ; then
      CUR_MSG="*** $( echo "${CUR_VAR#*#}" | tr "_" " ")"
    else
      eval CUR_VALUE="\$${CUR_VAR}"
      CUR_MSG="  ${CUR_VAR}: \"${CUR_VALUE}\" "
    fi
    "printf"  "${CUR_MSG}\n" 
  done
  return ${THISRC}
}

# ----------------------------------------------------------------------


# ----------------------------------------------------------------------
# isNumber
#
# check if a value is an integer
#
# usage: isNumber testValue
#
# returns: ${__TRUE} - testValue is a number else not
#
function isNumber {
  typeset __FUNCTION="isNumber"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
	
  typeset THISRC=${__FALSE}

# old code:
#  typeset TESTVAR="$(echo "$1" | sed 's/[0-9]*//g' )"
#  [ "${TESTVAR}"x = ""x ] && return ${__TRUE} || return ${__FALSE}

  [[ $1 == +([0-9]) ]] && THISRC=${__TRUE} || THISRC=${__FALSE}

  return ${THISRC}
}

# ----------------------------------------------------------------------
# AskUser
#
# Ask the user (or use defaults depending on the parameter -n and -y)
#
# Usage: AskUser "message"
#
# returns: ${__TRUE} - user input is yes
#          ${__FALSE} - user input is no
#          USER_INPUT contains the user input
#
# Notes: "all" is interpreted as yes for this and all other questions
#        "none" is interpreted as no for this and all other questions
#
# If __NOECHO is ${__TRUE} the user input is not written to STDOUT
# __NOECHO is set to ${__FALSE} again in this function
#
# If __USE_TTY is ${__TRUE} the prompt is written to /dev/tty and the
# user input is read from /dev/tty . This is useful if STDOUT is redirected
# to a file.
#
# "shell" opens the DebugShell; set __DEBUG_SHELL_IN_ASKUSER to ${__FALSE}
# to disable the DebugShell in AskUser
#
function AskUser {
  typeset __FUNCTION="AskUser"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
	
  typeset THISRC=""

  if [ "${__USE_TTY}"x = "${__TRUE}"x ] ; then
    typeset mySTDIN="</dev/tty"
    typeset mySTDOUT=">/dev/tty"
  else
    typeset mySTDIN=""
    typeset mySTDOUT=""
  fi

  case ${__USER_RESPONSE_IS} in

   "y" ) USER_INPUT="y" ; THISRC=${__TRUE}
         ;;

   "n" ) USER_INPUT="n" ; THISRC=${__FALSE}
         ;;

     * ) while true ; do
           [ $# -ne 0 ] && eval printf "\"$* \"" ${mySTDOUT}
           if [ ${__NOECHO} = ${__TRUE} ] ; then
             __STTY_SETTINGS="$( stty -g )"
             stty -echo
           fi

           eval read USER_INPUT ${mySTDIN}
           if [ "${USER_INPUT}"x = "shell"x -a ${__DEBUG_SHELL_IN_ASKUSER} = ${__TRUE} ] ; then
             DebugShell
           else
             [ "${USER_INPUT}"x = "#last"x ] && USER_INPUT="${LAST_USER_INPUT}"
             break
           fi
         done

         if [ ${__NOECHO} = ${__TRUE} ] ; then
           stty ${__STTY_SETTINGS}
           __STTY_SETTINGS=""
         fi

         case ${USER_INPUT} in

           "y" | "Y" | "yes" | "Yes") THISRC=${__TRUE}  ;;

           "n" | "N" | "no" | "No" ) THISRC=${__FALSE} ;;

           "all" ) __USER_RESPONSE_IS="y"  ; THISRC=${__TRUE}  ;;

           "none" )  __USER_RESPONSE_IS="n" ;  THISRC=${__FALSE} ;;

           * )  THISRC=${__FALSE} ;;

        esac
        ;;
  esac
  [ "${USER_INPUT}"x != ""x ] && LAST_USER_INPUT="${USER_INPUT}"

  __NOECHO=${__FALSE}
  return ${THISRC}
}


# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# check_rcm_values
#
# init the variables neccessary for RCM access
#
# usage: check_rcm_values
#
# returns: ${__TRUE} - ok, variables set
#          ${__FALSE} - error initiating the RCm support
#
# This function is only useful in RCM environments!
#
function check_rcm_values {
  typeset __FUNCTION="check_rcm_values"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  typeset THISRC=${__TRUE}

  if [ "${RCM_HOSTID}"x = ""x ] ; then
    LogError "RCM_HOSTID is not set (check the file ${RCM_HOSTID_FILE})"
    THISRC=${__FALSE}
  fi

  if [ "${RCM_SERVICE}"x = ""x ] ; then
    LogError "Variable RCM_SERVICE is not set"
    THISRC=${__FALSE}
  fi

  if [ "${RCM_FUNCTION}"x = ""x ] ; then
    LogError "Variable RCM_FUNCTION is not set"
    THISRC=${__FALSE}
  fi
  
  return ${THISRC}
}

  
# ----------------------------------------------------------------------
# get_rcm_userid
#
# get the userid and password for RCM access from the user
#
# usage: get_rcm_userid
#
# returns: always ${__TRUE}, RCM_USERID and RCM_PASSWORD are set 
#
# note: the RCM_USERID is NOT neccessary for dbquery and dbgetfile
#
# This function is only useful in RCM environments!
#
function get_rcm_userid {
  typeset __FUNCTION="get_rcm_userid"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  typeset THISRC=${__TRUE}
  
  typeset STTY_SETTINGS="$( stty -g )"

  if [ "${RCM_USERID}"x = ""x ] ; then
#    printf "Please enter the RCM userid: " ; read RCM_USERID
    AskUser "Please enter the RCM userid: " ; RCM_USERID="${USER_INPUT}"
  fi
  
  if [ "${RCM_PASSWORD}"x = ""x ] ; then
    __NOECHO=${__TRUE}
    __USE_TTY=${__TRUE}
    AskUser "Please enter the RCM password for ${RCM_USERID}: " ; RCM_PASSWORD="${USER_INPUT}"
    __NOECHO=${__FALSE}
    __USE_TTY=${__FALSE}

#    stty -echo
#    printf "Please enter the RCM password: " ; read RCM_PASSWORD
#    stty ${STTY_SETTINGS}
  fi
  
  return ${THISRC}
}

# ----------------------------------------------------------------------
# Read_APPL_PARAMS_entries
#
# read the APPL_PARAMS entries for ${RCM_SERVICE}:${RCM_FUNCTION} from the RCM
#
# usage: Read_APPL_PARAMS_entries
#
# returns: ${__TRUE} - APPL_PARAMS read
#          ${__FALSE} - error reading the APPL_PARAMS
#
# The found APPL_PARAMS entries are stored in these variables.
#
# RCM_APPL_PARAMS_KEY[0] - no of entries found
#
# RCM_APPL_PARAMS_KEY[n] - PARAMETER field for the nth entry
# RCM_APPL_PARAMS_VAL[n] - VALUE field for the nth entry
#
# The variable FOUND_APPL_PARAM_ENTRY_KEYS contains all PARAMETER entries
# found in the RCM
#
# This function is only useful in RCM environments!
#
function Read_APPL_PARAMS_entries {
  typeset __FUNCTION="Read_APPL_PARAMS_entries"	
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  typeset THISRC=${__TRUE}

  typeset RCM_INCLUDE_FILE="/usr/db/RCM/Utility/shAPI_env"
   
  typeset DBQUERY_CMD=""
  typeset THIS_KEY=""
  typeset THIS_VALUE=""
  typeset i=0
  
  FOUND_APPL_PARAM_ENTRY_KEYS=""
    
  if [ "${RCM_INCLUDE_FILE}"x != ""x ] ; then
    if [ -r "${RCM_INCLUDE_FILE}" ] ; then
      . "${RCM_INCLUDE_FILE}"
    fi
  fi

  check_rcm_values || THISRC=${__FALSE}
  
  if  [ ! -x "${RCM_DBQUERY}" ] ; then
    LogError "${RCM_DBQUERY} not found or not executable"
    THISRC=${__FALSE}
  fi

  if [ ${THISRC} = ${__TRUE} ] ; then

    THISRC=${__FALSE}

# read the APPL_PARAMS from the RCM
#
    DBQUERY_CMD="${RCM_DBQUERY} --where \"{ hostid => '${RCM_HOSTID}', service => '${RCM_SERVICE}', function => '${RCM_FUNCTION}' }\" \
 --key appl_params_by_hostid_svc_func --fields=parameter,value "

    LogMsg "Executing "
    LogMsg "-"  "${DBQUERY_CMD}"

    eval ${DBQUERY_CMD} | tr -d '"' | sort | while read THIS_KEY THIS_VALUE ; do
      [ "${THIS_KEY}"x = ""x ] && continue
      
      (( i = i + 1 ))
      
      THISRC=${__TRUE}
      LogInfo "Key found: \"${THIS_KEY}\" = \"${THIS_VALUE}\" "

      case ${THIS_KEY} in

        * )
          LogMsg "Found the key \"${THIS_KEY}\" with the value \"${THIS_VALUE}\" "
          RCM_APPL_PARAMS_KEY[$i]="${THIS_KEY}"
          RCM_APPL_PARAMS_VAL[$i]="${THIS_VALUE}"
          FOUND_APPL_PARAM_ENTRY_KEYS="${FOUND_APPL_PARAM_ENTRY_KEYS} ${THIS_KEY}"
          ;;  

      esac
    done

    RCM_APPL_PARAMS_KEY[0]=$i
  fi

  [ ${THISRC} != ${__TRUE} ] && LogMsg "No config found in the RCM"

  return ${THISRC}
}


# ----------------------------------------------------------------------
# Retrieve_file_from_Jamaica
#
# retrieve a file from Jamaica (RCM)
#
# usage: Retrieve_file_from_Jamaica [file_name_in_rcm] {local_file_name}
#
# returns: ${__TRUE} - file retrieved
#          ${__FALSE} - file not found in Jamaica
#
# This function is only useful in RCM environments!
#
function Retrieve_file_from_Jamaica {
  typeset __FUNCTION="Retrieve_file_from_Jamaica"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}
  typeset THISRC=${__TRUE}

  typeset RCM_FILE="$1"
  typeset TARGET_FILE="$2"
  
  typeset NEW_FILE_CONTENTS=""

  check_rcm_values || THISRC=${__FALSE}
 
  if  [ ! -x "${RCM_DBGET_FILE}" ] ; then
    LogError "${RCM_DBGET_FILE} not found or not executable"
    THISRC=${__FALSE}
  fi

  if [ "${RCM_FILE}"x != ""x -a ${THISRC} = ${__TRUE} ] ; then

    [ "${TARGET_FILE}"x = ""x ] && TARGET_FILE="${RCM_FILE}"
    
    [ -r "${TARGET_FILE}" ] && ${PREFIX} rm "${TARGET_FILE}" 

    LogMsg "Executing "
    LogMsg "-"  "${RCM_DBGET_FILE} -f ${RCM_HOSTID} ${RCM_SERVICE} ${RCM_FUNCTION} ${RCM_FILE}"

    NEW_FILE_CONTENTS="$( ${RCM_DBGET_FILE} -f ${RCM_HOSTID} ${RCM_SERVICE} ${RCM_FUNCTION} "${RCM_FILE}" 2>/dev/null )"
    if [ "${NEW_FILE_CONTENTS}"x = ""x ] ; then
      LogWarning "${RCM_FILE} NOT found in the RCM"
    else
      LogMsg "Creating the file ${TARGET_FILE} (RCM entry is ${RCM_FILE})...."
      if [ "${PREFIX}"x = ""x ] ; then
        echo "${NEW_FILE_CONTENTS}" >"${TARGET_FILE}" && THISRC=${__TRUE}
      else
        ${PREFIX} echo "${NEW_FILE_CONTENTS} >${TARGET_FILE}" && THISRC=${__TRUE}
      fi
    fi
  fi

  return ${THISRC}
}

# ----------------------------------------------------------------------
# show_extended_usage_help
#
# function: show_extended_usage_help
#
# usage: this function is called in show_script_usage if the 
#        parameter -v and -h are used
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function show_extended_usage_help {
  typeset __FUNCTION="show_extended_usage_help"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
 
  typeset CUR_VAR=""
  typeset CUR_VALUE=""


#  HELPMSG="$( grep "^#H#" "${REAL_SCRIPTNAME}" | cut -c4- | sed "s/execute_tasks.sh/${SCRIPTNAME}/g" )"

# print also the verbose usage help if --v used
#
  if [ ${VERBOSE_LEVEL} -ge 1 ] ; then
    HELPMSG="$( grep "^#U#" "${REAL_SCRIPTNAME}" | cut -c4- | sed "s/restore_files_from_tsm.sh/${SCRIPTNAME}/g" )"
  
    eval echo \""${HELPMSG}"\"
  fi
  
# add your code her
#  LogMsg "This function is called if the parameter -v and -h are used"


  echo "Supported environment variables are:"
  echo ""
  
  for CUR_VAR in   ${ENV_VARIABLES} ; do
    eval CUR_VALUE="\$${CUR_VAR}"
    echo "  ${CUR_VAR} - current value is \"${CUR_VALUE}\" "
  done
  echo ""

# print also the history if the parameter -v is used two times
#
  if [ ${VERBOSE_LEVEL} -ge 2 ] ; then
    grep "^#V#" "${REAL_SCRIPTNAME}" | cut -c4- | sed "s#execute_tasks.sh#${REAL_SCRIPTNAME}#g"
  fi

# print also the template history if the parameter -v is used three times
#
  if [ ${VERBOSE_LEVEL} -ge 3 ] ; then
    grep "^#T#" "${REAL_SCRIPTNAME}" | cut -c4- | sed "s#execute_tasks.sh#${REAL_SCRIPTNAME}#g"
  fi

  VERBOSE_LEVEL=0
  return ${THISRC}
}
  

# ----------------------------------------------------------------------
# switch_to_background
#
# function: switch the current process running this script into the background
#
# usage: switch_to_background {no_redirect}
#
# parameter: no_redirect - do not redirect STDOUT and STDERR to a file
#
# returns: ${__TRUE} - ok, the process is running in the background
#          ${__FALSE} - error, can not switch the process into the background
#
function switch_to_background {
  typeset __FUNCTION="switch_to_background"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}

  if [ ${INSIDE_DEBUG_SHELL}x = ${__TRUE}x ] ; then
    LogError "${__FUNCTION} not allowed in the Debugshell"
    return ${__FALSE}
  fi

  typeset REDIRECT_STDOUT=${__TRUE}
  [ "$1"x = "no_redirect"x ] && REDIRECT_STDOUT=${__FALSE}

  typeset TMPFILE=""
  typeset TMPLOGFILE=""

  typeset SIGTSTP=""
  typeset SIGCONT=""

# the signals used to stop a process and to restart the process in the
# background are different in the various Unix OS
#  
  case ${CUR_OS} in 
  
     SunOS )
       SIGTSTP="24"
       SIGCONT="25"
       ;;

     Linux )
       SIGTSTP="20"
       SIGCONT="18"
       ;;

     AIX )
       SIGTSTP="18"
       SIGCONT="19"
       ;;

     Darwin )
       SIGTSTP="18"
       SIGCONT="19"
       ;;

  esac

  if [ "${SIGTSTP}"x = ""x -o "${SIGCONT}"x = ""x ] ; then
    LogError "${__FUNCTION}: I do not know the signals used for OS \"${CUR_OS}\" "
    THISRC=${__FALSE}
  else

    LogMsg "Switching the process for the script \"${SCRIPTNAME}\" with the PID $$ into the background now ..."
  
  # create a duplicate file descriptor for the current STDOUT file descriptor
  #
    exec 9>&1
  
  # the file used for STDOUT and STDERR for the background process
  # (this is a global variable!)
  #
  
    if [ ${REDIRECT_STDOUT} = ${__TRUE} ] ; then
      NOHUP_STDOUT_STDERR_FILE="${NOHUP_STDOUT_STDERR_FILE:=${PWD}/nohup.out}"
  
      LogMsg "STDOUT/STDERR now goes to the file \"${NOHUP_STDOUT_STDERR_FILE}\" "
    fi
    
    case ${CUR_OS} in 
  
      SunOS | Linux | AIX | Darwin )
        if [ ${REDIRECT_STDOUT} = ${__TRUE} ] ; then
          exec 1>"${NOHUP_STDOUT_STDERR_FILE}" 2>&1 </dev/null
        fi
        
        TMPFILE="/tmp/${SCRIPTNAME}.$$.temp.sh"
        TMPLOGFILE="/tmp/${SCRIPTNAME}.$$.temp.log"
        
  # use &9 to write messages to the old STDOUT file descriptor
  #      echo "Test Redirect, TMPFILE is ${TMPFILE} " >&9
  
  # create a temporary script to switch this process into the background
  #      
        echo "
  # script to switch the process $$ to the background
  #
  kill -${SIGTSTP} $$
  sleep 1
  kill -${SIGCONT} $$
  exit 0
  "     >"${TMPFILE}" && chmod 755  "${TMPFILE}" && \
            FILES_TO_REMOVE="${FILES_TO_REMOVE} ${TMPFILE} ${TMPLOGFILE}"
  
        if [ ! -x "${TMPFILE}" ] ; then
          THISRC=${__FALSE}
          LogError "Can not create the temporary file for switching the process into the background"
        else
          "${TMPFILE}" >"${TMPLOGFILE}" 2>&1 &
          sleep 1
          __settraps
  
          LogMsg "-" >&9
          LogMsg "*** The script \"${SCRIPTNAME}\" (PID is $$) should now run in the background ...
  " >&9
        fi
        ;;
  
      * ) 
        LogError "Can not switch a process into the background in ${CUR_OS}"
        THISRC=${__FALSE}
        ;; 
    esac
  
    tty -s && RUNNING_IN_TERMINAL_SESSION=${__TRUE} || RUNNING_IN_TERMINAL_SESSION=${__FALSE}
  
  # close the temporary file descriptor again  
    exec 9>&-

  fi

  return ${THISRC}
}


# ----------------------------------------------------------------------
# print_summaries
#
# function:  print summaries about the executed tasks
#
# usage: print_summaries
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function print_summaries {
  typeset __FUNCTION="print_summaries"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  
  LogMsg "-"
  LogMsg "Execution summary:"
  LogMsg "-"
  LogMsg "Tasks processed:               ${NO_OF_TASKS_PROCESSED}  "
  LogMsg "Tasks executed succesfully:    ${NO_OF_TASKS_EXECUTED_SUCCESSFULLY}"
  LogMsg "Tasks executed with errors:    ${NO_OF_TASKS_EXECUTED_WITH_ERRORS}"
  LogMsg "Tasks not executed on request: ${NO_OF_TASKS_SKIPPED_ON_REQUEST}"
  LogMsg "Tasks not found:               ${NO_OF_TASKS_NOT_FOUND}"
  
  if  [ ${NO_OF_TASKS_EXECUTED_WITH_ERRORS} != 0 ] ; then
    LogMsg "-"
    LogMsg "Tasks that end with errors are:"
    for CUR_TASK in ${TASKS_EXECUTED_WITH_ERRORS} ; do
      LogMsg "-" "    ${CUR_TASK}"
    done
    THISRC=100
  fi

  if  [ ${NO_OF_TASKS_SKIPPED_ON_REQUEST} != 0 ] ; then
    LogMsg "-"
    LogMsg "Tasks that were not executed on request:"
    for CUR_TASK in ${TASKS_SKIPPED_ON_REQUEST} ; do
      LogMsg "-" "    ${CUR_TASK#task_*}"
    done
    THISRC=100
  fi

  if  [ ${NO_OF_TASKS_NOT_FOUND} != 0 ] ; then
    LogMsg "-"
    LogMsg "Tasks not found are:"
    for CUR_TASK in ${TASKS_NOT_FOUND} ; do
      LogMsg "-" "    ${CUR_TASK#task_*}"
    done
    THISRC=110
  fi

  LogMsg "-"
  
  return ${THISRC}
}


# ----------------------------------------------------------------------
# ListDefinedTasksGroups
#
# function: list all defined task groups
#
# usage: ListDefinedTasksGroups [regex1] [... [regex#]]
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function ListDefinedTasksGroups {
  typeset __FUNCTION="ListDefinedTasksGroups"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}

  typeset THIS_MASK="$*"
  
  typeset CUR_OUTPUT=""
  typeset CUR_TASK_GROUP=""
  typeset CUR_TASK=""
 
  typeset CUR_TASK_OK="${__TRUE}"
  typeset CUR_TASK_GROUP_NAME=""
  typeset CUR_MASK=""

  typeset CUR_TASK_GROUP_INFO=""

  CUR_OUTPUT="$( set | cut -f1 -d "="  | grep "^TASK_GROUP_" )"

  if [ "${CUR_OUTPUT}"x != ""x ] ; then

    if [ "${THIS_MASK}"x = ""x ] ; then
      LogMsg "-" "Defined Task groups are:"
    else
      LogMsg "-" "Defined Task groups matching one of the regex \"${THIS_MASK}\" are:"
    fi

    for CUR_TASK_GROUP in ${CUR_OUTPUT} ; do
#      LogMsg "-" "${CUR_TASK_GROUP#*TASK_GROUP_} : $( eval echo "\$${CUR_TASK_GROUP}" )"

      if [ "${THIS_MASK}"x != ""x ] ; then
        for CUR_MASK in ${THIS_MASK} ; do
          [[ ${CUR_MASK} != *\** && ${CUR_MASK} != *\?* ]] && CUR_MASK="*${CUR_MASK}*"
          CUR_TASK_GROUP_NAME="${CUR_TASK_GROUP}"
          CUR_TASK_OK=${__TRUE}
          [[ ${CUR_TASK_GROUP_NAME} == ${CUR_MASK} ]] && break
          CUR_TASK_OK=${__FALSE}
        done
        [ ${CUR_TASK_OK} = ${__FALSE} ] && continue
      fi

        
      LogMsg "-"
      
      LogMsg "-" "${CUR_TASK_GROUP#*TASK_GROUP_} : "

      CUR_TASK_GROUP_INFO="$( eval echo \""\$${CUR_TASK_GROUP}"\" | grep "^#I#" | cut -c4- |  sed "s/^/#/g"  )"
      [ "${CUR_TASK_GROUP_INFO}"x != ""x -a ${VERBOSE} = ${__TRUE} ] && LogMsg "-" "${CUR_TASK_GROUP_INFO}"
      
      for CUR_TASK in $( eval echo \""\$${CUR_TASK_GROUP}"\" | grep -v "^#"  ) ; do
        LogMsg "-" "    ${CUR_TASK}"
      done
    done
  fi

  return ${THISRC}
}


# ----------------------------------------------------------------------
# ListDefinedTasks
#
# function: list all defined tasks
#
# usage: ListDefinedTasks [regex1] [... [regex#]]
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function ListDefinedTasks {
  typeset __FUNCTION="ListDefinedTasks"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  
  typeset NO_OF_TASKS_DEFINED=0

  typeset FIELD_SIZE=0
  typeset TASK_MASK=""
  typeset CUR_TASK_OK=${__FALSE}
  
  LogMsg "-"
  LogMsg "-" "Include files used are:"
  LogMsg "-"
  LogMsg "-" ${INCLUDE_FILES}
  LogMsg "-"
  if [ "${OPTIONAL_INCLUDE_FILES}"x != ""x ] ; then
    LogMsg "Optional include files used are:"
    LogMsg "-"
    LogMsg "-" ${OPTIONAL_INCLUDE_FILES}
    LogMsg "-" 
  fi

  TASK_MASK="$*"

  if [ "${TASK_MASK}"x = ""x ] ; then
    LogMsg "-" "Tasks defined are:"
  else
    LogMsg "-" "Defined Task matching one of the regex \"${TASK_MASK}\" are:"
  fi
  LogMsg "-"
  
  if [ ${VERBOSE} = ${__TRUE} ] ; then
    if [ "${TYPESET_F_SUPPORTED}"x != "yes"x ] ; then
      LogWarning "The parameter -v is not supported for the parameter --list with the current ksh version"
    else
      for CUR_TASK in ${DEFINED_TASKS} ; do
        CUR_TASK_NAME="${CUR_TASK#task_*}"
        [ ${#CUR_TASK_NAME} -ge ${FIELD_SIZE} ] && FIELD_SIZE=${#CUR_TASK_NAME}
      done   
    fi
  fi
  (( FIELD_SIZE = FIELD_SIZE + 4))
  
  for CUR_TASK in ${DEFINED_TASKS} ; do
    [[ ${CUR_TASK} == task_dummy* ]] && continue
    [[ ${CUR_TASK} == task_template* ]] && continue
    
    if [ "${TASK_MASK}"x != ""x ] ; then
      for CUR_MASK in ${TASK_MASK} ; do

        [[ ${CUR_MASK} != *\** && ${CUR_MASK} != *\?* ]] && CUR_MASK="*${CUR_MASK}*"

        CUR_TASK_NAME="${CUR_TASK#task_*}"
        CUR_TASK_OK=${__TRUE}
        [[ ${CUR_TASK_NAME} == ${CUR_MASK} ]] && break
        CUR_TASK_OK=${__FALSE}
      done
      [ ${CUR_TASK_OK} = ${__FALSE} ] && continue
    fi

    (( NO_OF_TASKS_DEFINED = NO_OF_TASKS_DEFINED + 1 ))
    
    if [ ${VERBOSE} = ${__TRUE} -a "${TYPESET_F_SUPPORTED}"x = "yes"x ] ; then
      CUR_TASK_NAME="${CUR_TASK#task_*}"

      CUR_TASK_USAGE="$( typeset -f ${CUR_TASK} | grep "typeset TASK_USAGE=" | cut -f2- -d"=" | sed "s/\${__FUNCTION}/${CUR_TASK_NAME}/g" | tr -d '"' )"      
      eval CUR_TASK_USAGE="\"${CUR_TASK_USAGE}\""

      CUR_MESSAGE="$( printf "Task: %-${FIELD_SIZE}s Usage: %s" "${CUR_TASK_NAME}"  "${CUR_TASK_USAGE}" )"
      LogMsg "-" "${CUR_MESSAGE}"
    else
      LogMsg "-" "${CUR_TASK#task_*}"
    fi
  done
  LogMsg "-"
  LogMsg "-" "${NO_OF_TASKS_DEFINED} task(s) defined."
  LogMsg "-"
  return ${THISRC}
}


# ----------------------------------------------------------------------
# ListDefaultTasks
#
# function: list all tasks that would be executed if the parameter \"all\" is used
#
# usage: ListDefaultTasks
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function ListDefaultTasks {
  typeset __FUNCTION="ListDefaultTasks"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
   
  typeset CUR_TASK_LIST=""
  typeset CUR_TASK_LIST_NAME=""
  
  typeset IGNORE_TASK_LIST=""
  typeset DEFAULT_TASK_LIST=""

  typeset NO_TASK_LIST_FOR_ALL_TEMP=""
  
  typeset NO_IGNORE_TASK_LIST=0
  typeset NO_DEFAULT_TASK_LIST=0
  
  LogMsg "-"
  LogMsg "-" "Include files used are:"
  LogMsg "-"
  LogMsg "-" ${INCLUDE_FILES}
  LogMsg "-"
  if [ "${OPTIONAL_INCLUDE_FILES}"x != ""x ] ; then
    LogMsg "Optional include files used are:"
    LogMsg "-"
    LogMsg "-" ${OPTIONAL_INCLUDE_FILES}
    LogMsg "-" 
  fi
  
  LogMsg "-"
  LogMsg "-" "Tasks defined are"
  LogMsg "-"  
  
  NO_TASK_LIST_FOR_ALL_TEMP="$( echo "${NO_TASK_LIST_FOR_ALL}" | tr "\n" " " )"
  
  if [ "${TASK_LIST_FOR_ALL}"x != ""x ] ; then
    CUR_TASK_LIST="${TASK_LIST_FOR_ALL}"
  else
    CUR_TASK_LIST="${DEFINED_TASKS}"
  fi
  
  for CUR_TASK in ${CUR_TASK_LIST} ; do
    [[ ${CUR_TASK} == task_dummy* ]] && continue
    [[ ${CUR_TASK} == task_template* ]] && continue
    CUR_TASK_LIST_NAME="${CUR_TASK#task_*}"
    
    if [[ " ${NO_TASK_LIST_FOR_ALL_TEMP} " == *\ ${CUR_TASK_LIST_NAME}\ * || " ${NO_TASK_LIST_FOR_ALL_TEMP} " == *\ ${CUR_TASK}\ *  ]] ; then
      IGNORE_TASK_LIST="${IGNORE_TASK_LIST}
${CUR_TASK_LIST_NAME}"
      (( NO_IGNORE_TASK_LIST = NO_IGNORE_TASK_LIST + 1 ))
    else
      DEFAULT_TASK_LIST="${DEFAULT_TASK_LIST}
${CUR_TASK_LIST_NAME}"
      (( NO_DEFAULT_TASK_LIST = NO_DEFAULT_TASK_LIST + 1 ))
    fi
    
    (( NO_OF_TASKS_DEFINED = NO_OF_TASKS_DEFINED + 1 ))
    
  done

  LogMsg "-"
  LogMsg "-" "${NO_DEFAULT_TASK_LIST} default task(s) defined:"
  LogMsg "-" "${DEFAULT_TASK_LIST}"

  LogMsg "-"
  LogMsg "-" "${NO_IGNORE_TASK_LIST} task(s) will be ignored if the parameter \"all\" is used:"
  LogMsg "-" "${IGNORE_TASK_LIST}"
  LogMsg "-"

  return ${THISRC}
}

# ----------------------------------------------------------------------
# ListTasksToExecute
#
# function: list all remaining tasks in the task queue 
#
# usage: ListTasksToExecute [index]
#
# index = Start Index for the list ; def.: 1
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function ListTasksToExecute {
  typeset __FUNCTION="ListTasksToExecute"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  
  typeset i=${1:-1}
  typeset j=0
  
  typeset CUR_TASK=""
  typeset TASK_PARAMETER=""
  typeset TASK_NAME=""
 
  j="${#TASKS_TO_EXECUTE[0]}"
#  (( j = j + 1 ))
  
  while [ $i -gt 0 -a $i -le ${TASKS_TO_EXECUTE[0]} ] ; do 
    CUR_TASK="${TASKS_TO_EXECUTE[$i]}"
    TASK_PARAMETER="${CUR_TASK#*:}"
    TASK_NAME="${CUR_TASK%%:*}"
    [ "${TASK_NAME}"x = "${TASK_PARAMETER}"x ] && TASK_PARAMETER=""
    TASK_NAME="${TASK_NAME#task_*}"
    
    LogMsg "-" "$( printf "Task %${j}s: %s %s " $i ${TASK_NAME} ${TASK_PARAMETER} )"
    
#    LogMsg "-"  "Task $i: ${TASK_NAME} ${TASK_PARAMETER}"

    (( i = i + 1 ))   
  done
  
  return ${THISRC}
}

# ----------------------------------------------------------------------
# task_dummy_ok
#
# function: this is a dummy task that always returns 0
#
# usage: dummy_ok_task [any parameter]
#
# returns: ${__TRUE} - ok executing the task
#          ${__FALSE} - error executing the task
#
function task_dummy_ok {                  
  typeset __FUNCTION="task_dummy_ok"
  typeset TASK_USAGE="${__FUNCTION} [any parameter]"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  
  
  LogMsg "This is task \"${__FUNCTION}\"  "

  LogMsg "The parameter for the task are:"
  LogMsg "-" "$*"

  return ${THISRC}
}


# ----------------------------------------------------------------------
# task_dummy_error
#
# function: this is a dummy task that always returns 1
#
# usage: dummy_error_task [any parameter]
#
# returns: ${__TRUE} - ok executing the task
#          ${__FALSE} - error executing the task
#
function task_dummy_error {                  
  typeset __FUNCTION="task_dummy_error"
  typeset TASK_USAGE="${__FUNCTION} [any parameter]"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__FALSE}

  LogMsg "This is task \"${__FUNCTION}\" "
  
  LogMsg "The parameter for the task are:"
  LogMsg "-" "$*"

  return ${THISRC}
}

# ----------------------------------------------------------------------
# execute_finish_tasks
#
# function: execute the function finish_tasks if defined
#
# usage: execute_finish_tasks
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function execute_finish_tasks {
  typeset __FUNCTION="execute_finish_tasks"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}

# ----------------------------------------------------------------------
# execute the function finish_tasks at script end if it's defined 
#
  if [ "${SOURCE_FILE_FOR_FINISH_TASKS}"x != ""x ] ; then
    if [ ${VERBOSE} = ${__TRUE} -o ${ONLY_LIST_TASKS_TO_EXECUTE} = ${__TRUE} ] ; then
      LogMsg "The function \"finish_tasks\" to use is the one from the include file \"${SOURCE_FILE_FOR_FINISH_TASKS}\" "
    fi
  fi

  if typeset +f finish_tasks >/dev/null ; then
    if [ ${ONLY_LIST_TASKS_TO_EXECUTE} = ${__FALSE} ] ; then
      if [ ${DO_NOT_EXECUTE_FINISH_TASKS} = ${__TRUE} ] ; then
        LogInfo "\"finish_tasks\" is defined but the execution is disabled via parameter."
      else
        LogMsg "\"finish_tasks\" is defined - now executing it ..."
   
        LogMsg "-" "${TASK_SEPARATOR_LINE}"
        ${PREFIX} finish_tasks
        LogMsg "-" "${TASK_SEPARATOR_LINE}"
      fi 
    fi
  else
    LogMsg "No function \"finish_tasks\" defined in the include files"
  fi

  return ${THISRC}
}


# ----------------------------------------------------------------------
# get_fqn
#
# function: get the FQN of a file
#
# usage: get_fqn filename [...[filename#]]
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
# The function writes the FQN or the filename to STDOUT
#
function get_fqn {
  typeset __FUNCTION="get_fqn"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}
  typeset CUR_OUTPUT=""
  
  if [ "${READLINK}"x = ""x ] ; then
    CUR_OUTPUT="$*"
  else
    while [ $# -ne 0 ] ; do
      CUR_OUTPUT="${CUR_OUTPUT} $( readlink -f $1 )"
      shift 
    done
  fi
  \echo "${CUR_OUTPUT}"      

  return ${THISRC}
}


# ----------------------------------------------------------------------
# read_file_section
#
# function: read the lines of a file between start_regex and end_regex
#
# usage: read_file_section [filename] [start_regex] [end_regex] 
#
# returns: 0  OK, section found and printed to STDOUT 
#          1  OK, section not found in the file
#          2  file not found
#          3  error in one of the regex
#          4  invalid usage
#
# The function searches for sections starting with 
#
# start_regex
#  ...
# end_regex
# 
# The lines matching start_regex and end_regex are part of the 
#
# The output of the sed command used is in the global variable FILE_SECTION_CONTENTS (including
# the lines matching start_regex and end_regex).
# The remaining lines from the file will be in the global variable REMAINING_FILE_CONTENTS
#
# Example usage:
#   read_file_section "${DHCPD_CONFIG_FILE}" "^[ \t]*host[ \t]*${THIS_HOSTID}[ \t]*$" "^[ \t]*}[ \t]*$*"
#   read_file_section "${PXE_DEFAULT_CONFIG_FILE}" "^[ \t]*label[ \t]*${LABEL_FOR_PXE_DEFAULT_BOOT_MENU}[ \t]*$" "^[ \t]*append[ \t]*.*$"
#   read_file_section "${CUR_OUTPUT_FILE}" "^[ \t]*label install[ \t]*$" "^[ \t]*append[ \t]"
#
function read_file_section {
  typeset __FUNCTION="read_file_section"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=4
 
  typeset CUR_FILE="$1"
  typeset START_REGEX="$2"
  typeset END_REGEX="$3"

# init the global variables used
#  
  FILE_SECTION_CONTENTS=""
  REMAINING_FILE_CONTENTS=""
  
  if [ $# -eq 3 ] ; then
    if [ -r "${CUR_FILE}" ] ; then

#    sed -n "/^[ \t]*host schemmer-04/,/^[ \t]*}/p" /var/tmp/dhcpd.conf  ; echo $?
#      FILE_SECTION_CONTENTS="$( sed -n "/^[ \t]*${START_REGEX}/,/^[ \t]*${END_REGEX}[ \t]$/p" "${CUR_FILE}" 2>&1 )"

      FILE_SECTION_CONTENTS="$( sed -n "/${START_REGEX}/,/${END_REGEX}/p" "${CUR_FILE}" 2>&1 )"
      if [ $? -eq 0 ] ; then
        REMAINING_FILE_CONTENTS="$( sed -n "/${START_REGEX}/,/${END_REGEX}/!p" "${CUR_FILE}" 2>&1 )"
        if [ "${FILE_SECTION_CONTENTS}"x != ""x ] ; then
          THISRC=0
        else
          THISRC=1       
        fi
      else
        THISRC=3
      fi
    else
      THISRC=2
    fi
  else
    THISRC=4
  fi
  
  return ${THISRC}
}

# ----------------------------------------------------------------------
# function_template
#
# function: 
#
# usage: 
#
# returns: ${__TRUE} - 
#          ${__FALSE} - 
#
function function_template {
  typeset __FUNCTION="function_template"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}

# add your code her

  return ${THISRC}
}



# ----------------------------------------------------------------------
# template function used for the parameter --print_task_template
#

TASK_FUNCTION_TEMPLATE='

# ----------------------------------------------------------------------
# task_template
#
# function: [add the task description here]
#
# usage: [add the usage help for the task here]
#
# returns: ${__TRUE} - ok executing the task
#          ${__FALSE} - error executing the task
#
#
# Change the function name "task_template" to the proper task name
#
# Notes: 
#
# - the name of the function must start with task_
# - the local variable __FUNCTION must contain the function name
# - the local variable ${TASK_USAGE} should contain the usage help for the task
# - all variables used should be local variables; use "typeset variablename" to define local variables
# - use LogMsg to print messages
# - use LogError to print error messages
# - use LogWarning to print warning messages
# - use LogInfo to print messages that should only be printed if the parameter -v is used
# - use "AskUser [message]" to get input from the user; AskUser returns ${__TRUE} if "y" is entered else "n"
#   The user input is available in the variabe ${USER_INPUT}
# - use "die [returncode] [message]" to end the script if neccessary
#
function task_template {                  
  typeset __FUNCTION="task_template"
  typeset TASK_USAGE="${__FUNCTION} [add the usage help for the parameter for the task if any here]"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}

  typeset CUR_OUTPUT=""
  typeset TEMPRC=""

# add your code her
    
  return ${THISRC}
}
'

# ----------------------------------------------------------------------
# template for an include file
#

INCLUDE_FILE_TEMPLATE='#!/bin/bash
#
# This is an include file for ${0##*/}.sh
#

# code to disable the execution of this file
#
if [[ $0 == *.include ]] ; then
  CUR_FILENAME="${0##*/}"
  echo "ERROR: $0 is an include file for ${CUR_FILENAME%.*}.sh"
  exit 5
fi

# define the include file version (optional)
#
INCLUDE_FILE_VERSION="1.0.0.0"

# disable the parameter "all"
# (optional; default: the parameter "all" is enabled)
#
# DISABLE_THE_PARAMETER_ALL=${__TRUE}

# define the tasks to be executed for the parameter "all" 
# (optional, default: execute all defined tasks if "all" is used)
# 
# DEFAULT_TASKS=""

# define the tasks that should never be executed for the parameter "all" 
# (optional, if a task is defined in DEFAULT_TASKS and NO_DEFEAULT_TASKS
#  it will not executed if the parameter "all" is used)
# 
# NO_DEFAULT_TASKS=""

# if read by the wrapper script the variable with the filename of this 
# script is ${CUR_INCLUDE_FILE}"
#

# define the function init_tasks (optional)
#
function init_tasks {
  typeset __FUNCTION="init_tasks"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}

  LogMsg "This is the function \"${__FUNCTION}\"  "

# parameter for the function init_tasks
#
  if [ "${PARAMETER_FOR_INIT_TASKS}"x != ""x ] ; then
    LogInfo "The parameter for the function ${__FUNCTION} are: \"${PARAMETER_FOR_INIT_TASKS}\" "
  else
    LogInfo "No parameter for the function ${__FUNCTION} defined "
  fi

  return ${THISRC}
}

# define the function finish_tasks (optional)
#
function finish_tasks {
  typeset __FUNCTION="finish_tasks"
  ${__DEBUG_CODE}
  ${__FUNCTION_INIT}

  typeset THISRC=${__TRUE}

  LogMsg "This is the function \"${__FUNCTION}\"  "

  return ${THISRC}
}
'

# ----------------------------------------------------------------------
# main code starts here
#


# ----------------------------------------------------------------------
#
# redirect STDOUT and STDERR of the script and all commands executed by
# the script to a file if called in an background session
#
if [ ${RUNNING_IN_TERMINAL_SESSION} = ${__FALSE} -a  ${LOG_STDOUT} = ${__TRUE} ] ; then
  if [[ " $* " = *\ --noSTDOUTlog\ * ]] ; then
    :
  elif [[ " $* " != *\ -q\ * && " $* " != *\ --quiet\ * ]] ; then
    STDOUT_FILE="/var/tmp/${SCRIPTNAME}.STDOUT_STDERR"
    touch "${STDOUT_FILE}" 2>/dev/null
    if [ $? -ne 0 ] ; then
      STDOUT_FILE="/var/tmp/${SCRIPTNAME}.STDOUT_STDERR.$$"
    else
      [ ! -s "${STDOUT_FILE}" ] && rm "${STDOUT_FILE}"
    fi
    
    RotateLog "${STDOUT_FILE}"
  
    echo "${SCRIPTNAME} -- Running in a detached session ... STDOUT/STDERR will be in ${STDOUT_FILE}" >&2
 
    exec 3>&1
    exec 4>&2
    exec 1>>"${STDOUT_FILE}"  2>&1
  fi
fi

# ----------------------------------------------------------------------

STARTTIME_IN_SECONDS="$( date +%s )"
STARTTIME_IN_HUMAN_READABLE_FORMAT="$( date "+%d.%m.%Y %H:%M:%S" )"

LogMsg "### ${SCRIPTNAME} started at ${STARTTIME_IN_HUMAN_READABLE_FORMAT} (The PID of this process is $$)"

# install the trap handler
#
__settraps


# get the parameter
#
ALL_PARAMETER="$*"


DISABLE_THE_PARAMETER_ALL=""
REAL_DISABLE_THE_PARAMETER_ALL=""

INCLUDE_FILES_WITH_DISABLED_PARAMETER_ALL=""

TASK_LIST_FOR_ALL=""
NO_TASK_LIST_FOR_ALL=""

PARAMETER_OKAY=${__TRUE}

SHOW_SCRIPT_USAGE=${__FALSE}

FUNCTIONS_TO_TRACE=""

PRINT_VERSION_AND_EXIT=${__FALSE}

LOGFILE_PARAMETER_FOUND=${__FALSE}

SINGLE_STEP_MODE=${__FALSE}

CHECK_TASKS=${__FALSE}

CHECK_ONLY=${__FALSE}

EXECUTE_TASKS_ONLY_ONCE=${__FALSE}

ABORT_TASK_EXECUTION_ON_ERROR=${__FALSE}

ABORT_TASK_EXECUTION_ON_TASK_NOT_FOUND=${__FALSE}

ABORT_TASK_EXECUTION_ON_DUPLICATE_TASK_DEFINITIONS=${__FALSE}

NO_WARNINGS_ABOUT_DUPLICATE_TASK_DEFINITIONS=${__FALSE}

CREATE_INCLUDE_FILE_TEMPLATE=${__FALSE}

PRINT_TASK_TEMPLATE=${__FALSE}

LIST_DEFINED_TASK=${__FALSE}

LIST_DEFINED_TASK_GROUPS=${__FALSE}

LIST_DEFAULT_TASK=${__FALSE}

TRACE_TASKS=${__FALSE}

VERBOSE_FOR_TASKS=${__FALSE}

DO_NOT_EXECUTE_INIT_TASKS=${__FALSE}

DO_NOT_EXECUTE_FINISH_TASKS=${__FALSE}

USE_DEFAULT_INCLUDE_FILE=${__TRUE}

DEFAULT_INCLUDE_FILE_NAME="${SCRIPTNAME%.*}.include"

DEFAULT_INCLUDE_FILE_NAME_TEMPLATE="${DEFAULT_INCLUDE_FILE_NAME}.template"

INCLUDE_FILES=""
OPTIONAL_INCLUDE_FILES=""

SHOW_INCLUDE_FILE_USAGE=${__FALSE}

ONLY_LIST_TASKS_TO_EXECUTE=${__FALSE}

DISABLED_TASKS_FOUND_IN_THE_PARAMETER=""

# the alias __getparameter is used for parameter that support values
# these parameter can be used like this "-l logfile" or this "-l:logfile"
#
alias __getparameter='
       CUR_VALUE="${1#*:}"
       if [ "${CUR_VALUE}"x = "$1"x ] ; then
         CUR_VALUE=""
         if [ "$2"x != ""x ] ; then
           if [[ $2 != -* ]] ; then
             CUR_VALUE="$2"
             shift
           fi
         fi  
       fi'


LogMsg "### Processing the parameter ..."

while [ $# -ne 0 ] ; do
  case $1 in

    --info )
      VERBOSE_FOR_TASKS=${__TRUE}
      ;;

    ++info )
      VERBOSE_FOR_TASKS=${__FALSE}
      ;;

    --trace )
      TRACE_TASKS=${__TRUE}
      ;;

    ++trace )
      TRACE_TASKS=${__FALSE}
      ;;

    --singlestep )
      SINGLE_STEP_MODE=${__TRUE}
      ;;

    ++singlestep )
      SINGLE_STEP_MODE=${__FALSE}
      ;;

    --check )
      CHECK_TASKS=${__TRUE}
      CHECK_ONLY=${__FALSE}
      ;;

    ++check )
      CHECK_TASKS=${__FALSE}
      CHECK_ONLY=${__FALSE}
      ;;

    --checkonly )
      CHECK_TASKS=${__TRUE}
      CHECK_ONLY=${__TRUE}
      ;;

    ++checkonly )
      CHECK_TASKS=${__FALSE}
      CHECK_ONLY=${__FALSE}
      ;;

    --abortontasknotfound | --abort_on_task_not_found )
      ABORT_TASK_EXECUTION_ON_TASK_NOT_FOUND=${__TRUE}
      ;;

    ++abortontasknotfound | ++abort_on_task_not_found )
      ABORT_TASK_EXECUTION_ON_TASK_NOT_FOUND=${__FALSE}
      ;;

    --abortonerror | --abort_on_error )
      ABORT_TASK_EXECUTION_ON_ERROR=${__TRUE}
      ;;

    ++abortonerror | abort_on_error)
      ABORT_TASK_EXECUTION_ON_ERROR=${__FALSE}
      ;;

    --abort_on_duplicates )
      ABORT_TASK_EXECUTION_ON_DUPLICATE_TASK_DEFINITIONS=${__TRUE}
      ;;

    ++abort_on_duplicates )
      ABORT_TASK_EXECUTION_ON_DUPLICATE_TASK_DEFINITIONS=${__FALSE}
      NO_WARNINGS_ABOUT_DUPLICATE_TASK_DEFINITIONS=${__TRUE}
      ;;
       
    --print_includefile_help )
      SHOW_INCLUDE_FILE_USAGE=${__TRUE}
      ;;

    ++print_includefile_help )
      SHOW_INCLUDE_FILE_USAGE=${__FALSE}
      ;;
      
#    --print_task_template )
#      PRINT_TASK_TEMPLATE=${__TRUE}
#      ;;

    --print_task_template | --print_task_template:* )
       __getparameter
      PRINT_TASK_TEMPLATE=${__TRUE}

      if [ "${CUR_VALUE}"x = ""x ] ; then
        LogInfo "Writing the task template to STDOUT"
        FILE_FOR_TASK_TEMPLATE=""
      else
        FILE_FOR_TASK_TEMPLATE="${CUR_VALUE}"
        LogInfo "Writing the task template to the file \"${FILE_FOR_TASK_TEMPLATE}\" "
      fi
      ;;


    ++print_task_template )
      PRINT_TASK_TEMPLATE=${__FALSE}
      ;;

    --list_default_tasks )
       LIST_DEFAULT_TASK=${__TRUE}
       ;;

    ++list_default_tasks )
       LIST_DEFAULT_TASK=${__FALSE}
       ;;

    --list )
       LIST_DEFINED_TASK=${__TRUE}
       LIST_DEFINED_TASK_GROUPS=${__TRUE}
       ;;

    ++list )
       LIST_DEFINED_TASK=${__FALSE}
       LIST_DEFINED_TASK_GROUPS=${__FALSE}
       ;;

    --list_tasks )
       LIST_DEFINED_TASK=${__TRUE}
       LIST_DEFINED_TASK_GROUPS=${__FALSE}
       ;;

    ++list_tasks )
       LIST_DEFINED_TASK=${__FALSE}
       LIST_DEFINED_TASK_GROUPS=${__FALSE}
       ;;

    --list_task_groups )
       LIST_DEFINED_TASK_GROUPS=${__TRUE}
       ;;

    ++list_task_groups )
       LIST_DEFINED_TASK_GROUPS=${__FALSE}
       ;;
           
    --unique )
       EXECUTE_TASKS_ONLY_ONCE=${__TRUE}
       ;;

    ++unique )
       EXECUTE_TASKS_ONLY_ONCE=${__FALSE}
       ;;

    --disabled_tasks |  --disabled_tasks:* )
       __getparameter
       if [ "${CUR_VALUE}"x = ""x ] ; then
         LogError "Missing value for --disabled_tasks"
         PARAMETER_OKAY=${__FALSE}
       else
         TEMPVAR="$( echo "${CUR_VALUE}" | tr "," " " )"
         if [ "${TEMPVAR}"x = "none"x ] ; then
           DISABLED_TASKS_FOUND_IN_THE_PARAMETER=""
         else
           DISABLED_TASKS_FOUND_IN_THE_PARAMETER="${DISABLED_TASKS_FOUND_IN_THE_PARAMETER} ${TEMPVAR}"
         fi
       fi
       ;;
       
    -i | --includefile | -i:* | --includefile:* )
       __getparameter
       if [ "${CUR_VALUE}"x = ""x ] ; then
         LogError "Missing value for -i"
         PARAMETER_OKAY=${__FALSE}
       else
         TEMPVAR="$( echo "${CUR_VALUE}" | tr "," " " )"
         for CUR_VAR in ${TEMPVAR} ; do
           case ${CUR_VAR} in
             none )
               USE_DEFAULT_INCLUDE_FILE=${__FALSE}

               if [ "${INCLUDE_FILES}"x != ""x ] ; then
                 LogInfo "Include files removed from the list are : \"${INCLUDE_FILES}\" "
               fi

               if [ "${OPTIONAL_INCLUDE_FILES}"x != ""x ] ; then
                 LogInfo "Optional include files removed from the list are : \"${OPTIONAL_INCLUDE_FILES}\" "
               fi

               INCLUDE_FILES=""
               OPTIONAL_INCLUDE_FILES=""
               ;;

             default )
               USE_DEFAULT_INCLUDE_FILE=${__TRUE}
               if [ "${OPTIONAL_INCLUDE_FILES}"x != ""x ] ; then
                 LogInfo "Optional include files removed are : \"${OPTIONAL_INCLUDE_FILES}\" "
               fi
               OPTIONAL_INCLUDE_FILES=""
               ;;

             \?* )             
               OPTIONAL_INCLUDE_FILES="${OPTIONAL_INCLUDE_FILES} ${CUR_VAR#\?*} "
               ;;

             * )
               USE_DEFAULT_INCLUDE_FILE=${__FALSE}
               INCLUDE_FILES="${INCLUDE_FILES} $( get_fqn "${CUR_VAR}" )"
               ;;
           esac
         done
       fi
       ;;

    --create_include_file_template | --create_include_file_template:* )
       __getparameter

       CREATE_INCLUDE_FILE_TEMPLATE=${__TRUE}
       if [ "${CUR_VALUE}"x = ""x ] ; then
         LogInfo "Creating the default include file template: \"${DEFAULT_INCLUDE_FILE_NAME_TEMPLATE}\" "
         NEW_INCLUDE_FILE="${DEFAULT_INCLUDE_FILE_NAME_TEMPLATE}"
       else
         NEW_INCLUDE_FILE="${CUR_VALUE}"
         LogInfo "Creating the include file template \"${NEW_FILE}\" "
       fi
       ;;

    ++create_include_file_template )
       CREATE_INCLUDE_FILE_TEMPLATE=${__FALSE}
       ;;

    --no_init_tasks )
      DO_NOT_EXECUTE_INIT_TASKS=${__TRUE}
      ;;


    ++no_init_tasks )
      DO_NOT_EXECUTE_INIT_TASKS=${__FALSE}
      ;;

    --no_finish_tasks )
      DO_NOT_EXECUTE_FINISH_TASKS=${__TRUE}
      ;;

    ++no_finish_tasks )
      DO_NOT_EXECUTE_FINISH_TASKS=${__FALSE}
      ;;

    --only_list_tasks )
      ONLY_LIST_TASKS_TO_EXECUTE=${__TRUE}
      ;;

    ++only_list_tasks )
      ONLY_LIST_TASKS_TO_EXECUTE=${__FALSE}
      ;;
      
    -h | "" )
       SHORT_HELP=${__TRUE}
       SHOW_SCRIPT_USAGE=${__TRUE}
       ;;

    --help | -H | help |  "" )
       SHORT_HELP=${__FALSE}
       SHOW_SCRIPT_USAGE=${__TRUE}
       ;;

    -V | --version )
       PRINT_VERSION_AND_EXIT=${__TRUE}
       ;;

    +V | ++version )
       PRINT_VERSION_AND_EXIT=${__FALSE}
       ;;

    -v | --verbose )
       (( VERBOSE_LEVEL = VERBOSE_LEVEL+1 ))
       SHORT_HELP=${__FALSE}
       VERBOSE=${__TRUE}
       ;;

    +v | ++verbose )
       VERBOSE=${__FALSE}
       [ ${VERBOSE_LEVEL} -gt 0 ] && (( VERBOSE_LEVEL = VERBOSE_LEVEL-1 )) || VERBOSE_LEVEL=0
       ;;

    -q | --quiet )
       QUIET=${__TRUE}
       ;;

    +q | ++quiet )
       QUIET=${__FALSE}
       ;;

    -f | --force )
       FORCE=${__TRUE}
       ;;

    +f | ++force )
       FORCE=${__FALSE}
       ;;

    -o | --overwrite )
       OVERWRITE=${__TRUE}
       ;;

    +o | ++overwrite )
       OVERWRITE=${__FALSE}
       ;;


    -D | --debugshell )
       if [ ${ENABLE_DEBUG}x != ${__TRUE}x ] ; then
         LogError "DebugShell is disabled."
         PARAMETER_OKAY=${__FALSE}
       else
         DebugShell 
       fi
       ;;

    -d | --dryrun )
       if [ ${DRYRUN_MODE_DISABLED} = ${__TRUE} ] ; then
         LogError "Dryrun Mode is NOT supported"
         PARAMETER_OKAY=${__FALSE}
       else
         PREFIX="${PREFIX:=${DEFAULT_DRYRUN_PREFIX}}"
       fi
       ;;

    +d | ++dryrun )
       if [ ${DRYRUN_MODE_DISABLED} = ${__TRUE} ] ; then
         LogError "Dryrun Mode is NOT supported"
         PARAMETER_OKAY=${__FALSE}
       else
         if [ "${PREFIX}"x != ""x ] ; then
           LogMsg "Disabling the dryrun mode (the dryrun prefix was \"${PREFIX}\")"
         fi
         PREFIX=""
       fi
       ;;

    -d:* | --dryrun:** )
       if [ ${DRYRUN_MODE_DISABLED} = ${__TRUE} ] ; then
         LogError "Dryrun Mode is NOT supported"
         PARAMETER_OKAY=${__FALSE}
       else
         PREFIX="${1#*:}"
         LogMsg "The dryrun prefix used is: \"${PREFIX}\" "
       fi
       ;;

    +y | ++yes | +n | ++no )
       __USER_RESPONSE_IS=""
       ;;
   
    -y | --yes )
       __USER_RESPONSE_IS="y"
       ;;
       
    -n | --no )
       __USER_RESPONSE_IS="n"
       ;;

    --nologrotate )
       ROTATE_LOG=${__FALSE}
       ;;

    ++nologrotate )
       ROTATE_LOG=${__TRUE}
       ;;

    --appendlog )
       APPEND_LOG=${__TRUE}
       ROTATE_LOG=${__FALSE}
       ;;
        
    ++appendlog )
       APPEND_LOG=${__FALSE}
       ROTATE_LOG=${__TRUE}
       ;;

    --noSTDOUTlog )
       LOG_STDOUT=${__FALSE}
       ;;

    ++noSTDOUTlog )
       LOG_STDOUT=${__TRUE}
       ;;
    
    --nocleanup )
      NO_CLEANUP=${__TRUE}
      ;;

    ++nocleanup )
      NO_CLEANUP=${__FALSE}
      ;;

    --nobackups)
      NO_BACKUPS=${__TRUE}
      ;;

    ++nobackups )
      NO_BACKUPS=${__FALSE}
      ;;

    --var | --var:* )
      __getparameter
      
      if [ "${CUR_VALUE}"x = ""x ] ; then
         LogError "Missing value for --var"
         PARAMETER_OKAY=${__FALSE}
       else
         if [ ${ENABLE_DEBUG}x != ${__TRUE}x ] ; then
           LogError "--var is disabled."
           PARAMETER_OKAY=${__FALSE}
         else
           VAR_NAME="${CUR_VALUE%%=*}"
           VAR_VALUE="${CUR_VALUE#*=}"
           LogMsg "Found --VAR parameter for ${VAR_NAME}=\"${VAR_VALUE}\" "
         
           eval CUR_VALUE="\$${VAR_NAME}"
           LogMsg "Current value of ${VAR_NAME} is: \"${CUR_VALUE}\" "
         
           eval ${VAR_NAME}=\"${VAR_VALUE}\" 

           eval NEW_VALUE="\$${VAR_NAME}"
           LogMsg "New value of ${VAR_NAME} is now: \"${NEW_VALUE}\" "
         fi
       fi
       ;;
         
    -t | --tracefunc | -t:* | --tracefunc:* )
       __getparameter    
       
       if [ "${CUR_VALUE}"x = ""x ] ; then
         LogError "Missing value for -t"
         PARAMETER_OKAY=${__FALSE}
       elif [ "${CUR_VALUE}"x = "none"x ] ; then
         LogInfo "Disabling tracing for all functions"
         FUNCTIONS_TO_TRACE=""
       else
         FUNCTIONS_TO_TRACE="${FUNCTIONS_TO_TRACE} $( echo "${CUR_VALUE}" | tr "," " " )"
       fi
       ;;

    -L | --listfunctions ) 
       LIST_FUNCTIONS_AND_EXIT=${__TRUE}
       ;;

    +L | ++listfunctions ) 
       LIST_FUNCTIONS_AND_EXIT=${__FALSE}
       ;;

    -l | --logfile | -l:* | --logfile:* )
       LOGFILE_PARAMETER_FOUND=${__TRUE}
       __getparameter

       if [ "${CUR_VALUE}"x = ""x ] ; then
         LogInfo "Running without a logfile (no value for the parameter -l found)"
         LOGFILE=""
       elif [[ ${CUR_VALUE} = -* ]] ; then
         LogInfo "Running without a logfile (no value for the parameter -l found)"
         LOGFILE=""
       elif [ "${CUR_VALUE}"x = "none"x ] ; then
         LogInfo "Running without a logfile"
         LOGFILE=""
       else
         LOGFILE="${CUR_VALUE}"
         LogRuntimeInfo "Using the logfile ${LOGFILE}"
       fi
       ;;

    -T | --tee )
       # parameter is already processed - ignore it
       :
       ;;


    --disable_tty_check )
       DISABLE_TTY_CHECK=${__TRUE}
       ;;

    ++disable_tty_check )
       LogWarning "The parameter \"++disable_tty_check\" is not supported and will be ignored"   
#       DISABLE_TTY_CHECK=${__FALSE}
       ;;

    -- )
        shift
        break
        ;;

# check for unknown switches
#
    -* )
       LogError "Unknown parameter found: $1"
       PARAMETER_OKAY=${__FALSE}
       ;;


    * ) 
       break
#       LogError "Unknown parameter found: $1"
#       PARAMETER_OKAY=${__FALSE}
       ;;
     
  esac
  shift
done

NOT_USED_PARAMETER="$*"
[ $# -ne 0 ] && LogMsg "Not yet used parameter are: \"$*\" "

if [[ ${NOT_USED_PARAMETER} == *--* ]]  ; then
  PARAMETER_FOR_INIT_TASKS="${NOT_USED_PARAMETER#*--}"

  NOT_USED_PARAMETER="${NOT_USED_PARAMETER%%--*}"
else
  PARAMETER_FOR_INIT_TASKS=""  
fi

LogMsg "Tasks to execute are: \"${NOT_USED_PARAMETER}\" "
LogMsg "Parameter for the function init_tasks are: \"${PARAMETER_FOR_INIT_TASKS}\" "

if [ ${TRACE_TASKS} = ${__TRUE} ] ; then
  for CUR_TASK in ${NOT_USED_PARAMETER} ; do
    if [[ ${CUR_TASK} == task_* ]] ; then
      FUNCTIONS_TO_TRACE="${FUNCTIONS_TO_TRACE} ${CUR_TASK%%:*}"
    else    
      FUNCTIONS_TO_TRACE="${FUNCTIONS_TO_TRACE} task_${CUR_TASK%%:*}"
    fi
  done
fi

if [ ${PARAMETER_OKAY} != ${__TRUE} ] ; then
  die 2
fi

if [ ${LIST_FUNCTIONS_AND_EXIT} = ${__TRUE} ] ; then
  LogMsg "Defined functions are :"
  LogMsg "-" "$( typeset +f )"
  die 0
fi

if [ ${SHOW_SCRIPT_USAGE} = ${__TRUE} ] ; then
  show_script_usage    
  die 0
fi

if [ ${PRINT_VERSION_AND_EXIT} = ${__TRUE}   ] ; then
  LOGFILE=""
  echo "${SCRIPT_VERSION}"
  [ ${VERBOSE} = ${__TRUE} ] && echo "The Script template version is ${TEMPLATE_VERSION}"
  die 0
fi

if [ "${PREFIX}"x != ""x ] ; then
  LogMsg "-"
  LogMsg "*** Running in dry-run mode -- no changes will be done. The dryrun prefix used is \"${PREFIX}\" "
  LogMsg "-"
fi

# the logfile to use is now fix so activate the logging to the logfile
#
__activate_logfile

# enable trace (set -x) for all requested functions
#
if [ "${FUNCTIONS_TO_TRACE}"x != ""x ] ; then
  __enable_trace_for_functions  "${FUNCTIONS_TO_TRACE}"
fi

# ----------------------------------------------------------------------
# main:

# ----------------------------------------------------------------------
# check if this script is executed by the root user
#
# [ "${CUR_USER_ID}"x != "0"x ] && die 202 "This script must be executed by root only"


# ----------------------------------------------------------------------
# to add variables to the print variable function for DebugShell use
#
# APPLICATION_VARIABLES="${APPLICATION_VARIABLES} "
#
# to define files, directories, or processes to remove at script end 
# or functions to execute at script end use
#
# finish routines that should be executed before the house keeping tasks are done
#   Use "function_name:parameter1[[...]:parameter#] to add parameter for a function
#   blanks or tabs in the parameter are NOT allowed
#
# CLEANUP_FUNCTIONS="${CLEANUP_FUNCTIONS} "
#
# processes that should be killed at script end
#   to change the timeout after kill before issuing a kill -9 for 
#   a process use  pid:timeout
#
# PROCS_TO_KILL="${PROCS_TO_KILL} "
#
# files that should be deleted at script end
#
# FILES_TO_REMOVE="${FILES_TO_REMOVE} "
#
# directories that should be removed at script end
#
# DIRS_TO_REMOVE="${DIRS_TO_REMOVE} "
#
# mount points to umount at script end
#
# MOUNTS_TO_UMOUNT="${MOUNTS_TO_UMOUNT} "
#
# finish routines to executed after all house keeping tasks are done
#   Use "function_name:parameter1[[...]:parameter#] to add parameter for a function
#   blanks or tabs in the parameter are NOT allowed
#
# FINISH_FUNCTIONS="${FINISH_FUNCTIONS} "
#

# ----------------------------------------------------------------------
# init the script return code
#
THISRC=${__TRUE}


if [ ${DISABLE_TTY_CHECK} != ${__TRUE} ] ; then
  if [ ${RUNNING_IN_TERMINAL_SESSION} = ${__TRUE} ] ; then
    LogRuntimeInfo "The script is running in a terminal session"
  else
    LogRuntimeInfo "The script is running in a session without terminal"
  fi
else
  LogRuntimeInfo "The tty check is disabled -- the script assumes to run in a terminal session"
fi

LogRuntimeInfo "The name of the shell used is \"${__SHELL}\" "
LogRuntimeInfo "The ksh version of the running shell is ${__KSH_VERSION}"
LogRuntimeInfo "The current hostname is \"${CUR_HOST}\" "
LogRuntimeInfo "The current short hostname is \"${CUR_SHORT_HOST}\" "
LogRuntimeInfo "The current os is \"${CUR_OS}\", the current OS version is \"${CUR_OS_VERSION}\" "
LogRuntimeInfo "The user id executing this script is \"${CUR_USER_NAME}\" (UID is \"${CUR_USER_ID}\") "
LogRuntimeInfo "The group id executing this script is \"${CUR_GROUP_NAME}\" (GID is \"${CUR_GROUP_ID}\") "

LogRuntimeInfo "The real script name is \"${REAL_SCRIPTNAME}\" "
LogRuntimeInfo "The real script directory is \"${REAL_SCRIPTDIR}\" "
LogRuntimeInfo "The working directory is \"${WORKING_DIR}\" "
LogRuntimeInfo "The editor to use is \"${EDITOR}\" "
LogRuntimeInfo "The pager to use is \"${PAGER}\" "

if [ ${RUNNING_ON_A_VIRTUAL_MACHINE} = ${__TRUE} ] ; then
  LogRuntimeInfo "The script is running in a virtual machine"
  LogRuntimeInfo "The hypervisor used is \"${SYSTEM_PRODUCT_NAME}\" "
  LogRuntimeInfo "The vendor of the hypervisor used is \"${HPYERVISOR_VENDOR}\" "
else
  LogRuntimeInfo "The script is running on a physical machine"
fi

LogRuntimeInfo "RUNNING_IN_A_CONSOLE_SESSION is  \"${RUNNING_IN_A_CONSOLE_SESSION}\" "

LogRuntimeInfo "STDOUT_IS_A_PIPE is ${STDOUT_IS_A_PIPE} "
LogRuntimeInfo "STDIN_IS_A_PIPE is ${STDIN_IS_A_PIPE} "
LogRuntimeInfo "STDIN_IS_TTY is  \"${STDIN_IS_TTY}\" "
LogRuntimeInfo "STDOUT_IS_TTY is  \"${STDOUT_IS_TTY}\" "
LogRuntimeInfo "STDERR_IS_TTY is  \"${STDERR_IS_TTY}\" "

LogRuntimeInfo "STDIN is  \"${STDIN_DEVICE}\" "
LogRuntimeInfo "STDOUT is \"${STDOUT_DEVICE}\" "
LogRuntimeInfo "STDERR is \"${STDERR_DEVICE}\" "


# ----------------------------------------------------------------------
# check for the parameter --print_task_template
#
if [ ${PRINT_TASK_TEMPLATE} = ${__TRUE} ] ; then
  if [ "${FILE_FOR_TASK_TEMPLATE}"x = ""x ] ; then
    LogMsg "The task template is :"
    LogMsg "-" "${TASK_FUNCTION_TEMPLATE}"
  else
    BackupFile "${FILE_FOR_TASK_TEMPLATE}" "${FILE_FOR_TASK_TEMPLATE}.old"
    if [ $? -eq 0 ] ; then
      LogMsg "Writing the task template to the file \"${FILE_FOR_TASK_TEMPLATE}\" ..."
      echo "${TASK_FUNCTION_TEMPLATE}" >"${FILE_FOR_TASK_TEMPLATE}"
      if [ $? -ne 0 ] ; then
        die 40 "Error writing the task template to the file \"${FILE_FOR_TASK_TEMPLATE}\" "
      fi
    fi
  fi
  die 0
fi

# ----------------------------------------------------------------------

if [ ${CREATE_INCLUDE_FILE_TEMPLATE} = ${__TRUE} ] ; then
  BackupFile "${NEW_INCLUDE_FILE}" "${NEW_INCLUDE_FILE}.old"
  if [ $? -eq 0 ] ; then
    LogMsg "Creating the new include file template \"${NEW_INCLUDE_FILE}\" ..."

    echo "${INCLUDE_FILE_TEMPLATE}"> "${NEW_INCLUDE_FILE}" 
    if [ $? -ne 0 ] ; then
      die 13  "Error creating the file \"${NEW_INCLUDE_FILE}\" "
    fi
  fi
  
  die 0
fi

# ----------------------------------------------------------------------
# search the default include file
#
DEFAULT_INCLUDE_FILE=""

LogInfo "Searching the default include file \"${DEFAULT_INCLUDE_FILE_NAME}\" ..."
if [ -r "${PWD}/${DEFAULT_INCLUDE_FILE_NAME}" ] ; then
  DEFAULT_INCLUDE_FILE="${PWD}/${DEFAULT_INCLUDE_FILE_NAME}"
  LogInfo " ... \"${DEFAULT_INCLUDE_FILE}\" found."
elif [ -r "${REAL_SCRIPTDIR}/${DEFAULT_INCLUDE_FILE_NAME}" ] ; then
  DEFAULT_INCLUDE_FILE="${REAL_SCRIPTDIR}/${DEFAULT_INCLUDE_FILE_NAME}"
  LogInfo "\"${DEFAULT_INCLUDE_FILE}\" found."
else
  LogMsg "No default include file found (the filename for the default include file is: ${DEFAULT_INCLUDE_FILE_NAME})"
fi

if  [ ${USE_DEFAULT_INCLUDE_FILE} = ${__TRUE} ] ; then
  if [ "${DEFAULT_INCLUDE_FILE}"x != ""x  ] ; then
    INCLUDE_FILES="${DEFAULT_INCLUDE_FILE} ${INCLUDE_FILES}"
  else
    die 9 "Default include file not found"
  fi
fi

if [ "${OPTIONAL_INCLUDE_FILES}"x != ""x ] ; then
  LogMsg "Searching the optional include files ..."
  for CUR_INCLUDE_FILE in ${OPTIONAL_INCLUDE_FILES} ; do
    if [ -r "${CUR_INCLUDE_FILE}" ] ; then
      LogMsg "The optional include file \"${CUR_INCLUDE_FILE}\" exists"
      INCLUDE_FILES="${INCLUDE_FILES} $( get_fqn "${CUR_INCLUDE_FILE}" )"
    else
      LogMsg "The optional include file \"${CUR_INCLUDE_FILE}\" does not exist"
    fi
  done
fi

if [ "${INCLUDE_FILES}"x = ""x ] ; then
  die 10 "No include files defined (default include file is \"${DEFAULT_INCLUDE_FILE_NAME}\") "
fi
  
# ----------------------------------------------------------------------
# only print the usage for each include file if requested
#
if [ ${SHOW_INCLUDE_FILE_USAGE} = ${__TRUE} ] ; then
  LogMsg "Print the help text for each include file requested via parameter"

  ERRORS_FOUND=${__FALSE}
  INCLUDE_FILES_FOUND=""
  INCLUDE_FILES_NOT_FOUND=""

  NO_OF_INCLUDE_FILES_FOUND=0
  NO_OF_INCLUDE_FILES_NOT_FOUND=0
  
  for CUR_INCLUDE_FILE in ${INCLUDE_FILES} ; do
#    LogMsg "Checking the include file \"${CUR_INCLUDE_FILE}\" ..."
  
    [[ ${CUR_INCLUDE_FILE} != */* ]] && CUR_INCLUDE_FILE="./${CUR_INCLUDE_FILE}"
 
    [[ ${CUR_INCLUDE_FILE} != /* ]] && CUR_INCLUDE_FILE="${PWD}/${CUR_INCLUDE_FILE}"

    if [ ! -f "${CUR_INCLUDE_FILE}" -o  ! -r "${CUR_INCLUDE_FILE}" ]  ; then
      LogError "The include file \"${CUR_INCLUDE_FILE}\" does not exist or is not readable"
      ERRORS_FOUND=${__TRUE}
      INCLUDE_FILES_NOT_FOUND="${INCLUDE_FILES_NOT_FOUND}
${CUR_INCLUDE_FILE}"
      (( NO_OF_INCLUDE_FILES_NOT_FOUND  = NO_OF_INCLUDE_FILES_NOT_FOUND + 1 ))
      continue
    fi

    INCLUDE_FILES_FOUND="${INCLUDE_FILES_FOUND}
${CUR_INCLUDE_FILE}"
    (( NO_OF_INCLUDE_FILES_FOUND  = NO_OF_INCLUDE_FILES_FOUND + 1 ))

    LogMsg "-"

    LogMsg "*** Help text for the include file \"${CUR_INCLUDE_FILE}\" :"  
    LogMsg "-" " --------------------------------------------------------------------- "    
    CUR_OUTPUT="$( grep "^#H#" "${CUR_INCLUDE_FILE}"  | cut -c4- 2>/dev/null )"
    LogMsg "-" "${CUR_OUTPUT}"
    LogMsg "-" " --------------------------------------------------------------------- "    
  done

  LogMsg "-"
  LogMsg "${NO_OF_INCLUDE_FILES_FOUND} include file(s) found"
  LogMsg "${NO_OF_INCLUDE_FILES_NOT_FOUND} include file(s) not found"

  if [ "${INCLUDE_FILES_FOUND}"x != ""x ] ; then
    LogMsg "-"
    LogMsg "Include files found are:"
    LogMsg "-" "${INCLUDE_FILES_FOUND}"
  fi

  if [ "${INCLUDE_FILES_NOT_FOUND}"x != ""x ] ; then
    LogMsg "-"
    LogMsg "Include files not found are:"
    LogMsg "-" "${INCLUDE_FILES_NOT_FOUND}"
  fi
  LogMsg "-"

  die 0      
fi
  
# ----------------------------------------------------------------------
# check for the definition of DEFAULT_TASKS in all include files
#

# ----------------------------------------------------------------------
# check and read the include files
#

ERRORS_FOUND=${__FALSE}

LogMsg "-"
LogInfo "Checking and reading the include file(s) \"${INCLUDE_FILES}\" now ..."

TASK_FUNCTIONS_FOUND=""
OPTIONAL_DEFAULT_TASKS=""
OPTIONAL_DEFAULT_TASKS_FILES=""

INCLUDE_FILES_ALREADY_PROCESSED=""

INCLUDE_FILES_WITHOUT_DEFAULT_TASK_DEFINITIONS=""

SOURCE_FILE_FOR_FINISH_TASKS="" 
SOURCE_FILE_FOR_INIT_TASKS=""

DUPLICATE_TASK_DEFINITIONS_FOUND=${__FALSE}

for CUR_INCLUDE_FILE in ${INCLUDE_FILES} ; do
  LogMsg "-"
  LogMsg "Checking the include file \"${CUR_INCLUDE_FILE}\" ..."
  
  [[ ${CUR_INCLUDE_FILE} != */* ]] && CUR_INCLUDE_FILE="./${CUR_INCLUDE_FILE}"
 
  [[ ${CUR_INCLUDE_FILE} != /* ]] && CUR_INCLUDE_FILE="${PWD}/${CUR_INCLUDE_FILE}"

  if [[ " ${INCLUDE_FILES_ALREADY_PROCESSED} " == *\ ${CUR_INCLUDE_FILE}\ * ]] ; then
    LogWarning "The include file \"${CUR_INCLUDE_FILE}\" was already processed"
    continue
  else
    INCLUDE_FILES_ALREADY_PROCESSED="${INCLUDE_FILES_ALREADY_PROCESSED} ${CUR_INCLUDE_FILE}"
  fi

  if [ ! -f "${CUR_INCLUDE_FILE}" -o ! -r "${CUR_INCLUDE_FILE}" ] ; then
    LogError "The include file \"${CUR_INCLUDE_FILE}\" does not exist or is not readable"
    ERRORS_FOUND=${__TRUE}
    continue
  fi

  INCLUDE_FILE_VERSION="$( grep -v "^#" "${CUR_INCLUDE_FILE}" | grep "INCLUDE_FILE_VERSION=" | tail -1 | cut -f2 -d "=" )"
  if [ "${INCLUDE_FILE_VERSION}"x != ""x ] ; then
    eval INCLUDE_FILE_VERSION=${INCLUDE_FILE_VERSION}
    if [[ " ${SUPPORTED_INCLUDE_FILE_VERSIONS} " != *\ ${INCLUDE_FILE_VERSION}\ * ]] ; then
      LogError "The version of the file \"${CUR_INCLUDE_FILE}\", \"${INCLUDE_FILE_VERSION}\", is not supported by this script"
      ERRORS_FOUND=${__TRUE}
      continue
    else
      LogInfo "The version of the include file \"${CUR_INCLUDE_FILE}\", \"${INCLUDE_FILE_VERSION}\", is okay."
    fi
  else
    LogInfo "There is no version defined in the include file \"${CUR_INCLUDE_FILE}\""
  fi

  THIS_OUTPUT="$( ${__SHELL} -n  "${CUR_INCLUDE_FILE}" 2>&1 )"
  if [ $? -ne 0 ] ; then
    LogError "There is at least one syntax error in the file \"${CUR_INCLUDE_FILE}\": "
    LogMsg "-" "${THIS_OUTPUT}"
    ERRORS_FOUND=${__TRUE}
    continue
  fi

  grep "^[[:space:]]*function[[:space:]]*init_tasks[[:space:]]*{" "${CUR_INCLUDE_FILE}" > /dev/null
  if [ $? -eq 0 ] ; then
    LogInfo "Function \"init_tasks\" found in the include file \"${CUR_INCLUDE_FILE}\" "
    SOURCE_FILE_FOR_INIT_TASKS="${CUR_INCLUDE_FILE}"
  fi

  grep "^[[:space:]]*function[[:space:]]*finish_tasks[[:space:]]*{" "${CUR_INCLUDE_FILE}" > /dev/null
  if [ $? -eq 0 ] ; then
    LogInfo "Function \"finish_tasks\" found in the include file \"${CUR_INCLUDE_FILE}\" "
    SOURCE_FILE_FOR_FINISH_TASKS="${CUR_INCLUDE_FILE}"
  fi
  
  ALREADY_DEFINED_TASKS=" $( typeset +f | grep ^task | tr "\n" " " ) "

  TASKS_DEFINED_IN_THIS_FILE="$( grep "^[[:space:]]*function[[:space:]]*task_" "${CUR_INCLUDE_FILE}" | awk '{ print $2 }' )"
   
  for CUR_TASK in ${TASKS_DEFINED_IN_THIS_FILE} ; do   
    if [[ " ${ALREADY_DEFINED_TASKS} " == *\ ${CUR_TASK}\ * ]] ; then
      eval PRIMARY_SOURCE_FILE="\${SOURCE_FILE_FOR_${CUR_TASK}}"

      if [ ${NO_WARNINGS_ABOUT_DUPLICATE_TASK_DEFINITIONS} != ${__TRUE} ] ; then
        LogWarning "Duplicate task definition found in the file \"${CUR_INCLUDE_FILE}\": ${CUR_TASK}"
        [ "${PRIMARY_SOURCE_FILE}"x != ""x ] && LogWarning "  The task is already defined in the include file \"${PRIMARY_SOURCE_FILE}\" "
      else 
        LogInfo "Duplicate task definition found in the file \"${CUR_INCLUDE_FILE}\": ${CUR_TASK}"
        [ "${PRIMARY_SOURCE_FILE}"x != ""x ] && LogInfo "  The task is already defined in the include file \"${PRIMARY_SOURCE_FILE}\" "
      fi
      DUPLICATE_TASK_DEFINITIONS_FOUND=${__TRUE}
    else
      eval SOURCE_FILE_FOR_${CUR_TASK}="${CUR_INCLUDE_FILE}"      
    fi
  done
    
  DEFAULT_TASKS=""
  NO_DEFAULT_TASKS=""

  DISABLE_THE_PARAMETER_ALL=""

  LogMsg "Reading the include file \"${CUR_INCLUDE_FILE}\" ..."
  .  "${CUR_INCLUDE_FILE}"


  if [ "${NO_DEFAULT_TASKS}"x != ""x ] ; then
    NO_TASK_LIST_FOR_ALL="${NO_TASK_LIST_FOR_ALL} ${NO_DEFAULT_TASKS}"
    LogInfo "Found this list of tasks to be excluded from  \"all\" in the include file \"${CUR_INCLUDE_FILE}\" :" 
    for THIS_TASK in ${NO_DEFAULT_TASKS} ; do
      LogInfo "  ${THIS_TASK}"
    done
  fi

  if [ "${DEFAULT_TASKS}"x = "all"x ] ; then
    if [ "${TASK_LIST_FOR_ALL}"x != ""x ]  ; then
      TASK_LIST_FOR_ALL="${TASK_LIST_FOR_ALL} ${TASKS_DEFINED_IN_THIS_FILE}"
    else
      LogInfo "All tasks defined in the file \"${CUR_INCLUDE_FILE}\" will be added to the list of default tasks to execute"
      OPTIONAL_DEFAULT_TASKS="${OPTIONAL_DEFAULT_TASKS}
#I#${CUR_INCLUDE_FILE}" 
      OPTIONAL_DEFAULT_TASKS="${OPTIONAL_DEFAULT_TASKS} $( echo "${TASKS_DEFINED_IN_THIS_FILE}" | grep -v "^#" ) "
      OPTIONAL_DEFAULT_TASKS_FILES="${OPTIONAL_DEFAULT_TASKS_FILES}
${CUR_INCLUDE_FILE}"
    fi
  elif [ "${DEFAULT_TASKS}"x = "none"x ] ; then
    LogInfo "Default tasks are disabled for the file \"${CUR_INCLUDE_FILE}\" "
    DEFAULT_TASKS=""
  elif [ "${DEFAULT_TASKS}"x != ""x ] ; then

    if [ "${OPTIONAL_DEFAULT_TASKS}"x != ""x ] ; then
      LogInfo "Processing the optional default tasks from the include files already read; these are the files: " && \
        LogMsg "-" "${OPTIONAL_DEFAULT_TASKS_FILES}
"

      for CUR_FUNCTION in ${OPTIONAL_DEFAULT_TASKS} ; do
        if [[ ${CUR_FUNCTION} == "#I#"* ]] ; then
          LogInfo "  Processing the default tasks from the include file \"${CUR_FUNCTION#*#I#}\" "
          continue
        fi
        if [[ ${TASK_LIST_FOR_ALL} == *\ ${CUR_FUNCTION}\ * ]] ; then
          LogInfo "    The function \"${CUR_FUNCTION}\" is already in the DEFAULT_TASKS list."
          continue
        fi
      
        LogInfo "    Adding the function \"${CUR_FUNCTION}\" to the DEFAULT_TASKS list"
        TASK_LIST_FOR_ALL="${TASK_LIST_FOR_ALL} ${CUR_FUNCTION}"
      done

      OPTIONAL_DEFAULT_TASKS=""
      OPTIONAL_DEFAULT_TASKS_FILES=""
    fi

    TASK_LIST_FOR_ALL="${TASK_LIST_FOR_ALL} $( echo "${DEFAULT_TASKS}" | grep -v "^#" ) "
    LogInfo "Found this list of tasks for \"all\" in the include file \"${CUR_INCLUDE_FILE}\" :" 
    for THIS_TASK in ${DEFAULT_TASKS} ; do
      LogInfo "  ${THIS_TASK}"
    done
  else
    LogInfo "No tasks defined in the file \"${CUR_INCLUDE_FILE}\" will be added to the list of default tasks to execute"
    INCLUDE_FILES_WITHOUT_DEFAULT_TASK_DEFINITIONS="${INCLUDE_FILES_WITHOUT_DEFAULT_TASK_DEFINITIONS}
${CUR_INCLUDE_FILE}"
  fi

#  if [ "${TASK_LIST_FOR_ALL}"x != ""x -a "${DEFAULT_TASKS}"x = ""x ] ; then
#    LogInfo "DEFAULT_TASKS is defined in other include files but not in the file \"${CUR_INCLUDE_FILE}\" "
#    LogInfo "Now creating the default task list for the file \"${CUR_INCLUDE_FILE}\" ..."
    
#    CURRENTLY_DEFINED_TASKS="$( typeset +f | grep ^task  )"
    
#    for CUR_FUNCTION in ${CURRENTLY_DEFINED_TASKS} ; do
#      if [[ ${ALREADY_DEFINED_TASKS} == *\ ${CUR_FUNCTION}\ * ]] ; then
#        LogInfo "The function \"${CUR_FUNCTION}\" is already in the DEFAULT_TASKS list."
#        continue
#      fi
#      LogInfo "  Adding the function \"${CUR_FUNCTION}\" to the DEFAULT_TASKS list"
#      TASK_LIST_FOR_ALL="${TASK_LIST_FOR_ALL} ${CUR_FUNCTION}"
#    done
#  fi

  if [ "${DISABLE_THE_PARAMETER_ALL}"x = "${__TRUE}"x ] ; then
    REAL_DISABLE_THE_PARAMETER_ALL="${__TRUE}"
    LogInfo "The parameter \"all\" is disabled in the include file \"${CUR_INCLUDE_FILE}\" "
    INCLUDE_FILES_WITH_DISABLED_PARAMETER_ALL="${INCLUDE_FILES_WITH_DISABLED_PARAMETER_ALL} ${CUR_INCLUDE_FILE}"
  fi

done


if [ "${TASK_LIST_FOR_ALL}"x != ""x ] ; then
  if [ "${INCLUDE_FILES_WITHOUT_DEFAULT_TASK_DEFINITIONS}"x != ""x ] ; then
    LogMsg "-"
    LogWarning "Definitions for DEFAULT_TASKS found in one or more include files but there are NO default task definitions in the include files" && \
      LogMsg "-" "${INCLUDE_FILES_WITHOUT_DEFAULT_TASK_DEFINITIONS}
"  && \
      LogMsg "NOTE: Add the statement \"DEFAULT_TASKS=none\" to the include files to suppress this warning if this is the expected behaviour"
  fi
fi

if [ ${ABORT_TASK_EXECUTION_ON_DUPLICATE_TASK_DEFINITIONS} = ${__TRUE} ] ; then
  LogError "One or more duplicate task definitions found"
  ERRORS_FOUND=${__TRUE}
fi  

if [ ${ERRORS_FOUND} = ${__TRUE} ] ; then
  die 15 "One or more errors found reading the include files"
fi

# ----------------------------------------------------------------------
# get the list of defined tasks
#

DEFINED_TASKS="$( typeset +f | grep ^task | grep -v task_template )"
if [ "${DEFINED_TASKS}"x = ""x ] ; then
 die 20 "No defined tasks found"
fi

# ----------------------------------------------------------------------
# check for the parameter --list
#

if [ ${LIST_DEFINED_TASK} = ${__TRUE} -o ${LIST_DEFAULT_TASK} = ${__TRUE} -o ${LIST_DEFINED_TASK_GROUPS} = ${__TRUE} ] ; then

  if [ ${LIST_DEFINED_TASK} = ${__TRUE} ] ; then

    set -f
    ListDefinedTasks  ${NOT_USED_PARAMETER}
    if [ ${LIST_DEFINED_TASK_GROUPS} = ${__TRUE} ] ; then
      ListDefinedTasksGroups ${NOT_USED_PARAMETER}
    fi
    set +f

    if [ ${VERBOSE} != ${__TRUE} -a "${TYPESET_F_SUPPORTED}"x = "yes"x ] ; then
      LogMsg "-"
      LogMsg "-" "Use the parameter \"-v\" to also list the usage help for each task"
      LogMsg "-"
    else
      LogMsg "-"
    fi
  
    LogMsg "-" "Note: use \":\" to separate the task name and the parameter"
    LogMsg "-"

  fi

  if [ ${LIST_DEFAULT_TASK} = ${__TRUE} ] ; then

    ListDefaultTasks
  
  fi

  if [ ${LIST_DEFINED_TASK_GROUPS} = ${__TRUE} -a ${LIST_DEFINED_TASK} != ${__TRUE} ] ; then
  
    set -f
    ListDefinedTasksGroups ${NOT_USED_PARAMETER}
    set +f
  
  fi

  die 0

fi


# ----------------------------------------------------------------------
# process the list of requested tasks
#

if [ $# -eq 0 ] ; then
  LogMsg "-"
  die 0 "No tasks to execute found in the parameter; use the parameter \"--list\" to list all known tasks or \"--help\" to view the script usage"
fi

if [ "${DISABLED_TASKS_FOUND_IN_THE_PARAMETER}"x = ""x ] ; then
  LogInfo "No disabled tasks found in the parameter"
else
  LogMsg "Tasks disabled via parameter are:"
  LogMsg "-" "${DISABLED_TASKS_FOUND_IN_THE_PARAMETER}"

  DISABLED_TASKS="${DISABLED_TASKS} ${DISABLED_TASKS_FOUND_IN_THE_PARAMETER}"
fi

# add the function print_summaries to the list of functions to execute at script end
#
FINISH_FUNCTIONS="${FINISH_FUNCTIONS} print_summaries"

TASK_SEPARATOR_LINE=" ---------------------------------------------------------------------- "

MAINRC=0

TASKS_NOT_FOUND=""
TASKS_EXECUTED_SUCCESSFULLY=""
TASKS_EXECUTED_WITH_ERRORS=""
TASKS_SKIPPED_ON_REQUEST=""

NO_OF_TASKS_PROCESSED=0
NO_OF_TASKS_NOT_FOUND=0
NO_OF_TASKS_EXECUTED_SUCCESSFULLY=0
NO_OF_TASKS_EXECUTED_WITH_ERRORS=0
NO_OF_TASKS_SKIPPED_ON_REQUEST=0

if [ ${USE_ONLY_KSH88_FEATURES} != ${__TRUE} ] ; then
  typeset -A TASKS_TO_EXECUTE
fi  

TASKS_TO_EXECUTE[0]=0

# ----------------------------------------------------------------------
# create the list of known task groups
#
TASK_GROUPS=""

for CUR_TASK_GROUP in $( set | cut -f1 -d "="  | grep "^TASK_GROUP_" ) ; do
  TASK_GROUPS="${TASK_GROUPS} ${CUR_TASK_GROUP#*TASK_GROUP_} "
done

TASKS_IN_CUR_TASK_GROUP_INFO="$( echo "${TASKS_IN_TASK_GROUP}" | grep "^#I#" | cut -c3- )"
TASKS_IN_TASK_GROUP="$( echo "${TASKS_IN_TASK_GROUP}" | grep -v "^#" )"

# LogInfo "Task group \"${CUR_TASK}\" found "

[ "${TASKS_IN_CUR_TASK_GROUP_INFO}"x != ""x ] && LogInfo "Taskgroup info is :
${TASKS_IN_CUR_TASK_GROUP_INFO}"


if [ "${TASK_GROUPS}"x != ""x ] ; then
  LogInfo "Task groups defined in the include files are:"
  for CUR_TASK_GROUP in ${TASK_GROUPS} ; do
    LogInfo "  Task group \"${CUR_TASK_GROUP}\" found"
    
    eval TASK_GROUP_MEMBERS="\${TASK_GROUP_${CUR_TASK_GROUP}}"

    CUR_TASK_GROUP_INFO="$( echo "${TASK_GROUP_MEMBERS}" | grep "^#I#" | cut -c3- )"
    TASK_GROUP_MEMBERS="$( echo "${TASK_GROUP_MEMBERS}" | grep -v "^#" )"

    [ "${CUR_TASK_GROUP_INFO}"x != ""x ] && LogInfo "    Taskgroup info for the task group \"${CUR_TASK_GROUP}\" is :
${CUR_TASK_GROUP_INFO}" 

    LogInfo "    The tasks in the task group \"${CUR_TASK_GROUP}\" are: "

    for THIS_TASK in ${TASK_GROUP_MEMBERS} ; do
      LogInfo "      ${THIS_TASK}"
    done
  done
else
  LogInfo "No task groups found in the include files"
fi

# ------------------------------------------------------------------------
#  Preprocess the parameter
#
LogMsg "-"
LogMsg "Processing the parameter  ..."

if [ ${USE_ONLY_KSH88_FEATURES} != ${__TRUE} ] ; then
  typeset -A TASKS_FOUND
fi  
TASKS_FOUND[0]=0

PARAMETER_ALL_FOUND=${__FALSE}
PARAMETER_all_FOUND=${__FALSE}

i="${TASKS_FOUND[0]}" 

while [ $# -ne 0 ] ; do
  CUR_PARAMETER="$1"
  shift

  [[ "${CUR_PARAMETER}" == "--" ]] && break
  
  LogInfo "  Processing the parameter \"${CUR_PARAMETER}\" ..."

  if [[ ${CUR_PARAMETER} == */* ]] ; then
    CUR_TASK_FILE="${CUR_PARAMETER}"

    LogMsg "Reading the tasks to execute from the file \"${CUR_TASK_FILE}\" ..."
    if [  ! -r "${CUR_TASK_FILE}" ] ; then
      die 32 "The file \"${CUR_TASK_FILE}\" does not exist or is not readable"
    fi

    while read CUR_LINE ; do
      [ "${CUR_LINE}"x = ""x ] && continue
      [[ ${CUR_LINE} == \#* ]] && continue
      LogInfo "    Processing the line \"${CUR_LINE}\" ..."
      
      if [[ ${CUR_LINE} == all ]] ; then
        PARAMETER_all_FOUND=${__TRUE}
        continue
      fi

      if [[ ${CUR_LINE} == ALL ]] ; then
        PARAMETER_ALL_FOUND=${__TRUE}
        continue
      fi

      [[ ${CUR_LINE} == TASK_GROUP_* ]] && CUR_LINE="${CUR_LINE#*TASK_GROUP_}"
      
      CUR_TASK_NAME="$( echo "${CUR_LINE}" | sed -e "s/ /:/g" )"
      LogInfo "CUR_TASK_NAME is \"${CUR_TASK_NAME}\" "
      
#      CUR_TASK_PARAMETER="${CUR_LINE#* }"
#      CUR_TASK_NAME="${CUR_LINE%% *}"

#      [ "${CUR_TASK_NAME}"x != "${CUR_TASK_PARAMETER}"x ] && CUR_TASK_NAME="${CUR_TASK_NAME}:${CUR_TASK_PARAMETER}"

      (( i = i +1 ))
      TASKS_FOUND[$i]="${CUR_TASK_NAME}"    
    done <"${CUR_TASK_FILE}"
  else

    if [[ ${CUR_PARAMETER} == all ]] ; then
      PARAMETER_all_FOUND=${__TRUE}
      continue
    fi

    if [[ ${CUR_PARAMETER} == ALL ]] ; then
      PARAMETER_ALL_FOUND=${__TRUE}
      continue
    fi

    (( i = i + 1 ))
    TASKS_FOUND[$i]="${CUR_PARAMETER}"
    
  fi
done
TASKS_FOUND[0]=$i

# ------------------------------------------------------------------------

LogMsg "-"
LogMsg "Preparing the list of tasks to execute ..."

# ------------------------------------------------------------------------

PROCESS_ALL_TASKS=${__FALSE}

if [ ${PARAMETER_all_FOUND} = ${__TRUE} ] ; then
  if [ "${REAL_DISABLE_THE_PARAMETER_ALL}"x = "${__TRUE}"x ] ; then
    LogError "Parameter \"all\" found but the parameter \"all\" is disabled in these include files:"
    LogMsg "-" "${INCLUDE_FILES_WITH_DISABLED_PARAMETER_ALL}"
    die 30 "Parameter \"all\" is disabled in at least one include file"
  fi

  LogMsg "Parameter \"all\" found - now ignoring all other task parameter and executing all defined tasks"
  if [ "${TASK_LIST_FOR_ALL}"x != ""x ] ; then
    LogMsg "Executing the tasks defined in the include file(s) for \"all\" "
    LIST_OF_TASKS_TO_EXECUTE="${TASK_LIST_FOR_ALL}"
  else
    LogMsg "Executing all defined tasks in all include files read"
    LIST_OF_TASKS_TO_EXECUTE="${DEFINED_TASKS}"
  fi    

  PROCESS_ALL_TASKS=${__TRUE}
fi

if [ ${PARAMETER_ALL_FOUND} = ${__TRUE} ] ; then
  LogMsg "Parameter \"ALL\" found: Now ignoring all other task parameter and the settings for \"all\" from the include files"

  LIST_OF_TASKS_TO_EXECUTE="${DEFINED_TASKS}"

  PROCESS_ALL_TASKS=${__TRUE}
fi

# ------------------------------------------------------------------------

if [ ${PROCESS_ALL_TASKS} = ${__TRUE} ] ; then
 
  TASKS_FOUND[0]=0
  i="${TASKS_FOUND[0]}"

  for CUR_TASK in ${LIST_OF_TASKS_TO_EXECUTE} ; do
    [[ ${CUR_TASK} == task_dummy* ]] && continue
    (( i = i + 1 ))
    TASKS_FOUND[$i]="${CUR_TASK}"
  done
   
  TASKS_FOUND[0]=$i
  
fi


# ------------------------------------------------------------------------

  i="${TASKS_TO_EXECUTE[0]}"
  j=0
  
  while [ $j -lt ${TASKS_FOUND[0]} ] ; do
    (( j = j + 1 ))
    CUR_TASK="${TASKS_FOUND[$j]}"

    if [[ ${TASK_GROUPS} = *\ ${CUR_TASK}\ * ]] ; then
 
      eval TASKS_IN_TASK_GROUP="\${TASK_GROUP_${CUR_TASK}}"

      TASKS_IN_CUR_TASK_GROUP_INFO="$( echo "${TASKS_IN_TASK_GROUP}" | grep "^#I#" | cut -c3- )"
      TASKS_IN_TASK_GROUP="$( echo "${TASKS_IN_TASK_GROUP}" | grep -v "^#" )"

      LogInfo "Task group \"${CUR_TASK}\" found "

      [ "${TASKS_IN_CUR_TASK_GROUP_INFO}"x != ""x ] && LogInfo "Taskgroup info is :
${TASKS_IN_CUR_TASK_GROUP_INFO}"

      LogInfo "The tasks in that task group are: "
      for THIS_TASK in ${TASKS_IN_TASK_GROUP} ; do
        LogInfo "  ${THIS_TASK} "
      done

      THIS_TASK_LIST="${TASKS_IN_TASK_GROUP}"
    else
      THIS_TASK_LIST="${CUR_TASK}"
      LogInfo "Adding the task \"${CUR_TASK}\" to the queue "
    fi
    
    set -f
    for CUR_TASK in ${THIS_TASK_LIST} ; do
      if [[ ${CUR_TASK} == *\** || ${CUR_TASK} == *\?* ]] ; then
        TASKS_FOR_REGEX_FOUND=""        
        CUR_TASK_REGEX="${CUR_TASK}"
        for CUR_TASK in ${DEFINED_TASKS} ; do
          if [[ ${CUR_TASK} == task_${CUR_TASK_REGEX}  || ${CUR_TASK} == ${CUR_TASK_REGEX}  ]] ; then
            (( i = i + 1 ))
            TASKS_TO_EXECUTE[$i]="${CUR_TASK}"

            TASKS_FOR_REGEX_FOUND="${TASKS_FOR_REGEX_FOUND} ${CUR_TASK}"
          fi
        done
        LogInfo "Regex \"${CUR_TASK_REGEX}\" found; the regex evaluates to "
        for THIS_TASK in ${TASKS_FOR_REGEX_FOUND} ; do
          LogInfo "  ${THIS_TASK} "
        done
      else
        (( i = i + 1 ))
        TASKS_TO_EXECUTE[$i]="${CUR_TASK}"
      fi
    done
    set +f
  done


TASKS_TO_EXECUTE[0]=$i

# ------------------------------------------------------------------------

if [ ${CHECK_TASKS} = ${__TRUE} ] ; then
  LogMsg "Checking if all requested tasks exist ..."
  i=0
  ERRORS_FOUND=${__FALSE}
  while [ $i -lt ${TASKS_TO_EXECUTE[0]} ] ; do
    (( i = i + 1 ))
    CUR_TASK="${TASKS_TO_EXECUTE[$i]}"

    LogInfo "Checking the task \"${CUR_TASK}\" ..."


    CUR_TASK_PARAMETER="${CUR_TASK#*:}"
    CUR_TASK_NAME="${CUR_TASK%%:*}"
    [[ "${CUR_TASK_NAME}" != task_* ]] && CUR_TASK_NAME="task_${CUR_TASK_NAME}"

    LogInfo "Parsed task name is :          \"${CUR_TASK_NAME}\""
    LogInfo "Parsed task parameter are :    \"${CUR_TASK_PARAMETER}\""

    typeset -f "${CUR_TASK_NAME}" >/dev/null
    if [ $? -eq 0 ] ; then
      LogInfo "The task \"${CUR_TASK_NAME}\" exists"
    else
      LogError "The task \"${CUR_TASK_NAME}\" does not exist"
      ERRORS_FOUND=${__TRUE}
      TASKS_NOT_FOUND="${TASKS_NOT_FOUND} ${CUR_TASK_NAME}"
      (( NO_OF_TASKS_NOT_FOUND = NO_OF_TASKS_NOT_FOUND + 1 ))
    fi
  done

  if [ ${ERRORS_FOUND} = ${__TRUE} ] ; then
    LogError "${NO_OF_TASKS_NOT_FOUND} task(s) not found:"
    LogMsg "-" "${TASKS_NOT_FOUND}"
    die 35 "Tasks missing"
  else
    LogMsg "All requested tasks exist."
    [ ${CHECK_ONLY} = ${__TRUE} ] && die 0
  fi

  TASKS_NOT_FOUND=""
  NO_OF_TASKS_NOT_FOUND=0

fi

# ----------------------------------------------------------------------
# execute the function init_tasks if it's defined
#

if [ "${SOURCE_FILE_FOR_INIT_TASKS}"x != ""x ] ; then
  if [ ${VERBOSE} = ${__TRUE} -o ${ONLY_LIST_TASKS_TO_EXECUTE} = ${__TRUE} ] ; then
    LogMsg "The function \"init_tasks\" to use is the one from the include file \"${SOURCE_FILE_FOR_INIT_TASKS}\" "
  fi
fi

if typeset +f init_tasks >/dev/null ; then

  if [ ${ONLY_LIST_TASKS_TO_EXECUTE} = ${__FALSE} ] ; then
    if [ ${DO_NOT_EXECUTE_INIT_TASKS} = ${__TRUE} ] ; then
      LogMsg "\"init_tasks\" is defined but the execution is disabled via parameter."
      if [ "${PARAMETER_FOR_INIT_TASKS}"x != ""x ] ; then
        LogWarning "There are parameter defined for the function init_tasks: \"${PARAMETER_FOR_INIT_TASKS}\" "
      fi
    else
      LogMsg "\"init_tasks\" is defined - now executing it ..."
      LogMsg "-" "${TASK_SEPARATOR_LINE}"
      ${PREFIX}  init_tasks
      TEMPRC=$?
      LogMsg "-" "${TASK_SEPARATOR_LINE}"
      if [ ${TEMPRC} -ne ${__TRUE} ] ; then
        die 36 "init_tasks ended with an return code not ${__TRUE}"
      fi
    fi
  fi
else
  if [ "${PARAMETER_FOR_INIT_TASKS}"x != ""x ] ; then
    LogWarning "No function \"init_tasks\" defined in the include files"
    LogWarning "But there are parameter defined for the function init_tasks: \"${PARAMETER_FOR_INIT_TASKS}\" "
  else
    LogMsg "No function \"init_tasks\" defined in the include files"
  fi
fi
set +x

CLEANUP_FUNCTIONS="${CLEANUP_FUNCTIONS} execute_finish_tasks"

# ----------------------------------------------------------------------
#

if [ ${ONLY_LIST_TASKS_TO_EXECUTE} = ${__FALSE} ] ; then
  LogMsg "Executing the tasks now ..."
else  
  LogMsg "Will only list the tasks to execute"
  if [ "${DISABLED_TASKS_FOUND_IN_THE_PARAMETER}"x != ""x ] ; then
    LogMsg "Note: The list of tasks might contain disabled tasks - the disabled tasks will be processed while executing the tasks."
    LogMsg "      Use the parameter \"-d\" to check which tasks would be executed after processing the list of disabled tasks"
  fi
fi

LogMsg "-"
LogMsg "The tasks to execute are:"
ListTasksToExecute
LogMsg "-"

if [ ${ONLY_LIST_TASKS_TO_EXECUTE} = ${__TRUE} ] ; then
  die 0 
fi
  
if [ ${SINGLE_STEP_MODE} = ${__TRUE} ] ; then
  LogMsg "The tasks will be executed in single step mode."
  LogMsg "-"
fi

SINGLE_STEP_TEMPORARY_DISABLED=${__FALSE}
JUMP_DONE=${__FALSE}

TASKS_ALREADY_EXECUTED=""
TASKS_SKIPPED_ON_REQUEST=""

i=0
while [ $i -lt ${TASKS_TO_EXECUTE[0]} ] ; do 

  (( i = i + 1 ))
  
  (( NO_OF_TASKS_PROCESSED = NO_OF_TASKS_PROCESSED + 1 ))

  CUR_TASK="${TASKS_TO_EXECUTE[$i]}"

# check if this task is disabled
#
  if [ "${DISABLED_TASKS}"x != ""x ] ; then
    set -f

    EXECUTE_TASK=${__TRUE}
    for CUR_EXCLUDE_TASK_MASK in ${DISABLED_TASKS} ; do
      if [[ ${CUR_TASK#task_*}  == ${CUR_EXCLUDE_TASK_MASK} || ${CUR_TASK}  == ${CUR_EXCLUDE_TASK_MASK} ]] ; then
        set +f
        LogWarning "The task \"${CUR_TASK}\" is disabled (exclude mask is \"${CUR_EXCLUDE_TASK_MASK}\") - skipping this task now"
        TASKS_SKIPPED_ON_REQUEST="${TASKS_SKIPPED_ON_REQUEST} ${CUR_TASK}"
        (( NO_OF_TASKS_SKIPPED_ON_REQUEST = NO_OF_TASKS_SKIPPED_ON_REQUEST  + 1 ))
        EXECUTE_TASK=${__FALSE}
        SINGLE_STEP_TEMPORARY_DISABLED=${__FALSE}
        break
      fi
    done
    set +f
    [ ${EXECUTE_TASK} = ${__FALSE} ] && continue
  fi
  
  if [ ${PARAMETER_all_FOUND} = ${__TRUE} -a "${NO_TASK_LIST_FOR_ALL}"x != ""x ] ; then
    EXECUTE_TASK=${__TRUE}
   set -f
    for CUR_EXCLUDE_TASK_MASK in ${NO_TASK_LIST_FOR_ALL} ; do
      if [[ ${CUR_TASK#task_*}  == ${CUR_EXCLUDE_TASK_MASK} || ${CUR_TASK}  == ${CUR_EXCLUDE_TASK_MASK} ]] ; then
        LogMsg "INFO: The task \"${CUR_TASK}\" should not be executed if \"all\" is used (exclude mask is \"${CUR_EXCLUDE_TASK_MASK}\") - skipping this task now"
        TASKS_SKIPPED_ON_REQUEST="${TASKS_SKIPPED_ON_REQUEST} ${CUR_TASK}"
        (( NO_OF_TASKS_SKIPPED_ON_REQUEST = NO_OF_TASKS_SKIPPED_ON_REQUEST  + 1 ))
        EXECUTE_TASK=${__FALSE}
        SINGLE_STEP_TEMPORARY_DISABLED=${__FALSE}
        break
      fi
    done
   set +f
    
    [ ${EXECUTE_TASK} = ${__FALSE} ] && continue
  fi

  if [ ${EXECUTE_TASKS_ONLY_ONCE} = ${__TRUE} ] ; then
    if [[ ${TASKS_ALREADY_EXECUTED} == *\ ${CUR_TASK%:*}\ *  ]] ; then
      LogWarning "The task \"${CUR_TASK%:*}\" was already executed - skipping the request for this task now"
      continue
    fi
  fi
    
  if [ $i -gt 1 -a JUMP_DONE=${__FALSE} ] ; then
    (( j = i - 1 ))
    LAST_TASK="${TASKS_TO_EXECUTE[$j]}"
    LAST_TASK_PARAMETER="${LAST_TASK#*:}"
    LAST_TASK_NAME="${LAST_TASK%%:*}"
    if [ "${LAST_TASK_NAME}"x = "${LAST_TASK_PARAMETER}"x ] ; then
      LAST_TASK_PARAMETER=""
      LAST_TASK_PARAMETER_MSG=""
    else
      LAST_TASK_PARAMETER_MSG="with the parameter \"${CUR_TASK_PARAMETER}\""
    fi
  fi

  JUMP_DONE=${__FALSE}
  
  LogInfo "Processing the task \"${CUR_TASK}\" ..."

  CUR_TASK_PARAMETER="${CUR_TASK#*:}"
  CUR_TASK_NAME="${CUR_TASK%%:*}"

  LogInfo "Parsed task name is :          \"${CUR_TASK_NAME}\""
  LogInfo "Parsed task parameter are :    \"${CUR_TASK_PARAMETER}\""
    
  if [ "${CUR_TASK_PARAMETER}"x = "${CUR_TASK_NAME}"x ] ; then
    CUR_TASK_PARAMETER=""
    TASK_PARAMETER_MSG=""
  else
    TASK_PARAMETER_MSG="with the parameter \"${CUR_TASK_PARAMETER}\""
  fi
  [[ "${CUR_TASK_NAME}" != task_* ]] && CUR_TASK_NAME="task_${CUR_TASK_NAME}"
  CUR_TASK_PARAMETER="$( echo "${CUR_TASK_PARAMETER}" | sed "s/:/ /g" )"

  LogInfo "Evaluated task name is :       \"${CUR_TASK_NAME}\""
  LogInfo "Evaluated task parameter are : \"${CUR_TASK_PARAMETER}\""
  
#  LogMsg "Processing the task \"${CUR_TASK_NAME}\" ${TASK_PARAMETER_MSG} ..."  
#  LogMsg "-"

  if [ ${SINGLE_STEP_MODE} = ${__TRUE} -a ${SINGLE_STEP_TEMPORARY_DISABLED} = ${__FALSE} ] ; then
  
    EXECUTE_THIS_STEP=${__TRUE}
    
    while true ; do
      LogMsg "-"
      LogMsg "-" "=================================================================================="
      if [ $i -gt 1 ] ; then
        LogMsg "-" "The last task processed was \"${LAST_TASK_NAME}\" ${LAST_TASK_PARAMETER_MSG} "
      fi
      AskUser "Execute the task \\\"${CUR_TASK_NAME}\\\" ${TASK_PARAMETER_MSG} now (qarlLnY, h for help)?"
      case ${USER_INPUT} in

        help | h )
          LogMsg "-" "
Known commands:

q | quiet      -- end the script
a | all        -- disable single step for the remaining tasks
r | repeat     -- execute the last step again
l | list       -- list the remaining tasks
L | List       -- list all tasks in the task queue
ld             -- list all deinfed tasks
j # | jump #   -- jump to task no #
y | yes        -- execute the next step
n | no         -- skip the next step
h | help       -- print this help
"
          ;;
          
        j\ * | jump\ * )
          NEXT_TASK_NUMBER="${USER_INPUT#* }"
          if [[ ${NEXT_TASK_NUMBER} == *\ * ]] ; then
            LogMsg "-" "\"${NEXT_TASK_NUMBER}\" is not a number"
          elif ! isNumber "${NEXT_TASK_NUMBER}" ; then
            LogMsg "-" "\"${NEXT_TASK_NUMBER}\" is not a number"
          elif [ ${NEXT_TASK_NUMBER} -le 0 -o ${NEXT_TASK_NUMBER} -gt ${TASKS_TO_EXECUTE[0]} ] ; then
            LogMsg "Invalid number: \"${NEXT_TASK_NUMBER}\" -- The task number must be in the range 1 and ${TASKS_TO_EXECUTE[0]}"
          else
            (( i = NEXT_TASK_NUMBER -1 ))
            EXECUTE_THIS_STEP=${__FALSE}
            JUMP_DONE=${__TRUE}
            break
          fi
          ;;

        List | L) 
           LogMsg "-"
           LogMsg "-" "The tasks in the task queue are :"
           ListTasksToExecute 1
           ;;
           
        ListDefinedTasks | ld )  
          ListDefinedTasks
          ;;

        list | l )
           LogMsg "-"
           LogMsg "-" "The remaining tasks are :"
           ListTasksToExecute $i
           ;;
                     
        quiet | q )
          die 100 "Task execution aborted by the user"
          ;;

        all | a )
          LogMsg "-" "Singlestep mode is disabled now for the remaining tasks"
          SINGLE_STEP_MODE=${__FALSE}
          EXECUTE_THIS_STEP=${__TRUE}
          break
          ;;

        repeat | r )
          if [ $i -gt 1 ] ; then
            LogMsg "-" "Executing the last task \"${LAST_TASK_NAME}\" ${LAST_TASK_PARAMETER_MSG} again now ..."
            (( i = i - 2 ))
            SINGLE_STEP_TEMPORARY_DISABLED=${__TRUE}

            EXECUTE_THIS_STEP=${__FALSE}
            break
          else
            LogMsg  "-" "This is the first task to execute - there is no last task to execute again yet."
            continue
          fi
          ;;

        no | n | NO )
          LogMsg "-" "Not executing the task \"${CUR_TASK_NAME}\" on user request."
          EXECUTE_THIS_STEP=${__FALSE}
          break
          ;;        

        yes | y | YES | "" )
          LogMsg "-" "Executing the task \"${CUR_TASK_NAME}\" now ..."
          EXECUTE_THIS_STEP=${__TRUE}
          break
          ;;        

        * )
          LogMsg "-" "Unknown input: ${USER_INPUT}"
          ;;

      esac               
    done

    [ ${EXECUTE_THIS_STEP} != ${__TRUE} ] && continue


  else
    LogMsg "Processing the task \"${CUR_TASK_NAME#task_*}\" ${TASK_PARAMETER_MSG} ..."  
  fi
  SINGLE_STEP_TEMPORARY_DISABLED=${__FALSE}
   
  if ! typeset -f "${CUR_TASK_NAME}" 2>/dev/null 1>/dev/null ; then
    LogError "Task \"${CUR_TASK_NAME}\" is not defined"
    TASKS_NOT_FOUND="${TASKS_NOT_FOUND} ${CUR_TASK}"
    (( NO_OF_TASKS_NOT_FOUND = NO_OF_TASKS_NOT_FOUND + 1 ))
    [ ${ABORT_TASK_EXECUTION_ON_TASK_NOT_FOUND} = ${__TRUE} ] && die 45 "The task \"${CUR_TASK}\" is not defined"
    MAINRC=1
    continue
  fi


    TASKS_ALREADY_EXECUTED=" ${TASKS_ALREADY_EXECUTED} ${CUR_TASK_NAME} "
    
    LogMsg "Executing now \"${CUR_TASK_NAME#task_*} ${CUR_TASK_PARAMETER}\""
    LogMsg "-"
    LogMsg "-" "${TASK_SEPARATOR_LINE}"
    __CUR_INDEX="$i"
    
    if [ ${VERBOSE_FOR_TASKS} = ${__TRUE} ] ; then
      CUR_VERBOSE_MODE=${VERBOSE}
      VERBOSE=${__TRUE}
    fi
    
    ${PREFIX} ${CUR_TASK_NAME} ${CUR_TASK_PARAMETER}
    TEMPRC=$?
    i=${__CUR_INDEX}

    if [ ${VERBOSE_FOR_TASKS} = ${__TRUE} ] ; then
      VERBOSE=${CUR_VERBOSE_MODE}
    fi
    
    LogMsg "-" "${TASK_SEPARATOR_LINE}"
    LogMsg "-"

    if [ ${TEMPRC} -eq ${__TRUE} ] ; then
      TASKS_EXECUTED_SUCCESSFULLY="${TASKS_EXECUTED_SUCCESSFULLY} ${CUR_TASK#task_*}"
      (( NO_OF_TASKS_EXECUTED_SUCCESSFULLY = NO_OF_TASKS_EXECUTED_SUCCESSFULLY + 1 ))
    else
      TASKS_EXECUTED_WITH_ERRORS="${TASKS_EXECUTED_WITH_ERRORS} ${CUR_TASK#task_*}"
      (( NO_OF_TASKS_EXECUTED_WITH_ERRORS = NO_OF_TASKS_EXECUTED_WITH_ERRORS + 1 ))
      [ ${ABORT_TASK_EXECUTION_ON_ERROR} = ${__TRUE} ] && die 5 "The task \"${CUR_TASK}\" ended with an error"
      MAINRC=1
    fi
    
done

# ----------------------------------------------------------------------
#
die ${MAINRC}


# ----------------------------------------------------------------------
#
