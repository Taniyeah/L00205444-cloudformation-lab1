# CloudFormation Lab 1

**Student Name:** Taniya Offergeld
**Student Number:** L00205444
**Institution:** ATU Donegal
**Course:** PGDip in Computing in DevOps, IaC for DevOps Pipelines
**Lecturer:** R.G. Lennon
**Assignment:** CloudFormation Lab 

## 1. Introduction

In Part 1a I build a static website with CloudFormation. My L-number and name show as the header, the page is stored in an S3 bucket. This serves as a public facing web service hosts. In Part 1b I build a second setup with a web tier, an application tier and a database tier.

I keep each version as simple as possible and follow a tutorial first. Then I improve it one change at a time, each in its own branch and pull request. This README is part of that. I update it in pull requests as the work moves on, so the history shows my progress.

## 2. Status

| Part | Status |
|---|---|
| 1a, static website on S3 | Done, deployed and tested |
| 1a, deploy script | Done |
| 1a, destroy script | Done, tested with a real delete and a rebuild |
| 1b, three tier architecture | Done, deployed and tested |
| 1b, improvements | Planned (tags, deploy script, destroy script) |
| README write up | In progress |

### README versions
| Version | Branch | What it covers |
|---|---|---|
| v1 | docs/readme-v1-part-1a | Part 1a basics, deploy script, declarations so far |
| v1.1 | docs/readme-v1.1-formatting | Formatting fix |
| v2 | docs/readme-v2-part-1a-final | Part 1a finished, destroy script, LLM use |
| v3 | docs/readme-v3-three-tier | Part 1b three tier architecture |
| v4 | docs/readme-v4-final | Best practice table, full prompt list, final screenshots (planned) |

## 3. Repository structure

```
.
├── README.md                          this write up
├── CODE_OF_CONDUCT.md
├── LICENSE
├── src/website/index.html             the static page (L-number and name as header)
├── scripts/
│   ├── deploy.sh                      deploys the stack and uploads the page
│   └── destroy.sh                     empties the bucket and deletes the stack
├── templates/
│   ├── s3-website/s3-website.yaml     Part 1a, website hosted from S3 (main version)
│   ├── website/static-website.yaml    Part 1a, first attempt with EC2 and Apache
│   └── three-tier/three-tier.yaml     Part 1b, web, app and database tiers
└── docs/images/                       screenshots
```

## 4. Part 1a: static website

### Version 1: the first attempt with EC2
My first template (`templates/website/static-website.yaml`) creates a private S3 bucket, a security group that allows port 80 only, and an EC2 instance running Apache. I deployed it and the page loaded.

![First version with EC2](docs/images/ec2-website.png)

Main problem here was that he page is typed into the start up script of the server, so the bucket is never used. That does not meet "store the content in an S3 bucket". I kept the file in the repo to show the first version, and I deleted the stack in AWS afterwards to avoid running cost.

### Version 2: website hosted from S3
The second template (`templates/s3-website/s3-website.yaml`) creates two things:
1. An S3 bucket with website hosting switched on. `index.html` is the home page.
2. A bucket policy that lets anyone read the files (`s3:GetObject` only).

The outputs give me the bucket name and the website address.

```
Browser  --HTTP-->  S3 website endpoint  -->  Bucket (index.html)
```

![Website hosted from S3](docs/images/s3-website.png)

### How to deploy
The region is eu-west-1 (Ireland). Run the script from the root of the repo:

```bash
./scripts/deploy.sh
```

The script validates the template, deploys the stack `lab1a-s3-website`, reads the bucket name from the stack outputs, uploads `index.html` and prints the website address. It uses the AWS CLI, so I log in first with `aws login`.

### How to delete
```bash
./scripts/destroy.sh
```

The script is based on Dhandala (2026). It does these steps:
1. Checks that the stack exists. If it does not, it says so and stops.
2. Checks that termination protection is off.
3. Shows the resources that will be deleted and asks me to type `yes`.
4. Empties the bucket, because a stack cannot delete a bucket that still has files in it.
5. Deletes the stack and waits until it is gone.

I changed three things from the article. I empty the bucket first, I read the bucket name from the stack outputs like in `deploy.sh`, and I left out the export check because my stack has no exports.

### Testing the scripts
1. I ran `destroy.sh` and typed anything but `yes`. The script cancelled and the website still loaded.
2. I ran `destroy.sh` and typed `yes`. The bucket was emptied and the stack was deleted.
3. I ran `deploy.sh` again. The site came back from the repo with one command, on a new bucket and a new address, and the header showed my L-number and name.

![Output of destroy.sh](docs/images/destroy-script.png)

## 5. Part 1b: three tier architecture

### What I built
One CloudFormation template (`templates/three-tier/three-tier.yaml`) builds a web tier, an application tier and a database tier, each in its own subnets with its own security group. I used Sofowoke (2024) as the base and kept its IP ranges, subnet layout and security group rules. I left out the parts that are not needed for a first version (see the table below). I built the template in three pull requests: network, security groups and the three tiers.

