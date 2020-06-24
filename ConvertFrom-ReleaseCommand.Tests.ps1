Set-StrictMode -Version Latest

Describe 'ConvertFrom-ReleaseCommand' {
    It "Given bump='<bump>', tag='<tag>' and latest release '<apiTag>', returns tag '<nextTag>'." -TestCases @(
        @{ apiTag = 'v2.2.2'; nextTag = "v2.2.3"; title = "Simple release name" }
        @{ apiTag = 'v2.2.2'; bump = 'minor'; nextTag = "v2.3.0"; title = "Minor release name" }
        @{ apiTag = 'v2.2.2'; bump = 'major'; nextTag = "v3.0.0"; title = "Major release name" }
        @{ apiTag = 'v2.2.2'; tag = 'v4.0.0'; bump = 'major'; nextTag = "v4.0.0"; title = "Manual release name ignores bump" }
    ) {
        Mock Invoke-RestMethod {
            param([string]$StatusCodeVariable)
            Set-Variable -Name $StatusCodeVariable -Value 200 -Scope script
            return @{ tag_name = $apiTag }
        }
        $cmdArgs = @{
            Repository  = 'test/test'
            CommentBody = "/release`n$title"
            Bump        = $bump
            NextTag     = $tag
        }
        $result = .\ConvertFrom-ReleaseCommand.ps1 @cmdArgs
        $result | Should -BeOfType [hashtable]
        $result.tag | Should -Be $nextTag
        $result.name | Should -Be $title
        $result.body | Should -Be "Full changelog: https://github.com/test/test/compare/$apiTag...$nextTag"
    }

    It "Given api code <apiCode>, bump='<bump>', tag='<tag>', returns tag '<nextTag>'." -TestCases @(
        @{ apiCode = 404; nextTag = "v1.0.0"; title = "First release name" }
        @{ apiCode = 404; nextTag = "v1.0.0"; title = "First release name" }
        @{ apiCode = 404; nextTag = "v1.0.0"; title = "First release name" }
        @{ apiCode = 404; tag = 'v2.3.5'; nextTag = "v2.3.5"; title = "Manual release name" }
        @{ apiCode = 404; bump = 'minor'; nextTag = "v1.0.0"; title = "First release name" }
        @{ apiCode = 404; bump = 'major'; nextTag = "v1.0.0"; title = "First release name" }
    ) {
        Mock Invoke-RestMethod {
            param([string]$StatusCodeVariable)
            Set-Variable -Name $StatusCodeVariable -Value $apiCode -Scope script
            return @{ tag_name = $apiTag }
        }
        $cmdArgs = @{
            Repository  = 'test/test'
            CommentBody = "/release`n$title"
            Bump        = $bump
            NextTag     = $tag
        }
        $result = .\ConvertFrom-ReleaseCommand.ps1 @cmdArgs
        $result | Should -BeOfType [hashtable]
        $result.tag | Should -Be $nextTag
        $result.name | Should -Be $title
        $result.body | Should -BeNullOrEmpty
    }
}