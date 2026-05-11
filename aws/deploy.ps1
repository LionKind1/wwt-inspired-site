# Deploy static site to AWS S3 website bucket (requires AWS CLI v2 + credentials).
# One-time: aws configure    OR    aws sso login --profile your-profile
#
# Usage (from repo root):
#   .\aws\deploy.ps1
#   .\aws\deploy.ps1 -Region us-west-2 -StackName my-static-site -Profile prod

param(
    [string]$Region = "us-east-1",
    [string]$StackName = "vertex-static-site",
    [string]$BucketName = "",
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Template = Join-Path $PSScriptRoot "cloudformation-s3-website.yaml"

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
    Write-Error "AWS credentials not found. Run: aws configure   or   aws sso login --profile <name>   then retry."
}

Write-Host "Deploying stack '$StackName' in $Region..."
$deployCmd = @(
    "cloudformation", "deploy",
    "--region", $Region,
    "--stack-name", $StackName,
    "--template-file", $Template,
    "--no-fail-on-empty-changeset"
)
if ($BucketName) {
    $deployCmd += "--parameter-overrides", "BucketName=$BucketName"
}
& aws @awsArgs @deployCmd
if ($LASTEXITCODE -ne 0) {
    Write-Error "CloudFormation deploy failed."
}

$bucket = & aws @awsArgs cloudformation describe-stacks `
    --region $Region `
    --stack-name $StackName `
    --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue | [0]" `
    --output text

if (-not $bucket -or $bucket -eq "None") {
    Write-Error "Could not read BucketName from stack outputs."
}

Write-Host "Syncing site files to s3://$bucket/ ..."
Push-Location $RepoRoot
try {
    & aws @awsArgs s3 sync . "s3://$bucket/" `
        --region $Region `
        --delete `
        --exclude ".git/*" `
        --exclude "aws/*" `
        --exclude ".cursor/*" `
        --exclude "*.md"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "s3 sync failed."
    }
}
finally {
    Pop-Location
}

$url = & aws @awsArgs cloudformation describe-stacks `
    --region $Region `
    --stack-name $StackName `
    --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue | [0]" `
    --output text

Write-Host ""
Write-Host "Done. Site URL: $url"
Write-Host "(HTTP only via S3 website endpoint; front with CloudFront + ACM for HTTPS.)"
