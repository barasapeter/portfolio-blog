- Logged into AWS console
- create an ec2 instance:
    - set Name and tags  Info Name: portfolio-prod-machine
    - Application and OS Images (Amazon Machine Image): Ubuntu
    - Amazon Machine Image (AMI): Ubuntu Server 24.04 LTS (HVM), SSD volume type
    - Instance type: t3.micro
    - no key pair
    - Network settings:
        - Firewall (Security Groups):
            - allow ssh traffic from: Anywhere (0.0.0.0/0)
            - Allow HTTPS traffic from the internet
            - Allow HTTP traffic from the internet
    - storage:
        - 8 Gib GP3 Root volume, 3000 IOPS, Not encrypted
- launnched instance

- connected to the instance
run:
$ sudo apt update
$ sudo apt upgrade

- note: sudo apt upgrade asks for a prompt:
```
After this operation, 776 kB of additional disk space will be used.
Do you want to continue? [Y/n] 
```
- type Y and hit enter

- Install ensurepip

$ sudo apt install -y python3.12-venv

- clone the repository
$ git clone https://github.com/barasapeter/MyPortfolioNPersonalBlog.git

- navigate to the directory
$ cd MyPortfolioNPersonalBlog

- Create a virtual environment

$ python3 -m venv venv

- Activate the virtual environment

$ source venv/bin/activate

- Install PostgreSQL development libraries (command may require prompt input, Y/N)

$ sudo apt install libpq-dev python3-dev build-essential

- note: this command requires confirmation:
```
After this operation, 317 MB of additional disk space will be used.
Do you want to continue? [Y/n]
```

- Type "Y" and hit Enter
- Postgres installs

- Install requirements.txt

$ pip3 install -r requirements.txt

- Create .env file
$ cat > .env << 'EOF'
<FILE CONTENTS>
EOF








- Set up database (PostgresSQL)
- Install PostgresSQL
$ sudo apt install postgresql postgresql-contrib -y
- Log in as postgresql
$ sudo -i -u postgres psql
- Create database
postgres=# CREATE DATABASE portfolio_blog;

- exit postgres shell

- Reset the postgres password
$ sudo -u postgres psql

- Youll now be inside the PostgreSQL shell (postgres=#).
- Then run:

postgres=# \password postgres

- Enter new password for user "postgres": 
- Enter it again: 



- exit postgres shell
- Install a missing CV2 libraries
$ sudo apt install -y libgl1 libglib2.0-0
$ sudo apt install -y libsm6 libxrender1 libxext6


- Test gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000
$ gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000

- at this point, gunicorn should run and shut down autonomously




- Set up a Systemd service (so app runs in background)
$ sudo nano /etc/systemd/system/fastapi.service
- nano opens. paste:
```
[Unit]
Description=FastAPI app
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/MyPortfolioNPersonalBlog
ExecStart=/home/ubuntu/MyPortfolioNPersonalBlog/venv/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
```
- save and exit

Note: (if there is a better way of creating this file you are free to do so. expecially in a bash script)

- Start & enable:
$ sudo systemctl daemon-reload
$ sudo systemctl start fastapi
$ sudo systemctl enable fastapi
$ sudo systemctl status fastapi

- the service should be running






- Set up Nginx as a reverse proxy
- install nginx

$ sudo apt install nginx -y

- Create config:
$ sudo nano /etc/nginx/sites-available/fastapi

- paste:
```
server {
    server_name cardlabs.cloud www.cardlabs.cloud;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```




- Enable site
$ sudo ln -s /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled
$ sudo nginx -t
$ sudo systemctl restart nginx





- Secure with HTTPS (Lets Encrypt)
$ sudo apt install certbot python3-certbot-nginx -y

- point your instance IP to the DNS provider

- Generate SSL
$ sudo certbot --nginx -d cardlabs.cloud -d cardlabs.cloud

- You will see:
```
(venv) ubuntu@ip-172-31-27-108:~/MyPortfolioNPersonalBlog$ sudo certbot --nginx -d cardlabs.cloud -d cardlabs.cloud
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Enter email address (used for urgent renewal and security notices)
(Enter 'c' to cancel): 
```

- Type email address: barasapeter52@gmail.com
- press enter to confirm


- Add Auto-renew check
$ sudo systemctl status certbot.timer

