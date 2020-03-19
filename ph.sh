:
# (#) phone v1.0  Maintain telephone database Author: Russ Sage


BASE="$HOME/bin/.phone.list"
if [ $# -gt 0 ]
	then 
		grep -y "$1" $BASE | more
		exit 0
fi
clear
while :
do 
	echo "



				PHONE MENU
				----------

		  	   (A)dd name to list
			  
			   (D)elete name from list

			   (E)dit list

			   (S)earch for name in list

			   (V)iew complete list

			   <cr> - Exit Porgram


		       
		       Press a, d, e, s, v or <cr>: \c"
read RSP

	case $RSP in
	"")      
		clear
		exit 0
		;;
	a|A)	clear
		echo "\nEnter name to add (<cr> to exit): \c"
		read NAME
		if [ "$NAME" = "" ]
		  then clear
		       continue
		fi
		echo "Enter Company : \c"
		read COMP
		echo "Enter Work Number: \c"
		read WNUM
		echo "$NAME\t$COMP\t\t\t$WNUM" >> $BASE
		echo "Enter Title and Description: \c"
		read DESC
		echo "Enter Fax Number: \c"
		read NUM
		echo "$NAME\t$DESC\t\t$NUM" >> $BASE
		echo "Enter Address Line 1: \c"
		read ADD1
		echo "City, State, Zip: \c"
		read CSZ
		echo "$NAME\t$ADD1\t\t$CSZ" >> $BASE
		echo "Enter Comment: \c" 
		read COMM
		echo "Enter Home Number: \c"
		read HNUM
		echo "$NAME\t$COMM\t\t\t$HNUM" >> $BASE
		echo "Enter Comment: \c"
		read COMM1
		echo "$NAME\t$COMM1" >> $BASE
		sort -o $BASE.tmp $BASE
		mv $BASE.tmp $BASE
		;;
	d|D)	echo "\nEnter name to delete (<cr> to exit): \c"
		read NAME
		if [ "$NAME" = "" ]
		then continue
		fi
		sed -e "/$NAME/d" $BASE > $BASE.new
		mv $BASE.new $BASE
		;;
	e|E)	vi $BASE
		;;
	s|S)	clear
		echo "\nEnter name to search: \c"
		read NAME
		echo ""
		echo ""
		grep -y "$NAME" $BASE | more
		echo "\nhit <cr>\c"
		read RSP
		;;
	v|V)	echo "\n\tPhone List\n\t--------------" &
		more $BASE
		echo "\nhit <cr>\c"
		read RSP
		;;
	*)	echo "Not a vilid command"
		;;
	esac
clear
done
