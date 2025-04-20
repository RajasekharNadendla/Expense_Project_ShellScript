#!/bin/bash
USERID=$(id -u)
TimeStamp=$(date %F-%H-%M-%S)
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

dnf module disable nodejs -y &>>$logfile
validate $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$logfile
validate $? "Enabling nodejs:20 version"

dnf list installed nodejs &>>$logfile
if [$? -ne 0]
then
    dnf install nodejs -y &>>$logfile
    validate $? "Installing nodejs"
else 
    echo -e "nodejs is already installed $Y skipping $N"
fi

id expense &>>$logfile
if [$? -ne 0]
then
    useradd expense &>>$logfile
    validate $? "creating the expense user"
else
    echo -e "Expense user is already created $Y Skipping $N"
fi

mkdir -p /app &>>$logfile
validate $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$logfile
validate $? "Downloading backend code"

cd /app &>>$logfile
validate $? "change directory to app"

rm -rf /app/* &>>$logfile   #to make idempotent we delete the content in this folder as we need to run the script more than one time 
validate $? "deleting the files inside app directory"

cd /app &>>$logfile
validate $? "change directory to app"

unzip /tmp/backend.zip &>>$logfile
validate $? "Extracted backend code"

npm install &>>$logfile
validate $? "install the dependencies of the backend"

cp /home/ec2-user/Expense_Project_ShellScript/backend.service /etc/systemd/system/backend.service &>>$logfile
validate $? "copying the configarations to backend.service"

systemctl daemon-reload &>>$logfile
validate $? "Daemon Reload"

systemctl start backend &>>$logfile
validate $? "Starting backend"

systemctl enable backend &>>$logfile
validate $? "Enabling backend"

dnf list installed mysql &>>$logfile
if [$? -ne 0]
then 
    dnf install mysql -y &>>$logfile
    validate $? "installing mysql client"
else
    echo -e "mysql is already installed $Y Skipping $N"
fi

mysql -h db.rajasekhar.store -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$logfile
validate $? "Schema loading"

systemctl restart backend &>>$logfile
validate $? "restarting the backend"

echo -e "$G ***** Script Execution is completed *****$N"
