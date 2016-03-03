. "$PSScriptRoot\includes.ps1"

import-module Pester
import-module Logging

Describe "Logging module" {
    It "Should be imported" {
        gmo Logging | Should Not BeNullOrEmpty
        get-command Log-Info | Should Not BeNullOrEmpty
    }
}