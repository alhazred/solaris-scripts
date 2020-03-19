#!/bin/ksh
#

###############################################
# This script generates a system fingerprint 
# that can be ported to STAR OFFICE or MS WORD
# (if you must). Good plan for system data
# 
# -Tech
###############################################
# 11/05/04
# Resolved some disk reporting issues. 
# Disk connected via Fabric errored on vtoc.
# 
# -Tech
###############################################




alias EECHO=/usr/bin/echo 

HEAD_OUTPUT=./head.`date '+%m%d%y'`.txt
TOC_OUTPUT=./toc.`date '+%m%d%y'`.txt
CONTENT_OUTPUT=./content.`date '+%m%d%y'`.txt
FINAL_OUTPUT=./`hostname`.`date '+%m%d%y'`.htm
x=0
y=0

# Initialize cache files 
EECHO " " > $HEAD_OUTPUT
EECHO "<br><h4 align=center>TABLE OF CONTENTS</h4><br> " > $TOC_OUTPUT
EECHO " " > $CONTENT_OUTPUT

function html_header {
	EECHO "<html>\n\
<head>\n\
<style>\n\
h1{font-size:24.0pt;font-family:arial;}\n\
h2{font-size:18.0pt;font-family:arial;}\n\
h3{font-size:14.0pt;font-family:arial;}\n\
h4{font-size:12.0pt;font-family:arial;}\n\
.toc{text-align:center;font-size:12.0pt;font-family:arial;}\n\
.text{text-align:center;font-size:12.0pt;font-family:arial;}\n\
.heading{text-align:right;font-size:10.0pt;font-family:arial;color:#FFFFFF}
pre{font-size:10.0pt;font-family:courier;}\n\
</style>\n\
</head>\n\
<body bgcolor=#f0f0f0>\n " 
	
}
function html_border {
	EECHO "<div style='border:none;border-bottom:double windowtext 2.25pt;padding:0in 0in 1.0pt 0in'></div>"
}

function html_logo {
	EECHO "<!-- ********************* AMTRAK LOGO AND HEADING **************** -->"
	EECHO "<table bgcolor=#000000 border=0 cellpadding=5 cellspacing=0 width=100%><TR><TD align=left>"
	EECHO "<img src='http://www.ttsolutions.com/images/title.gif'></td>"
	EECHO "<td class=heading align=right>`date | tr '[:lower:]' '[:upper:]'` </td></tr></table>"
}

function table_top {
	EECHO "<table border=0 width=85% cellpadding=2>"
	EECHO "<tr><td style='border-top:solid #000000 .05pt; border-bottom: solid #000000 .05pt; border-left:solid #000000 .05pt;border-right:solid #000000 .05pt; background: #CCCCCC;' ><pre>"
}

function table_bottom {
	EECHO "</pre></td></tr></table>"
}

function xy_reset {
        # Reset Y and increment X variable for document autoformat
        let x=x+1
        let y=0
}

function create_toc {
	#  Creating Table Of Contents
	EECHO "<span class='toc'><a href='#_$x.$y.'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$x.$y. - $TITLE</a></span><br>" >> $TOC_OUTPUT
}

function create_h2_toc {
	#  Creating Table Of Contents
	EECHO "<span class='toc'><a href='#_$x.$y.'><b>$x.$y. - $TITLE</b></a></span><br>" >> $TOC_OUTPUT
}

function doc_title {
	TITLE="`hostname | tr '[:lower:]' '[:upper:]'` AS-BUILT DOCUMENTATION"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
       	html_border 
	create_h2_toc 
	EECHO "<h1 align=center><a name=_$x.$y.>"
	EECHO "`hostname | tr '[:lower:]' '[:upper:]'` AS-BUILT DOCUMENTATION \n</a></h1>"
#	\n<h4 align=center>`date | tr '[:lower:]' '[:upper:]'`</h4> "
       	html_border 
	EECHO "<br>"
	xy_reset
}