```
Internet
   |
Internet gateway
   |
Public subnets (10.10.1.0/24, 10.10.2.0/24)   <- web tier: one web server
   |
Private subnets (10.10.3.0/24, 10.10.4.0/24)  <- app tier: one server
   |
Private subnets (10.10.5.0/24, 10.10.6.0/24)  <- database tier: MySQL on RDS
```

| Tier | What it is | Subnets | Security group |
|---|---|---|---|
| Web | One `t3.micro` server running Apache. The page shows my L-number and name. | Public | Web group |
| App | One `t3.micro` server with no software | Private | App group |
| Database | MySQL 8.0 on `db.t3.micro`, 20 GB | Private (two availability zones, RDS needs this) | Database group |

### Security groups
These are the same rules as in the blog, except that I left out the bastion host.

| Group | Allows | From |
|---|---|---|
| Web | Ports 80, 22 and 3306, and ping | The internet (ping only from inside the VPC) |
| App | Port 80 | Anywhere |
| Database | Port 3306 | The web group |

### What I changed from the blog
| Area | The blog | My template | Why |
|---|---|---|---|
| NAT gateway | Yes | Left out | Costs money while it runs |
| Availability zones | Fixed to us-east-1 | Taken from the region | I work in eu-west-1 |
| Bastion host | Yes | Left out | Keeps it simple, so the app group has no SSH rule |
| Web tier | Auto scaling group behind a load balancer | One server | Keeps it simple |
| App tier | Second auto scaling group with the same Apache page | One plain server | There is no NAT gateway to install software |
| Load balancer and scaling policies | Yes | Left out | Keeps it simple |
| Server image | us-east-1 image, `amazon-linux-extras` | Current Amazon Linux 2023 image for the region, `dnf` | The blog's image does not exist in eu-west-1 |
| Instance type | `t2.micro` | `t3.micro` | `t2.micro` was not free tier eligible on my account |
| Web page | "Welcome To Swift Cart" | My L-number and name | The brief |
| Database security setting | Old `DBSecurityGroups` | `VPCSecurityGroups` | The old one is for EC2-Classic |
| Database size | `db.m6gd.large`, 15 GB | `db.t3.micro`, 20 GB | Cost, and 20 GB is the MySQL minimum |
| Database version | MySQL 8.0.35 | MySQL 8.0 | AWS picks a supported minor version |
| Outputs | None | Website address, database endpoint, app server IP, VPC ID | Easier to test |

### Known weaknesses
I list these because the brief asks me to think about security.
- Ports 22 and 3306 on the web group are open to the internet. They are open in the blog too. This needs to be reviewed
- The database password is a throwaway default in the template, because I wanted the deploy to run without typing it. The repo is public. It is a lab database that I delete after testing. A better way is to let RDS keep the password in Secrets Manager (`ManageMasterUserPassword`).
- The app group allows port 80 from anywhere, as in the blog. 

### How I deployed and deleted it
I deployed it by hand. The scripts for 1b are planned as improvements.

```bash
aws cloudformation validate-template \
  --template-body file://templates/three-tier/three-tier.yaml --region eu-west-1

aws cloudformation deploy \
  --template-file templates/three-tier/three-tier.yaml \
  --stack-name lab1b-three-tier --region eu-west-1

aws cloudformation delete-stack --stack-name lab1b-three-tier --region eu-west-1
```

### Testing
My first two deploys failed because `t2.micro` was not free tier eligible on my account. I read the error in the stack events, changed the instance type to `t3.micro` and deployed again. Then:
- The web page loaded and showed my L-number and name.
- The EC2 list showed the web and app servers running. 
- The RDS list showed the database as available.

![Web tier](docs/images/three-tier-web.png)

![App tier](docs/images/three-tier-app.png)

![Database tier](docs/images/three-tier-database.png)

## 6. Branches and pull requests

| Branch | What it did |
|---|---|
| docs/add-code-of-conduct | Code of conduct |
| feature/add-index-page | Static page with my L-number and name |
| feature/s3-bucket-template | Private S3 bucket template |
| feature/web-service | EC2 web server (first version) |
| docs/add-screenshot | Screenshot of the first version |
| feature/s3-website-hosting | Website hosted from S3 (version 2) |
| feature/deploy-script | Deploy script |
| docs/readme-v1-part-1a | README version 1 |
| docs/readme-v1.1-formatting | README formatting fix |
| feature/destroy-script | Destroy script and screenshot of the test |
| docs/readme-v2-part-1a-final | README version 2 |
| feature/three-tier-network | Part 1b network (VPC, subnets, gateway, route tables) |
| feature/three-tier-security-groups | Part 1b security groups |
| feature/three-tier-instances-and-database | Part 1b web, app and database tiers |
| docs/readme-v3-three-tier | README version 3 |

I do not delete merged branches, so the history stays visible.

## 7. Best practice 

- Every template and script has comments that explain what each part does and where it came from.
- The destroy script shows what it will delete and asks before it does anything.
- The whole site can be deleted and rebuilt from the repo with two commands
- The app and database tiers sit in private subnets with no route to the internet. Only the web tier is public.
- The three tiers are built in one template that I added to in small steps, so each pull request shows one change.
- I use feature branches and small pull requests


