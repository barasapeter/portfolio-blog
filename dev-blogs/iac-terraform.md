# From Manual Server Setup to Infrastructure as Code

## Context

While building my blogging application for my portfolio, I initially deployed the backend the way many solo developers do: manually, step by step, directly on a Linux server.

At the time, this felt reasonable. I wanted to understand the system deeply, avoid abstractions too early, and keep moving. What followed was a long but educational process — one that ultimately pushed me toward **Infrastructure as Code (IaC)** and Terraform.

This post documents:
- The *actual* steps I took to deploy my server
- Why that approach doesn’t scale
- How that experience shaped my decision to learn Terraform
- How I plan to evolve this setup as my skills mature

No buzzwords. Just what happened.

---



## How I Deployed Manually

Before I even got to the command line, I had to log into AWS, navigate through what felt like a thousand clicks to spin up a new instance, configure security groups, and ensure networking was correct. Only after all that groundwork could I start updating and preparing the server itself.

Below are the exact steps I used to deploy the application backend on a fresh Ubuntu server. This is not theoretical — this is the process I followed, debugged, and maintained.

### System Setup

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3.12-venv
```







### Python Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### Build Dependencies

```bash
sudo apt install libpq-dev python3-dev build-essential
```

### Application Dependencies

```bash
pip3 install -r requirements.txt
```

### Environment Configuration

```bash
cat > .env << 'EOF'
<FILE CONTENTS>
EOF
```

This step alone required careful coordination between:

* Environment variables
* Database credentials
* Application configuration

Any mismatch meant runtime failures.

---

## Database Setup (PostgreSQL)

```bash
sudo apt install postgresql postgresql-contrib -y
sudo -i -u postgres psql
```

```sql
CREATE DATABASE cardlabs;
```

### Authentication Issues (Real Failure Case)

While testing Gunicorn, I hit database authentication failures. The fix:

```bash
sudo -u postgres psql
```

```sql
ALTER USER postgres PASSWORD '....PWD...';
\q
```

This worked — but it was manual, stateful, and undocumented outside my own notes.

---

## Native Dependency Issues

The application required OpenCV-related libraries that were missing on the server:

```bash
sudo apt install -y libgl1 libglib2.0-0
sudo apt install -y libsm6 libxrender1 libxext6
```

This wasn’t obvious from the app code itself and only surfaced at runtime.

---

## Application Server (Gunicorn)

Testing manually:

```bash
gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000
```

Failures here often traced back to:

* Database auth
* Missing environment variables
* Incorrect working directories

Each issue required SSHing back in and debugging live.

---

## Systemd Service Configuration

To keep the app running:

```bash
sudo nano /etc/systemd/system/fastapi.service
```

```ini
[Unit]
Description=FastAPI app
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/cardlabsv3.0
ExecStart=/home/ubuntu/cardlabsv3.0/venv/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start fastapi
sudo systemctl enable fastapi
sudo systemctl status fastapi
```

This worked — but any path change, user change, or deployment change meant editing files directly on the server.

---

## Reverse Proxy and HTTPS

### Nginx Setup

```bash
sudo apt install nginx -y
sudo nano /etc/nginx/sites-available/fastapi
```

```nginx
server {
    server_name cardlabs-sandbox.duckdns.org www.cardlabs-sandbox.duckdns.org;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx
```

### HTTPS with Let’s Encrypt

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d cardlabs-sandbox.duckdns.org
sudo systemctl status certbot.timer
```

---

## What This Process Taught Me

This setup *works*. The application runs, traffic flows, HTTPS is enabled.

But it’s fragile.

### Problems I Hit (or Will Hit Again)

* No reproducibility
* No version control for infrastructure
* Manual recovery after failure
* Environment drift over time
* High cognitive load to repeat this on another server

If I needed:

* A staging environment
* A second region
* A clean rebuild
* Another developer onboarded

…I would be re-running this entire checklist from memory.

---

## Why This Pushed Me Toward Terraform

After going through this process, Infrastructure as Code stopped being abstract.

Terraform solves problems I *personally experienced*:

* Server creation is declarative
* Networking is documented in code
* Infrastructure can be recreated from scratch
* Changes are reviewed before being applied
* Environments can be cloned safely

Instead of remembering steps, I can **encode decisions**.

---










## My Very First Terraform Experience

Once I decided to try Terraform, I didn’t dive straight into AWS or complex infrastructure. I started small — on **Windows**, with a local provider — just to understand **how Terraform tracks resources and applies changes**.

Here’s how it went:

1. **Downloaded Terraform** and added it to the system PATH. Verified the installation:

```powershell
C:\Users\barasa> terraform -version
Terraform v1.14.4
on windows_amd64
```

2. **Created a working directory** for experimentation:

```powershell
C:\Users\barasa\Desktop> mkdir tf-test
C:\Users\barasa\Desktop> cd tf-test
```

3. **Initialized Terraform**:

```powershell
C:\Users\barasa\Desktop\tf-test> terraform init
Terraform initialized in an empty directory!
```

Later, I installed the `local` provider to manage local files:

```powershell
C:\Users\barasa\Desktop\tf-test> terraform init
Initializing provider plugins...
- Installing hashicorp/local v2.6.2...
Terraform has been successfully initialized!
```

4. **Created a simple Terraform configuration** to generate a file:

```hcl
resource "local_file" "hello" {
  content  = "hello, terraform is interesting!"
  filename = "hello.txt"
}
```

5. **Planned and applied the changes**:

```powershell
C:\Users\barasa\Desktop\tf-test> terraform plan
Plan: 1 to add, 0 to change, 0 to destroy.

C:\Users\barasa\Desktop\tf-test> terraform apply
Do you want to perform these actions? Enter a value: yes
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**Result:** A file `hello.txt` was created with the content `"hello, terraform is interesting!"`.

This **tiny experiment** taught me the core Terraform workflow:

* `terraform init` — sets up the environment
* `terraform plan` — previews changes before touching anything
* `terraform apply` — makes the changes happen
* State management is automatic and trackable

Starting local gave me confidence before applying Terraform to real servers in AWS.














---

## How This Will Evolve

As my Terraform skills grow, this project will transition to:

* Terraform-managed servers
* Versioned infrastructure
* Environment separation (dev / staging / prod)
* Automated provisioning
* Reduced manual SSH work

Eventually, the painful checklist above becomes:

* A repository
* A plan
* A repeatable outcome

---

## Why I’m Documenting This

This blog isn’t about pretending everything was smooth.

It’s about showing:

* How I approach real problems
* How I learn from friction
* How I evolve systems over time
* How tooling choices are earned, not adopted blindly

Terraform isn’t magic — it’s the next logical step.

And now that I’ve felt the pain, I understand why it exists.

---

*This post documents the transition from manual operations to Infrastructure as Code. The implementation will evolve — the lessons stay.*
