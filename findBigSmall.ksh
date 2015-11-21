#!/usr/bin/ksh
# User defined function in awk
# This script will show the way of using user 
#  defined functions in awk script
# The program find both the maximum and minimum number 
#  from the defined array
# The PRE condition is that the number of elements 
#  should be a power of 2
#  e.g. 2,4,8,16,32....
# It also checks the PRE condition - power2() function
#  here for testing the number of elements taken are 32.

awk '
function power2(num, flag)
{
flag=0
n=num
while(n > 1)
{
  m=n
  if ( m%2 == 0 )
  {
    n=n/2
  }
  else
  {
    flag=1
    break
  }
}
return flag
}

function findsmall(q, num)
{
while (num>1)
{
num=num/2
for(i=1;i<=num;i++)
{
  if (q[2*i] > q[2*i-1])
   {
      q[i]=q[2*i-1]
   }
  else
   {
      q[i]=q[2*i]
   }
}
}
return q[1]
}


BEGIN {
number=32
k=number
flag=0
small=0
p[1]=199; p[2]=-3; p[3]=92; p[4]=14; p[5]=1; p[6]=56; p[7]=37; p[8]=8;
p[9]=17; p[10]=9; p[11]=92; p[12]=14; p[13]=97; p[14]=56; p[15]=100; p[16]=2;
p[17]=19; p[18]=39; p[19]=92; p[20]=14; p[21]=15; p[22]=56; p[23]=37; p[24]=83;
p[25]=17; p[26]=90; p[27]=92; p[28]=14; p[29]=97; p[30]=56; p[31]=100; p[32]=0;

RC=power2(number, flag)

if(RC == 0)
  print number" is a power of 2"
else
  print number" is not a power of 2"

#find the maximum number
while (k>1)
{
k=k/2

for(i=1;i<=k;i++)
{
  if (p[2*i] > p[2*i-1])
  {
    p[i]=p[2*i]
    if (small == 0 ) q[i]=p[2*i-1]
  }
  else
  {
    p[i]=p[2*i-1]
    if (small == 0 ) q[i]=p[2*i]
  }
}
small=1
#find the minimum number
findsmall(q, k)
}

print "MAXIMUM NUMBER IS - ", p[1]
print "MINIMUM NUMBER IS - ", q[1]
}'


###
### This script is submitted to BigAdmin by a user
### of the BigAdmin community.
### Sun Microsystems, Inc. is not responsible for the
### contents or the code enclosed.
###


