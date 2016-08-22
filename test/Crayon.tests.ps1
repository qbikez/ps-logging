. "$PSScriptRoot\includes.ps1"

import-module Pester
import-module crayon

Describe "crayon module" {
    It "Should be imported" {
        gmo crayon | Should Not BeNullOrEmpty
        get-command Log-Info | Should Not BeNullOrEmpty
    }
    It "Should log" {
        { log-info "this is info" } | Should Not Throw
        { log-warn "this is warn" } | Should Not Throw
    }

    It "WithLogRedirect Should redirect log" {
        WithLogRedirect {
            $message = "this is info"
            $o = log-info $message
            $o | Should be "info: $message"
        } 
    }
}