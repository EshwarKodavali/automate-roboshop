#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER

echo "Script started executed at: $(date)"

if [ $USER_ID -ne 0 ]; then
    echo "please use root access"
    exit 1
else
    echo "It is a root access"
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N"
    else
        echo -e "$2 ... $R SUCCESS $N"
    
    fi
}

cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "imported to repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installed mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabled mongodb"

systemctl start mongod
VALIDATE $? "started mongodb" 

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted mongodb"