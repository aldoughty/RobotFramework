*** Settings ***
Documentation     Compliance Get Form 5500 Filing Permissions post-login for Partner Gateway
...
Force Tags        svc-compliance  svcS-functional2  
...               job-compliance    pp-CI   fullClone5-db  #execution tags
...    
Test Setup        Run Keywords  Set Database Server  Delete Cookie File
Test Teardown     Run Keywords  Log Test Run  Delete Cookie File

Resource          ../../../config/cEnvironmentUplift.txt
Resource          ../../../services/sLoginAppAuthentication.txt
Resource          ../../../services/sCompliance.txt
Resource          ../../../utils/uCookies.txt
Resource          ../../../utils/uPwdReset.txt

*** Variables ***
${gateway}          ${partnerGatewayUrlFront}
${companyCleanup}   ${EMPTY}

*** Test Cases ***

Verify Plan Admin Receives Correct Form 5500 Filing Permissions From Compliance Url
    [Tags]  Sprint-20.11  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan
     When Form 5500 Filing Permissions Service Is Called Post Login For Partner Gateway
     Then The Correct Form 5500 Filing Permissions Info Is Returned

*** Keywords ***

##  Data Setup  ##

A Valid Plan Admin On A Terminated Plan
    [Documentation]  Plan admin who is also an authorized rep on a terminated plan; hardcoded and unique for parallelization
    Set Test Variable  ${userId}                     <value>        #Variable can be removed if/when we remove Add/Remove Uplift Beta Option
    Set Test Variable  ${5500ExtensionEdit}          true           #Only Authorized Rep, Plan Admin or TPA Filing Offline can update extensionFiled
    Set Test Variable  ${5500FilingEdit}             true           #Only Authorized Rep can update filingOffline
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

##  Action  ##

Form 5500 Filing Permissions Service Is Called Post Login For Partner Gateway
    User Successfully Logs In Via Service Using ${userName} And ${userPwd} For UserId ${userId} 
    Call Get Form 5500 Filing Permissions For User ${userId} And Plan 199553 And Gateway ${partnerGatewayUrlFront}

##  Verification  ##

The Correct Form 5500 Filing Permissions Info Is Returned
    get json response    ${serviceResponse}

    ${respForm5500ExtensionEdit}=         get json value   ${jsonResponse}    /data/permissions/FORM_5500_EXTENSION_EDIT
    ${respForm5500FilingEdit}=            get json value   ${jsonResponse}    /data/permissions/FORM_5500_FILING_EDIT

    should be equal    ${respForm5500ExtensionEdit}       ${5500ExtensionEdit}
    should be equal    ${respForm5500FilingEdit}          ${5500FilingEdit}

##  Teardown  ##

Delete Cookie File
    Delete Cookie File By Dir   ${CURDIR}
