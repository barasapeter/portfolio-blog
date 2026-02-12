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
postgres=# ALTER USER postgres PASSWORD '1988';

- exit postgres shell
- Install a missing CV2 libraries
$ sudo apt install -y libgl1 libglib2.0-0
$ sudo apt install -y libsm6 libxrender1 libxext6

- Test gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000
$ gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000


