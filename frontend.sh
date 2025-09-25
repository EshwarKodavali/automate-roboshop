#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
HOME_PATH=$PWD

LOG_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER
echo "Script started executed at: $(date)"

if [ $USER_ID -ne 0 ]; then
    echo -e "$R This is not a Root USER $N"
    exit 1
else
    echo -e "This is a root user u can $G PROCEED $N"
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R failure STOP.. $N"
        exit 1
    else
        echo -e "$2 is $G Success you can proceed.. $N"
    fi
}

dnf module list nginx &>>$LOG_FILE

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disable nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enable nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "install nginx"

systemctl enable nginx
systemctl start nginx 

rm -rf /usr/share/nginx/html/*
VALIDATE $? "removed"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "copied code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipped"

cp $HOME_PATH/frontend.repo /etc/nginx/nginx.conf

systemctl restart nginx
VALIDATE $? "started nginx"