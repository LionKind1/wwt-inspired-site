# Deploy CloudFront for the existing S3 static website.
# Run this after the ACM certificate status is ISSUED.
#
# Usage:
#   .\aws\deploy-cloudfront.ps1 -Profile magnis-test -CertificateArn arn:aws:acm:us-east-1:...

param(
    [string]$Region = "us-east-1",
    [string]$S3StackName = "vertex-static-site",
    [string]$CloudFrontStackName = "magnisapp-cloudfront",
    [string]$DomainName = "magnisapp.com",
    [string]$WwwDomainName = "www.magnisapp.com",
    [Parameter(Mandatory = $true)]
    [string]$CertificateArn,
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"
$Template = Join-Path $PSScriptRoot "cloudformation-cloudfront.yaml"

if (-not (Test-Path $Template)) {
    Write-Error "Missing template: $Template"
}

$awsArgs = @()
if ($Profile) {
    $awsArgs += "--profile", $Profile
}

Write-Host "Checking AWS credentials..."
& aws @awsArgs sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "AWS credentials not found."
}

$bucket = & aws @awsArgs cloudformation describe-stacks `
    --region $Region `
    --stack-name $S3StackName `
    --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue | [0]" `
    --output text

if (-not $bucket -or $bucket -eq "None") {
    Write-Error "Could not read BucketName from S3 stack '$S3StackName'."
}

$originDomain = "$bucket.s3-website-$Region.amazonaws.com"

Write-Host "Deploying CloudFront stack '$CloudFrontStackName'..."
& aws @awsArgs cloudformation deploy `
    --region us-east-1 `
    --stack-name $CloudFrontStackName `
    --template-file $Template `
    --no-fail-on-empty-changeset `
    --parameter-overrides `
        DomainName=$DomainName `
        WwwDomainName=$WwwDomainName `
        AcmCertificateArn=$CertificateArn `
        OriginDomainName=$originDomain

if ($LASTEXITCODE -ne 0) {
    Write-Error "CloudFront stack deploy failed."
}

$distributionDomain = & aws @awsArgs cloudformation describe-stacks `
    --region us-east-1 `
    --stack-name $CloudFrontStackName `
    --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue | [0]" `
    --output text

$distributionId = & aws @awsArgs cloudformation describe-stacks `
    --region us-east-1 `
    --stack-name $CloudFrontStackName `
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue | [0]" `
    --output text

Write-Host ""
Write-Host "CloudFront deployed."
Write-Host "Distribution ID: $distributionId"
Write-Host "DNS target: $distributionDomain"
Write-Host ""
Write-Host "Hostinger DNS:"
Write-Host "  www CNAME -> $distributionDomain"
Write-Host "  apex/root -> use ALIAS/ANAME/CNAME flattening to $distributionDomain if Hostinger supports it."
Write-Host "  If not supported, forward magnisapp.com to https://www.magnisapp.com or move DNS to Route 53."
