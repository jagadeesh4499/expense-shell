#!/bin/bash
LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0|cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
USERID=$(id -u)
CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}
VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is.....$R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is.....$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}
echo "Script started exceuting at : $(date)" | tee -a $LOG_FILE
CHECK_ROOT
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nosejs 20" 
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "NodeJS installation"
id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    echo -e "expense user doesn't exists.....$G Going to create $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "expense user creation"
else
    echo -e "expense user is already exists....$Y SKIPPING $N"
fi
mkdir -p /app
VALIDATE $? "Creating /app folder"
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading application code"
cd /app
rm -rf /app/*   #removing the existing code
unzip /tmp/backend.zip &>>LOG_FILE
VALIDATE $? "Extracting backend code"
npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service
#load the data before running backend service
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "MySql Client Installation"
#In future use DNS (mysql.jagadeesh.online) in the place of IP Address
mysql -h 172.31.33.246 -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema Loading"
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"
systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabling backend"
systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarting backend"