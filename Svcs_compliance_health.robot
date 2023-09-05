*** Settings ***
Documentation     Checks the health of the Compliance service.
Force Tags        healthcheck
...               fullClone5-db  svc-compliance   job-compliance  #execution tags
Test Setup        Run Keywords     Delete Cookie File   Set Database Server
Test Teardown     Run Keywords  Log Test Run  Delete Cookie File
Resource          ../../../config/cEnvironmentUplift.txt
Resource          ../../../utils/uCookies.txt
Resource          ../../../services/sServiceBasics.txt

*** Variables ***
${status}   UP

*** Test Cases ***

Compliance Service Health Check
    [Tags]  Sprint-20.08  svc-Security  pp-CI   svcS-functional
    Verify Given Service ${complianceUrlDirect} health is status ${status}


*** Keywords ***
## WHEN  ##

## Cleanup  ##
Delete Cookie File
    Delete Cookie File By Dir   ${CURDIR}