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

dnf install maven -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "User established"
else
    echo -e "user already exists $Y SKIPPING $N"
fi

mkdir -p /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Getting the URL"

cd /app
VALIDATE $? "Moving to directory"

rm -rf /app/*
VALIDATE $? "removing everthing in that directory"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip shipping"

mvn clean package  &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar

cp $HOME_PATH/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "created service"

systemctl daemon-reload

systemctl enable shipping 


dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "install mysql"

mysql -h mysql.eshwar.fun -uroot -pRoboShop@1 -e 'cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h mysql.eshwar.fun -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.eshwar.fun -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.eshwar.fun -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping
VALIDATE $? "restarted"
