#!/usr/bin/env pwsh

[CmdletBinding()]
param (
  [Parameter(Mandatory)]
  [string]$Repository,

  [Parameter()]
  [AllowNull()]
  [AllowEmptyString()]
  [ValidateSet('', 'minor', 'major')]
  [string]$Bump,

  [Parameter()]
  [AllowNull()]
  [AllowEmptyString()]
  [string]$NextTag,

  [Parameter()]
  [string]$CommentBody
)

$latestArgs = @{
  Uri                = "https://api.github.com/repos/$Repository/releases/latest"
  StatusCodeVariable = 'statusCode'
  SkipHttpErrorCheck = $true
}
$latest = Invoke-RestMethod @latestArgs
if ($statusCode -eq 200) {
  $prev = $latest.tag_name
  if (-not $NextTag) {
    $v = [semver]($prev -replace '^v', '')
    $major, $minor, $patch = if ($Bump -eq 'major') {
      ($v.Major + 1), 0, 0
    }
    elseif ($Bump -eq 'minor') {
      $v.Major, ($v.Minor + 1), 0
    }
    else {
      $v.Major, $v.Minor, ($v.Patch + 1)
    }
    $bumped = [semver]::new($major, $minor, $patch, $v.PreReleaseLabel, $v.BuildLabel)
    $NextTag = "v$bumped"
  }
}
else {
  $NextTag = $NextTag ? $NextTag : 'v1.0.0'
}

# get lines following command line
$lines = $CommentBody -split '\r?\n' | Select-Object -Skip 1
# get first non-empty line
$name = $lines | Where-Object { $_ } | Select-Object -First 1
if (-not $name) {
  throw "Cannot create a release without a name, please provide release name in a line after command."
}
$rest = $lines | Select-Object -Skip ($lines.IndexOf($name) + 1)
$body = "$($rest -join "`n")".Trim()
# append changelog link if there was a previous tag
if ($prev) {
  $uriOldTag = [uri]::EscapeDataString($prev)
  $uriNewTag = [uri]::EscapeDataString($NextTag)
  $changelog = "Full changelog: https://github.com/$Repository/compare/$uriOldTag...$uriNewTag"
  $body = "$($body + "`n`n" + $changelog)".Trim()
}
return @{
  tag  = "$NextTag".Trim()
  name = "$name".Trim()
  body = "$body".Trim()
}