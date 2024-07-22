#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "Please enter DB password:"
read  mysql_root_password

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi                                 # Ikkada daka manam normal mundu scripts lo echavi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs:20 version"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing nodejs"

id expense &>>$LOGFILE      # Is this idempotency ? or not? normal ga oka user create ayaka malli same name tho user ni create
if [ $? -ne 0 ]                   # chesthe exist status (echo $?) 1 error chupisthadhi so anduku if
then                              # else statement use chesam.first time aithey if statement loki 
    useradd expense &>>$LOGFILE   # valtundhi expense ani user add avuthundhi ledha else loke velli already created ani vasthundhi
    VALIDATE $? "Creating expense user"
else
    echo -e "Expense user already created...$Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGFILE        # Is this idempotency? or not. no because mkdir (make directory) app ani create chestham malli same name tho create cheyagalama ? no  
VALIDATE $? "Creating app directory"  #so kabati -p isthey already vuntey silent avuthundhi error emi ivadhu leka pothey create chesthundhi

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading backend code"

cd /app
rm -rf /app/*           #Ikkada ee command yenduku ichamu ante first time app ane folder lo backend.zip 
unzip /tmp/backend.zip &>>$LOGFILE  # unzip chesaka malli dene second time run chese tappudu question
VALIDATE $? "Extracted backend code" # chesthundhi do you want to replace ani? akkada struck avutundhi so anduku vunnadhi delete
                                     # chesi then kotha app folder ni create cheyi ani rm -rf/app/* command icham
npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies"

#check your repo and path
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE #In expense document manam 'vim' ni use chesi
VALIDATE $? "Copied backend service"                             #chesam description ni but vim script lo work avadhu so manam ikkada
                                                # 'backend.service ani' file create chesi andulo description ni copy chesi aaa file path ikkada icham
systemctl daemon-reload &>>$LOGFILE             # if you type pwd in server it shows /home/ec2-user then /expense-shell/backend.service
VALIDATE $? "Daemon Reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing MySQL Client"
                                        #db.sudheerdevopsengineer.online anedhi mana mysql database ipaddress
mysql -h db.sudheerdevopsengineer.online -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Schema loading"         #ikkada datbase schema lo already schema lo data exist ayithe cheyadhu lekapothey create chesthundhi 
                                      # so malli new data vasthe data already exists ani chepthundhi
systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting Backend"