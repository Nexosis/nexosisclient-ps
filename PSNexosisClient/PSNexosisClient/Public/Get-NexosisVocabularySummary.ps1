Function Get-NexosisVocabularySummary {
<# 
 .Synopsis
  Gets summary information about the Vocabulary built from the Text columns in a session.

 .Description
  Nexosis will automatically engineer features based on Feature columsn of type Text This endpoint describe
  the vocabularies that we built from the text columns in your Session.

 .Parameter DataSource
  List Vocabularies from data sources matching this string

 .Parameter CreatedFromSession
  The Session Id used to create the vocabulary.

 .Parameter Page
  Zero-based page number of session results to retrieve.

 .Parameter PageSize
  Count of session results to retrieve in each page (max 1000).

 .Example
  Get-NexosisVocabularySummary

#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $DataSource,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        [GUID]$CreatedFromSession,
        [Parameter(Mandatory=$false)]
		[int]$page=0,
		[Parameter(Mandatory=$false)]
        [int]$pageSize=$script:PSNexosisVars.DefaultPageSize
	)
    process {
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        
        if ($createdFromSession -ne $null) {
            $params['createdFromSession'] = $createdFromSession
        }

        if ($datasource -ne $null) {
            $params['datasource'] = $datasource
        }

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

        Invoke-Http -method Get -path "vocabulary" -params $params
    }
}