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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "User established"
else
    echo "user already exists $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "created app folder"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Getting the URL"

cd /app
VALIDATE $? "Moving to directory"

rm -rf /app*
VALIDATE $? "removing everthing in that directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping the file"

npm install &>>$LOG_FILE
VALIDATE $? "installing NPM"

cp $HOME_PATH/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "created catlogue service"

systemctl daemon-reload
VALIDATE $? "daemon reloaded"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enable catalogue"

cp $HOME_PATH/mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "created mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "intalled mongodb"

INDEX=$(mongosh mongodb.eshwar.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -le 0 ]; then
    mongosh --host mongodb.eshwar.fun </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Connected to mongodb"
else
    echo "Catalogue schema already exists"
fi

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"
