#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
START_TIME=$(date +%s)
HOME_PATH=$PWD
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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "User established"
else
    echo -e "user already exists $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "created app folder"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "Getting the URL"

cd /app
VALIDATE $? "Moving to directory"

rm -rf /app/*
VALIDATE $? "removing everthing in that directory"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"

pip3 install -r requirements.txt &>>$LOG_FILE

cp $HOME_PATH/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload

systemctl enable payment &>>$LOG_FILE
systemctl start payment
VALIDATE $? "started"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"