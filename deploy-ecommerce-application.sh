function print_color(){

	case $1 in
		"green") CLOR="\033[0;32m" ;;
		"red") COLOR="\033[0;31m" ;;
		"*") COLOR="\033[0m" ;;
	esac

	echo -e "${COLOR} $2 ${NC}"
}


#-------------Database Config----------------------
#Install & Configure Firewalld
print_color "green" "Installing firewalld..."
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

is_firewalld_active=$(systemctl is-active firewalld)
if [ $is_firewalld_active = "active"
then
	print_color "green" "Firewalld Service is active"
else
	print_color "red" "FirewallD Service is not active"
	exit 1
fi

#Install and configure Database
print_color "green" "Installing MariaDB"
sudo yum install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb

#Add FirewallD rules for database
print_color "green" "Adding Firewall rules for DB..."
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

# Configure Database
print_color "green" "Configure DB..."
cat > configure-db.sql <<-EOF
MariaDB > CREATE DATABASE ecomdb;
MariaDB > CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
MariaDB > GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
MariaDB > FLUSH PRIVILEGES;

EOF

sudo mysql < configure-db.sql

# Loading Inventory data into Database
print_color "green" "Loading inventory data into DB..."
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF



sudo mysql < db-load-script.sql
#-------------------Web Server Configuration-----------------

#Install and configure Web Server
print_color "green" "COnfigure Web Server.."
sudo yum install -y httpd php php-mysql

# Configure Firewall rules for Web Server
print_color "green" "Configure FirewallD rules for Web server..."
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload


sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

# Start and enable httpd service
print_color "green" "Starting web server..."
sudo service http start
sudo systemctl enable httpd

# Install GIT and  download source code repo
print_color "green" "Cloning GIT Repo.."
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

# Replace database IP with localhost
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

print_color "green" "All set.."
