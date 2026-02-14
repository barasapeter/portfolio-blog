# From Manual Deployments to Secure, Production-Grade CI/CD

When I first deployed my FastAPI blogging platform, it worked.

But the deployment process didn’t.

I was manually:
- SSH-ing into EC2
- Pulling code
- Reinstalling dependencies
- Restarting services
- Reloading nginx

It worked — but it wasn’t engineering. It was procedure.

This post documents how I transformed that workflow into a secure, automated, production-ready deployment pipeline using:

- Terraform (Infrastructure as Code)
- GitHub Actions (CI/CD)
- AWS IAM with OIDC federation (zero static credentials)
- AWS Systems Manager (SSM) Run Command (no SSH)

More importantly, this documents the architectural decisions behind it.

---

# What Actually Changed?

The shift was not about adding GitHub Actions.

It was about moving across maturity levels.

## Stage 0 – Manual Ops

Deployment depended on:
- My memory
- My SSH access
- My correctness
- My availability

Failure modes:
- Forgot a command
- Installed wrong dependencies
- Restarted wrong service
- Broke production silently

This is fragile and non-reproducible.

---

## Stage 1 – Scripted Deployment

I created `bootstrap.sh` and `deploy.sh`.

Now deployment steps were:

```

sudo bash deploy.sh

```

Better — but still manual.

Still SSH-based.
Still human-triggered.

---

## Stage 2 – Infrastructure as Code

Using Terraform, I provisioned:

- EC2 instance
- Security group
- IAM roles
- Instance profile
- Elastic IP association
- User data bootstrap

Now infrastructure was:

```

terraform apply

```

No AWS console.
No “thousand clicks”.

Reproducible infrastructure is the foundation of DevOps maturity.

---

## Stage 3 – Automated CI/CD with Zero Secrets

The final transformation:

```

git push origin main

```

Triggers:

1. GitHub Actions
2. OIDC-based role assumption
3. SSM Run Command
4. EC2 executes deploy.sh
5. systemd restarts service
6. Deployment logs returned to GitHub

No SSH.
No stored AWS keys.
No manual intervention.

This is operational maturity.

---

# Why I Chose SSM Instead of SSH

There were multiple options:

| Approach | Problem |
|----------|----------|
| SSH from GitHub | Requires storing private key |
| AWS access keys in GitHub secrets | Long-lived credentials (bad practice) |
| Self-hosted runner on EC2 | Operational overhead |
| ECS/Docker | Overkill for this stage |

SSM Run Command was superior because:

- No open SSH port required
- No private key storage
- IAM-based access control
- Fully auditable execution
- Works with temporary credentials

This decision reduced attack surface significantly.

---

# Deep Dive: IAM + OIDC Security Architecture

This was the most educational part of the project.

## The Goal

Allow GitHub Actions to deploy to AWS **without storing AWS credentials**.

The solution: OIDC federation.

---

## How OIDC Works in This Context

Instead of storing:

```

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

```

GitHub:
- Generates a short-lived OIDC token
- Sends it to AWS
- AWS verifies identity via trust policy
- AWS issues temporary credentials
- Token expires automatically

There are:
- No long-lived credentials
- No secrets in GitHub
- No credential rotation problem

This is modern cloud security.

---

# Step 1 – Create AWS OIDC Provider

IAM → Identity Providers:

```

Provider URL: [https://token.actions.githubusercontent.com](https://token.actions.githubusercontent.com)
Audience: sts.amazonaws.com

```

Without this, GitHub cannot federate with AWS.

Initial failure I encountered:

```

No OpenIDConnect provider found

```

Fix: create provider properly.

---

# Step 2 – Create a Dedicated GitHub Deploy Role

Important security principle:

Do NOT reuse EC2 instance roles for GitHub.

Instead:

Create a dedicated IAM role:

```

portfolio-github-deploy-role

````

---

## Trust Policy (Critical Security Layer)

This determines **who can assume the role**.

Bad practice (too broad):

```json
"token.actions.githubusercontent.com:sub":
"repo:barasapeter/MyPortfolioNPersonalBlog:*"
````

AWS warned:

> Wildcard allows more sources than intended.

Correct production version:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated":
    "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub":
      "repo:barasapeter/MyPortfolioNPersonalBlog:ref:refs/heads/main"
    }
  }
}
```

Now:

* Only my repo
* Only main branch
* Can deploy

This prevents:

* Forked repo abuse
* Pull request injection
* Branch-based production deploys

This is least-privilege trust.

---

# Step 3 – Permission Policy

Trust policy ≠ permission policy.

I hit this error:

```
AccessDenied: not authorized to perform ssm:SendCommand
```

Meaning:
The role could be assumed — but it couldn’t do anything.

Fix:

```json
{
  "Effect": "Allow",
  "Action": [
    "ssm:SendCommand",
    "ssm:GetCommandInvocation"
  ],
  "Resource": "*"
}
```

Best practice improvement:

Restrict to specific instance ARN:

```json
"Resource":
"arn:aws:ec2:us-east-1:ACCOUNT_ID:instance/i-xxxxxxxx"
```

Even better:

Target instances by tag:

```
--targets Key=tag:Name,Values=portfolio-prod-machine
```

That makes deployment resilient to instance replacement.

---

# Step 4 – EC2 Must Also Have SSM Permissions

Separate concern:

EC2 needs:

```
AmazonSSMManagedInstanceCore
```

Attached via instance profile.

Without it:

* Instance does not register with SSM
* RunCommand fails silently

This separation of concerns is critical:

* GitHub role → permission to send commands
* EC2 role → permission to receive commands

---

# GitHub Workflow Design

My GitHub Actions pipeline:

1. Configure AWS credentials (OIDC)
2. Send SSM command
3. Capture CommandId
4. Wait for completion
5. Fetch stdout/stderr
6. Fail pipeline if deployment fails

This ensures:

* Deployment is verified
* CI fails if deploy fails
* Logs are centralized

No “fire and forget”.

---

# Terraform Best Practice Integration

To productionize this fully, Terraform should manage:

* `aws_iam_openid_connect_provider`
* GitHub deploy role
* Trust policy conditions
* Inline SSM permission policy
* EC2 instance profile
* Security groups
* Tag-based SSM targeting

Infrastructure and deployment pipeline become code.

No manual IAM console edits.

---

# DevOps Maturity Indicators Achieved

* Infrastructure reproducible via Terraform
* No static AWS credentials
* No SSH dependency
* Deployment triggered by git push
* Least privilege IAM
* Branch-restricted production deploys
* Auditable deployment logs
* Idempotent deployment script
* Zero manual AWS console interaction

That is production-ready CI/CD.

---

# What This Demonstrates

This project is not just a blogging app.

It demonstrates:

* Secure cloud authentication patterns
* Federated identity architecture
* IAM trust and permission separation
* Infrastructure as Code discipline
* CI/CD automation
* Least privilege security design
* Operational maturity

---

# Final Reflection

Anyone can deploy an app.

But designing:

* Zero-secret CI/CD
* Branch-restricted IAM trust
* Tag-based SSM targeting
* Fully automated reproducible infrastructure
