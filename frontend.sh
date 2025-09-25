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

dnf module disable nginx -y &>>$LOG_FILE
dnf module enable nginx:1.24 -y &>>$LOG_FILE
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx  &>>$LOG_FILE
systemctl start nginx 
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* 
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

rm -rf /etc/nginx/nginx.conf
cp $HOME_PATH/frontend.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying frontend.conf"

systemctl restart nginx 
VALIDATE $? "Restarting Nginx"