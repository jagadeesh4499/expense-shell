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
CHECK_ROOT
echo "Script started exceuting at : $(date)" | tee -a $LOG_FILE
dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Mysql installation"
systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabled Mysql"
systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Started Mysql"
#In future use DNS (mysql.jagadeesh.online) in the place of IP Address
mysql -h 172.31.45.29 -u root -p<password> -e 'show databases;' &>>LOG_FILE
if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
    VALIDATE $? "Setting up root Password"
else
    echo -e "MysQl root is  already setup.....$Y SKIPPING $N" | tee -a $LOG_FILE
fi