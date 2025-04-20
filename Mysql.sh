#!/bin/bash
USERID=$(id -u)
TimeStamp=$(date +%F-%H-%M-%S)
ScriptName=$(echo $0 | cut -d "." -f1)
logfile=/tmp/$ScriptName-$TimeStamp.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "Enter the root password"
read Root_Password

validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is ... $R Failed $N"
        exit 1
    else 
        echo -e "$2 is ... $G Success $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "please run the script with the root access"
    exit 1
else
    echo "You are the root user"
fi


dnf list installed mysql &>>$logfile
if [ $? -ne 0 ]
then
    dnf install mysql-server -y &>>$logfile
    validate $? "installing mysql server"
else
    echo -e "mysql is already installed $Y skipping $N"
fi



systemctl enable mysqld &>>$logfile
validate $? "Enable mysql server"

systemctl start mysqld &>>$logfile
validate $? "Start mysql server"


mysql -h db.rajasekhar.store -uroot -p${Root_Password} -e 'show databases;' &>>$logfile
if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass ${Root_Password} &>>$logfile
    validate $? "Setting the root password for mysql"
else
    echo -e "root password is already Configured $Y skipping $N"
fi

echo -e "$R ***** $G Script Execution is completed $R*****$N"