function doc_basic_system {
       	html_border 
	TITLE="System Summary"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	EECHO "<span class=text>"
	EECHO "<b>Hostname:</b> `hostname`<br>" 
	EECHO "<b>Hardware Platform:</b> `uname -i | awk -F, '{print $2}'`<br>" 
	ifconfig -a | grep -v 127 | grep inet | awk '{print "<b>IP Address:</b> "$2"<br>\n<b>Netmask:</b> "$4"<br>"}'
	if [[ -a /etc/serial ]]; then 
		EECHO "`cat /etc/serial`<br>" 
	else 
		EECHO "<b>System Serial Number:</b> unknown<br>" 
	fi
	EECHO "<b>HostID:</b> `hostid`<br>" 
	EECHO "<b>FQDN:</b> `hostname`.`domainname`<br>" 
	prtconf | grep 'Memory size:' | awk -F: '{print "<b>"$1":</b> "$2}' 
	EECHO "<br>"
	z=`swap -s | awk '{print $11}' | sed 's/k//g'`
	let z=z/1000 
	EECHO "<b>Swap size:</b> $z MB<br>"
	z=`psrinfo | wc -l | awk '{print $1}'`
	EECHO "<b>Processor Information:</b> $z Processor(s)<br>\n"
	psrinfo -v | grep 'operates at' | awk '{print  "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"NR, $2, $6$7"<br>"}' | sed 's/,//g'
	EECHO "</span>"
	EECHO "<br><br>"

        # Reset Y and increment X variable for document autoformat
	xy_reset
}

function doc_system {
	TITLE="System Identification"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	let y=y+1

	TITLE="System Identification - (/etc/release)"
	create_toc 
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE </a> \n"
	EECHO "</h3>"

	table_top
	EECHO "`cat /etc/release`"
	table_bottom
	EECHO "<br>"

	# Reset Y and increment X variable for document autoformat
	xy_reset
}

function doc_network {
	TITLE="Network Configuration"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	let y=y+1

	TITLE="Network Configuration Files - (/etc/hostname.*)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	for file in `ls -l /etc/hostname.* | awk '{print $9}'`
	do
		EECHO "<span class=text>Contents of $file :</span>"
		table_top
		EECHO "`cat $file` \n"
		table_bottom
	done
	EECHO "\n"
	let y=y+1
	
	
	TITLE="Network Configuration Files - (/etc/defaultrouter)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	table_top
	if [[ -a /etc/defaultrouter ]]; then 
		EECHO "`cat /etc/defaultrouter`" 
	else 
		EECHO "/etc/defaultrouter file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	TITLE="Network Configuration Files - (/etc/defaultdomain)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a>"
	EECHO "</h3>"

	table_top
	if [[ -a /etc/defaultdomain ]]; then 
		EECHO "`cat /etc/defaultdomain`" 
	else 
		EECHO "/etc/defaultdomain file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	TITLE="Network Configuration Files - (/etc/nsswitch.conf)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a>"
	EECHO "</h3>"

	table_top
	if [[ -a /etc/nsswitch.conf ]]; then 
		EECHO "`cat /etc/nsswitch.conf`" 
	else 
		EECHO "/etc/nsswitch.conf file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	TITLE="Network Configuration Files - (/etc/resolv.conf)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	table_top	
	if [[ -a /etc/resolv.conf ]]; then 
		EECHO "`cat /etc/resolv.conf`" 
	else 
		EECHO "/etc/resolv.conf file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	TITLE="Network Configuration Files - (/etc/gateways)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a>"
	EECHO "</h3>"

	table_top
	if [[ -a /etc/gateways ]]; then 
		EECHO "`cat /etc/gateways`" 
	else 
		EECHO "/etc/gateways file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	TITLE="Network Configuration Files - (/etc/netmasks)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a>"
	EECHO "</h3>"

	table_top
	if [[ -a /etc/netmasks ]]; then 
		EECHO "`cat /etc/netmasks`" 
	else 
		EECHO "/etc/netmasks file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	TITLE="Network Configuration Files - (/etc/networks)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a>"
	EECHO "</h3>"

	table_top
	if [[ -a /etc/networks ]]; then 
		EECHO "`cat /etc/networks`" 
	else 
		EECHO "/etc/networks file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	TITLE="Network Configuration Files - (/etc/ethers)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a>"
	EECHO "</h3>"

	table_top
	if [[ -a /etc/ethers ]]; then 
		EECHO "`cat /etc/ethers`" 
	else 
		EECHO "/etc/ethers file does not exist" 
	fi
	table_bottom
	EECHO "\n\n"
	let y=y+1

	# Reset Y and increment X variable for document autoformat
	xy_reset
}

