#!/bin/bash
USERID=$(id -u)
TimeStamp=$(date +%F-%H-%M-%S)
ScriptName=$(echo $0 | cut -d "." -f1)
logfile=/tmp/$ScriptName-$TimeStamp.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

echo "enter the mysql root password"
read mysql_root_password

validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is .. $R Failed $N"
        exit 1
    else
        echo -e "$2 is .. $G Success $N"
    fi
}

if [$USERID -ne 0]
then 
    echo "please run the script with the root access"
    exit 1
else
    echo "you are the root user"
fi


dnf list installed nginx &>>$logfile
if [$? -ne 0]
then 
    dnf install nginx -y &>>$logfile
    validate $? "Installing nginx"
else
    echo -e "nginx is already installed $Y Skipping $N"
fi

systemctl enable nginx &>>$logfile
validate $? "Enabling nginx"

systemctl start nginx &>>$logfile
validate $? "Starting nginx"


rm -rf /usr/share/nginx/html/* &>>$logfile
validate $? "Deleting the default files in html directory"


curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$logfile
validate $? "downloading the frontend code"

cd /usr/share/nginx/html &>>$logfile
validate $? "Change path to html directory"

unzip /tmp/frontend.zip &>>$logfile
validate $? "Extracting the frontend code"

cp /home/ec2-user/Expense_Project_ShellScript/expense.conf /etc/nginx/default.d/expense.conf &>>$logfile
validate $? "Copied expense conf"



systemctl restart nginx &>>$logfile
validate $? "Restarting nginx"

echo -e "$G ***** Script Execution is completed *****$N"
