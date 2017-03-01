# Dedicated VPC, RDS, EC2, ELB, S3 bucket and Route53 hostnames

## Purpose

For an application that requires a stand-alone VPC
The EC2 is expected to run a public facing application exposed via ELB on HTTPS
The application requires an RDS instance for data storage
The S3 bucket is for a web application.
The web app accesses backend data on the EC2 application via the ELB


## Artficats
1. vpc module
   - Builds a VPC for the exclusive use of this application
2. app-server-with-elb module
   - Launches an RDS, EC2 and ELB for the API server
3. s3-website module
   - Configures a Route53 hostname pointing to the ELB