## 8. Still to do

- [ ] 1b improvements, one branch each: tags, deploy script, destroy script

## 9. Declarations

### Tutorials and sources I followed
| Part | Source | What I used it for |
|---|---|---|
| 1a | Mozilla (n.d.) Your first website: Creating the content | HTML structure of `index.html` |
| 1a, version 1 | Techielass (n.d.) Create an S3 Bucket using AWS CloudFormation | Bucket settings in the EC2 version |
| 1a, version 1 | AWS CloudFormation Getting started walkthrough (Amazon Web Services, n.d.c) | Web server and security group in the EC2 version |
| 1a, version 2 | Le (2025) Project: S3 Static Website with CloudFormation | Main source for `s3-website.yaml` |
| 1a, version 2 | Setting permissions for website access (Amazon Web Services, n.d.a) | Check of the bucket policy |
| 1a, version 1 and 2 | AWS::S3::Bucket (Amazon Web Services, n.d.b) | Meaning of the bucket properties |
| 1a, deploy script | Davra (2022) Deploy a website with AWS S3 + CloudFront using CloudFormation | The pattern of validating, deploying and then uploading the page |
| 1a, deploy script | AWS CLI Command Reference, `cloudformation describe-stacks` (Amazon Web Services, n.d.d) | The `--query` and `--output text` options |
| 1a, destroy script | Dhandala (2026) How to Delete CloudFormation Stacks Safely | The steps: check the stack, show what is deleted, ask, delete, wait |
| 1b | Sofowoke (2024) Building and Deploying a 3-tier Architecture with AWS CloudFormation | Base for the whole template: IP ranges, subnet layout, security group rules |

### LLM use
I used Claude (Anthropic) during this lab, as the brief allows. It explained the assignment and helped me compare/evaluate tutorials. Claude helped me on feedback for my first versions of the EC2 template, the three tier template, `deploy.sh`, `destroy.sh` and this README. I adjusted and tweaked the scripts and templates, tested them, edited the text and made all commits and pull requests myself. The decisions were mine: I chose S3 hosting, picked the sources, decided what to keep and what to leave out (CloudFront and versioning), and chose the blog for Part 1b, and planned the branches and pull requests.

### What I changed to go further than the tutorials
- Added my L-number and name to the page and to the template descriptions.
- Moved from EC2 and Apache to S3 hosting, so the bucket really stores the site.
- Wrote a deploy script that reads the bucket name from the stack outputs, stops on any error and prints the website address.
- Wrote a destroy script that empties the bucket first, asks for confirmation and waits until the stack is gone.
- Proved the rebuild: I deleted the whole site and brought it back from the repo with one command.
- For Part 1b, split the blog's single template into steps and found that its security groups and database setting do not match its own design. I listed what I changed and what is still weak.
- Took out what I did not need (NAT gateway, bastion, load balancer, auto scaling) and explained why.
- Fixed the blog's region, image and instance type so it deploys in eu-west-1, and swapped the old database security group setting for the VPC one.

## 10. References

Amazon Web Services (n.d.a) *Setting permissions for website access*. Available at: https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteAccessPermissionsReqd.html (Accessed: 15 October 2026).

Amazon Web Services (n.d.b) *AWS::S3::Bucket*. Available at: https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-s3-bucket.html (Accessed: 15 October 2026).

Amazon Web Services (n.d.c) *Walkthrough: Creating your first stack*. Available at: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/gettingstarted.walkthrough.html (Accessed: 15 October 2026).

Amazon Web Services (n.d.d) *describe-stacks*. AWS CLI Command Reference. Available at: https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html (Accessed: 15 October 2026).

Davra, N. (2022) *Deploy a website with AWS S3 + CloudFront using CloudFormation*. Canopas. Available at: https://canopas.com/deploy-a-website-with-aws-s3-cloudfront-using-cloudformation-c2199dc6c435 (Accessed: 15 October 2026).

Dhandala (2026) *How to Delete CloudFormation Stacks Safely*. OneUptime. Available at: https://oneuptime.com/blog/post/2026-02-12-delete-cloudformation-stacks-safely/view (Accessed: 16 October 2026).

Le, A. (2025) *Project: S3 Static Website with CloudFormation*. Medium. Available at: https://medium.com/@elnala24/project-s3-static-website-with-cloudformation-2253652b7405 (Accessed: 9 October 2026).

Mozilla (n.d.) *Your first website: Creating the content*. MDN Web Docs. Available at: https://developer.mozilla.org/en-US/docs/Learn_web_development/Getting_started/Your_first_website/Creating_the_content (Accessed: 15 October 2026).

Sofowoke, N. (2024) *Building and Deploying a 3-tier Architecture with AWS CloudFormation*. Medium. Available at: https://medium.com/@nifemi.sofowoke/building-and-deploying-a-3-tier-architecture-with-aws-cloudformation-415f198c1cda (Accessed: 16 October 2026).

Techielass (n.d.) *Create an S3 Bucket using AWS CloudFormation*. Available at: https://www.techielass.com/create-an-s3-bucket-using-aws-cloudformation/ (Accessed: 15 October 2026).