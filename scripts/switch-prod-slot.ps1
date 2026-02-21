[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Status")]
param(
    [Parameter(ParameterSetName = "Switch", Mandatory = $true)]
    [ValidateSet("blue", "green")]
    [string]$Target,

    [Parameter(ParameterSetName = "Status")]
    [switch]$Status,

    [string]$IngressClassName = "nginx",
    [string]$ProdHost = "devops-lab-app-prod.localtest.me"
)

$ErrorActionPreference = "Stop"

function Step([string]$message) {
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

function Info([string]$message) {
    Write-Host "[OK] $message" -ForegroundColor Green
}

function Warn([string]$message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
}

function Get-HealthCode([string]$hostname) {
    return (curl.exe -s -o NUL -w "%{http_code}" -H "Host: $hostname" http://127.0.0.1/health)
}

function Get-LiveOwner([string]$liveHost) {
    return (kubectl get ingress -A -o jsonpath="{range .items[?(@.spec.rules[0].host=='$liveHost')]}{.metadata.namespace}{'/' }{.metadata.name}{'\n'}{end}").Trim()
}

function Get-ActiveSlot([string]$owner) {
    if ($owner -match '^devops-lab-app-prod-blue/') { return 'blue' }
    if ($owner -match '^devops-lab-app-prod-green/') { return 'green' }
    return 'unknown'
}

$blueNamespace = "devops-lab-app-prod-blue"
$greenNamespace = "devops-lab-app-prod-green"
$targetNamespace = if ($Target -eq "blue") { $blueNamespace } elseif ($Target -eq "green") { $greenNamespace } else { "" }
$otherNamespace = if ($Target -eq "blue") { $greenNamespace } elseif ($Target -eq "green") { $blueNamespace } else { "" }

Step "Pre-checks"
$requiredCommands = @("kubectl", "curl.exe")
foreach ($command in $requiredCommands) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $command"
    }
}

kubectl get ns $blueNamespace | Out-Null
kubectl get ns $greenNamespace | Out-Null
Info "Namespaces found: $blueNamespace and $greenNamespace"

if ($PSCmdlet.ParameterSetName -eq "Status") {
    Step "Live slot status"
    $owner = Get-LiveOwner -liveHost $ProdHost
    $activeSlot = Get-ActiveSlot -owner $owner

    if ([string]::IsNullOrWhiteSpace($owner)) {
        Warn "No live ingress owner found for $ProdHost"
    } else {
        Info "Live host owner: $owner"
    }

    Write-Host "Active production slot: $activeSlot" -ForegroundColor Green
    Write-Host "Live URL: http://$ProdHost"
    Write-Host "Slot URLs: http://devops-lab-app-prod-blue.localtest.me and http://devops-lab-app-prod-green.localtest.me"

    Step "Health checks"
    $liveCode = Get-HealthCode -hostname $ProdHost
    $blueCode = Get-HealthCode -hostname "devops-lab-app-prod-blue.localtest.me"
    $greenCode = Get-HealthCode -hostname "devops-lab-app-prod-green.localtest.me"
    Write-Host "- live=$liveCode blue=$blueCode green=$greenCode"
    return
}

Step "Validate target slot health"
$targetHost = "devops-lab-app-prod-$Target.localtest.me"
$targetCode = Get-HealthCode -hostname $targetHost
if ($targetCode -ne "200") {
    throw "Target slot '$Target' is not healthy (HTTP $targetCode on $targetHost)."
}
Info "Target slot '$Target' is healthy"

Step "Apply live ingress to target slot"
$tmpFile = Join-Path $env:TEMP ("prod-live-ingress-{0}.yaml" -f [guid]::NewGuid().ToString())
@"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devops-lab-app-live
  namespace: $targetNamespace
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: $IngressClassName
  rules:
    - host: $ProdHost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: devops-lab-app
                port:
                  number: 80
"@ | Set-Content -Path $tmpFile -Encoding utf8

Step "Remove conflicting ingresses for live host"
$conflicts = kubectl get ingress -A -o json | ConvertFrom-Json
$conflictItems = @($conflicts.items | Where-Object {
    $_.spec.rules -and $_.spec.rules.Count -gt 0 -and $_.spec.rules[0].host -eq $ProdHost -and
    -not ($_.metadata.namespace -eq $targetNamespace -and $_.metadata.name -eq "devops-lab-app-live")
})

foreach ($conflict in $conflictItems) {
    $conflictRef = "$($conflict.metadata.namespace)/$($conflict.metadata.name)"
    if ($PSCmdlet.ShouldProcess($conflictRef, "delete conflicting ingress for $ProdHost")) {
        kubectl -n $conflict.metadata.namespace delete ingress $conflict.metadata.name --ignore-not-found=true | Out-Null
    }
}

if ($PSCmdlet.ShouldProcess("$targetNamespace/devops-lab-app-live", "apply ingress for $ProdHost")) {
    kubectl apply -f $tmpFile | Out-Null
}

Step "Remove live ingress from inactive slot (if exists)"
if ($PSCmdlet.ShouldProcess("$otherNamespace/devops-lab-app-live", "delete ingress")) {
    kubectl -n $otherNamespace delete ingress devops-lab-app-live --ignore-not-found=true | Out-Null
}

Step "Validate live endpoint"
$liveCode = "000"
for ($i = 1; $i -le 10; $i++) {
    $liveCode = Get-HealthCode -hostname $ProdHost
    if ($liveCode -eq "200") {
        break
    }
    Start-Sleep -Seconds 2
}

if ($liveCode -ne "200") {
    Warn "Live host returned HTTP $liveCode"
} else {
    Info "Live host is healthy (HTTP 200)"
}

$owner = Get-LiveOwner -liveHost $ProdHost
if ([string]::IsNullOrWhiteSpace($owner)) {
    Warn "No ingress owner found for $ProdHost"
} else {
    Info "Live host owner: $owner"
}

Remove-Item -Force $tmpFile

Step "Done"
Write-Host "Active production slot: $Target" -ForegroundColor Green
Write-Host "Live URL: http://$ProdHost" -ForegroundColor Green
Write-Host "Slot URLs: http://devops-lab-app-prod-blue.localtest.me and http://devops-lab-app-prod-green.localtest.me"