function doc_proc {
	TITLE="Processor/Memory and EEPROM"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	let y=y+1

	TITLE="Processor/Memory and EEPROM - (swap -l)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	EECHO "<pre>"
	EECHO "`swap -l`\n\n"
	EECHO "</pre>"
	let y=y+1
	
	TITLE="Processor/Memory and EEPROM - (swap -s)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	EECHO "<pre>"
	EECHO "`swap -s`\n\n"
	EECHO "</pre>"
	let y=y+1

	TITLE="Processor/Memory and EEPROM - (psrinfo -v)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	EECHO "<pre>"
	EECHO "`psrinfo -v`\n\n"
	EECHO "</pre>"
	let y=y+1

        # Reset Y and increment X variable for document autoformat
	xy_reset
}

function doc_key {
	TITLE="Key System Files"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	let y=y+1

	TITLE="Key System Files - (/etc/hosts)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"
	
	table_top
        EECHO "`cat /etc/hosts`\n"
	table_bottom
        let y=y+1

	TITLE="Key System Files - (/etc/passwd)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	table_top
        EECHO "`cat /etc/passwd`\n"
	table_bottom
        let y=y+1


	TITLE="Key System Files - (/etc/group)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	table_top
        EECHO "`cat /etc/group`\n"
	table_bottom
        let y=y+1

	TITLE="Key System Files - (/etc/system)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	table_top
        EECHO "`cat /etc/system`\n"
	table_bottom
        let y=y+1

        # Reset Y and increment X variable for document autoformat
	xy_reset
}

function doc_disk {
	TITLE="Disk and Filesystem Information"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	let y=y+1

	TITLE="Disk Listings"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	EECHO "<pre>"
	iostat -En | awk '$0 ~ /^c/ {printf "Disk: %s ",$1}
        	$0 ~ /Serial/ {printf "Vendor: %s ProdID: %s Serial: %s",$2,$4,$NF}
        	$0 ~ /Size/ {printf " Size: %s \n",$2}' | \
        	sed -e /No:/d | \
#       	sort -u -k 2,2 | \
        	awk '$2 !~ /\// && $2 !~ /No:/ {print $0}'
	EECHO "</pre>"
	EECHO "\n"
        let y=y+1

	TITLE="Format Command Output Listings"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	EECHO "<pre>"
	echo | format | grep -v Searching | grep -v AVAILABLE | grep -v Specify | tail +3
	EECHO "</pre>"
	EECHO "\n"
        let y=y+1

#	for file in `iostat -En | awk '$0 ~ /^c/ {print $1}' | grep -v c0t6d0 | sort`
	for file in `echo | format | grep -v Searching | grep -v AVAILABLE | grep -v Specify | tail +3 |  awk '{print $2}' | sort -ub`
	do
		DISK=`EECHO $file | tr '[:lower:]' '[:upper:]'`
		TITLE="Disk Partition Tables ( $DISK )"
		create_toc
		EECHO "<h3>"
		EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
		EECHO "</h3>"
		
		EECHO "<pre>"
		prtvtoc /dev/rdsk/$file's2'
		EECHO "</pre>"
		EECHO "\n"
        	let y=y+1
	done

	
	TITLE="Files System Information - (/etc/vfstab)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	table_top 
	cat /etc/vfstab
	table_bottom	
	EECHO "\n"
        let y=y+1

	TITLE="Files System Information - (df -k)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"
	
	EECHO "<pre>"
	df -k
	EECHO "</pre>"
	EECHO "\n"
        let y=y+1

	TITLE="Files System Information - (df -n)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"
	
	EECHO "<pre>"
	df -n
	EECHO "</pre>"
	EECHO "\n"
        let y=y+1

	TITLE="Files System Information - (/etc/dfstab)"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"
	
	table_top	
	if [[ -a /etc/dfstab ]]; then 
		EECHO "`cat /etc/dfstab`" 
	else 
		EECHO "/etc/dfstab file does not exist" 
	fi
	table_bottom
	EECHO "\n"
	let y=y+1

        # Reset Y and increment X variable for document autoformat
       	xy_reset 
}

