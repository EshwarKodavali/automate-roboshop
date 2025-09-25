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
        echo -e "$2 ... $G FAILURE $N"
    else
        echo -e "$2 ... $G SUCCESS $N"
    
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installed"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "User established"
else
    echo -e "user already exists $Y SKIPPING $N"
fi

mkdir -p /app 


curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE

cd /app
VALIDATE $? "Moving to directory"

rm -rf /app/*
VALIDATE $? "removing everthing in that directory"


unzip /tmp/user.zip &>>$LOG_FILE

npm install &>>$LOG_FILE
VALIDATE $? "npm installed"

cp $HOME_PATH/user.service /etc/systemd/system/user.service

systemctl daemon-reload

systemctl enable user 
systemctl start user
VALIDATE $? "restarted"
END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"

