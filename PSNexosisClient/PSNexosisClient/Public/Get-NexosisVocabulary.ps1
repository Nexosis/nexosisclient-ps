Function Get-NexosisVocabulary {
<# 
 .Synopsis
  Gets a list of Vocabulary Words from a vocabulary

 .Description
  Nexosis will automatically engineer features based on Feature columns of type Text This endpoint returns a 
  listing of either words used as features or Stop Words (words that were in the text but not used) for a column
  of data in a session

 .Parameter VocabularyId
  The vocabulary id (UUID) to retrieve.

 .Parameter Type
  The type of word (Word or StopWord) to retrieve.

 .Parameter Page
  Zero-based page number of session results to retrieve.

 .Parameter PageSize
  Count of session results to retrieve in each page (max 1000).

 .Example
  Get-NexosisVocabulary -VocabularyId dc304a16-c3fb-491d-8e56-01ccc9c26d61 -type word

#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$VocabularyId,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $Type,
        [Parameter(Mandatory=$false)]
		[int]$page=0,
		[Parameter(Mandatory=$false)]
        [int]$pageSize=$script:PSNexosisVars.DefaultPageSize
	)
    process {
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        
        if (($null -ne $page) -and ($page -ne 0)) {
            $params['page'] = $page
        }

        if ($null -ne $pageSize) { 
            if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
                $params['pageSize'] = $pageSize
            } elseif ($script:PSNexosisVars.DefaultPageSize -ne $script:ServerDefaultPageSize) {
                $params['pageSize'] = $script:PSNexosisVars.DefaultPageSize
            }
        }

        if ($null -ne $type) {
            $params['type'] = $type
        }
        $encodedVocabularyId = [uri]::EscapeDataString($VocabularyId)
        Invoke-Http -method Get -path "vocabulary/$encodedVocabularyId" -params $params
    }
}