function doc_veritas {
	TITLE="Veritas Information"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	let y=y+1

        pkginfo | grep vxvm
        exit_status=$?
        if [[ $exit_status = 0 ]]; then
		TITLE="Veritas Disk Information (vxdisk list)"
		create_toc
		EECHO "<h3>"
		EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
		EECHO "</h3>"
	
		EECHO "<pre>"
                vxdisk list
		EECHO "</pre>"
                EECHO "\n"
                let y=y+1

		TITLE="Veritas Disk Detail Information (vxdisk -s list)"
		create_toc
		EECHO "<h3>"
		EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
		EECHO "</h3>"
	
		EECHO "<pre>"
                vxdisk -s list
		EECHO "</pre>"
                EECHO "\n"
                let y=y+1

		TITLE="Veritas Volume Manager Print (vxprint -ht)"
		create_toc
		EECHO "<h3>"
		EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
		EECHO "</h3>"
	
		EECHO "<pre>"
                vxprint -ht
		EECHO "</pre>"
                EECHO "\n"
                let y=y+1

                xy_reset
        else
		EECHO "<span class=text>"
                EECHO "Veritas Volume Manager Not Installed"
		EECHO "</span>"

        	# Reset Y and increment X variable for document autoformat
                xy_reset
        fi
}

function doc_packages {
	TITLE="Installed Packages and Patches"
        EECHO "<! -- ****************** $TITLE ****************** -- >"
	create_h2_toc 
	EECHO "<h2>"
	EECHO "<a name='_$x.$y.'>$x. $TITLE</a>" 
	EECHO "</h2>" 
	let y=y+1

	TITLE="Installed Packages"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	EECHO "<pre>"
        pkginfo -x
	EECHO "</pre>"
        EECHO "\n"
        let y=y+1

	TITLE="Installed Patches"
	create_toc
	EECHO "<h3>"
	EECHO "<a name='_$x.$y.'>$x.$y. $TITLE</a> "
	EECHO "</h3>"

	EECHO "<pre>"
        showrev -p | sort
	EECHO "</pre>"
        EECHO "\n"
        let y=y+1

        # Reset Y and increment X variable for document autoformat
        xy_reset

}

function doc_cleanup {
	cat $HEAD_OUTPUT $TOC_OUTPUT $CONTENT_OUTPUT > $FINAL_OUTPUT
	
	rm $HEAD_OUTPUT
	rm $TOC_OUTPUT
	rm $CONTENT_OUTPUT
	EECHO "Created file $FINAL_OUTPUT. Documentation complete."
}

		

html_header >> $HEAD_OUTPUT
html_logo >> $HEAD_OUTPUT
doc_title >> $HEAD_OUTPUT
doc_basic_system >> $CONTENT_OUTPUT
doc_system >> $CONTENT_OUTPUT
doc_network >> $CONTENT_OUTPUT
doc_proc >> $CONTENT_OUTPUT
doc_key >> $CONTENT_OUTPUT
doc_disk >> $CONTENT_OUTPUT
doc_veritas >> $CONTENT_OUTPUT
doc_packages >> $CONTENT_OUTPUT
echo creating final output....
sleep 5
doc_cleanup

