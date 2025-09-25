USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
START_TIME=$(date +%s)

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

dnf module disable redis -y &>>$LOG_FILE
dnf module enable redis:7 -y &>>$LOG_FILE

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "installed"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c /protected-mode no/' /etc/redis/redis.conf
VALIDATE $? "Allowing Remote connections to Redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling Redis"
systemctl start redis &>>$LOG_FILE
VALIDATE $? "Starting Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
