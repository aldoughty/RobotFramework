*** Settings ***
Documentation     Compliance Update Form 5500 Filing Settings post-login for Partner Gateway
...
Force Tags        svc-compliance 
...               job-compliance    pp-CI   fullClone5-db   svcS-functional2  #execution tags
...    
Test Setup        Run Keywords  Set Database Server  Delete Cookie File
Test Teardown     Run Keywords  Log Test Run  Delete Cookie File  Data Cleanup

Resource          ../../../config/cEnvironmentUplift.txt
Resource          ../../../services/sLoginAppAuthentication.txt
Resource          ../../../services/sCompliance.txt
Resource          ../../../utils/uCookies.txt
Resource          ../../../utils/uManageForm5500Filing.txt

*** Variables ***
${gateway}                   ${partnerGatewayUrlFront}
${planYear}                  ${previousYear_gvar}              #For service:  any digits for planYear, planId.  No blanks in ANY field.  planYear can be null, implies current year.
${filingType}                S                                 #form_5500_filing.filing_type, populating for the db insert on this test
${filingStatus}              Not Filed                         #form_5500_filing.filing_status, populating for the db insert on this test
${filingStatusDate}          01-JAN-${previousYear_gvar}       #only populated if form_5500_filing.filing_status = Filing Received, but populating here for the db insert on this test
${filingOffline}             ${EMPTY}
${extensionFiled}            ${EMPTY}

*** Test Cases ***

Verify Form 5500 Filing Settings For Extension Filed Are Set Correctly When Plan Admin Calls Set Form 5500 Settings Service
    [Tags]  Sprint-20.11  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan With A Record In Form 5500 Filing For Updating Extension Filed
     When Set Form 5500 Filing Settings Is Called Post Login For Partner Gateway
     Then The Form 5500 Filing Settings Are Updated Correctly

Verify Form 5500 Filing Settings For Filing Offline Are Set Correctly When Plan Admin Calls Set Form 5500 Settings Service
    [Tags]  Sprint-20.11  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan With A Record In Form 5500 Filing For Updating Filing Offline
     When Set Form 5500 Filing Settings Is Called Post Login For Partner Gateway
     Then The Form 5500 Filing Settings Are Updated Correctly

*** Keywords ***

##  Data Setup  ##

A Valid Plan Admin On A Terminated Plan With A Record In Form 5500 Filing For Updating Extension Filed      #User can only update extensionFiled OR filingOffline, not both.
    [Documentation]  Plan Admin On A Terminated Plan With No Records In Form 5500 Filing; record is created, updated and then deleted; hardcoded and unique for parallelization.
    Get Current Date For Form 5500 Filing
    Set Test Variable  ${scenario}                  extension
    Set Test Variable  ${userId}                    <value>                            #Only Authorized Rep, Plan Admin or TPA Filing Offline can update extensionFiled
    Set Test Variable  ${planId}                    <value>
    Set Test Variable  ${extensionFiled}            Y                                 #form_5500_filing.extension_filed_by_client_yn, must be Y or N
    Set Test Variable  ${extensionState}            30
    Set Test Variable  ${extensionStateUpdateDate}  ${CurrDt_DD-MON-YYYY}
    Data Setup

A Valid Plan Admin On A Terminated Plan With A Record In Form 5500 Filing For Updating Filing Offline       #User can only update extensionFiled OR filingOffline, not both.
    [Documentation]  Plan Admin On A Terminated Plan With No Records In Form 5500 Filing; record is created, updated and then deleted; hardcoded and unique for parallelization.
    Get Current Date For Form 5500 Filing
    Set Test Variable  ${scenario}                  offline
    Set Test Variable  ${userId}                    <value>                            #Only Authorized Rep can update filingOffline
    Set Test Variable  ${planId}                    <value>
    Set Test Variable  ${filingOffline}             Y                                 #form_5500_filing.ar_indicates_offline_yn, must be Y or N
    Set Test Variable  ${arOfflineDate}             ${CurrDt_DD-MON-YYYY}
    Data Setup

Data Setup
    Reset Password For User ID, Unlock Account And Get Username  ${userId}  ${userPwd}
    Set Form 5500 Filing For Plan Year ${planYear} And Plan ${planId} With Filing Type ${filingType} Filing Status ${filingStatus} And Filing Status Date ${filingStatusDate}

Get Current Date For Form 5500 Filing
    Get Current Date in DD-MON-YYYY Format

##  Action  ##

Set Form 5500 Filing Settings Is Called Post Login For Partner Gateway
    User Successfully Logs In Via Service Using ${userName} And ${userPwd} For UserId ${userId}     
    Log Variables
    Run Keyword If  '${scenario}'=='extension'    Call Set Form 5500 Extension Filed Setting Service For User ${userId} And Plan ${planId} And Year ${planYear} And Extension Setting ${extensionFiled} On Gateway ${gateway}
    ...                                   ELSE    Call Set Form 5500 Filing Offline Setting Service For User ${userId} And Plan ${planId} And Year ${planYear} And Filing Offline ${filingOffline} On Gateway ${gateway}
    System Responds With Status Success  ${serviceResponse}

##  Verification  ##

The Form 5500 Filing Settings Are Updated Correctly
    Run Keyword If  '${scenario}'=='extension'     Verify Form 5500 Extension Filed Settings Were Updated Correctly
    ...                                   ELSE     Verify Form 5500 Filing Offline Settings Were Updated Correctly

Verify Form 5500 Extension Filed Settings Were Updated Correctly
    [Documentation]     When form_5500_filing.extension_filed_by_client_yn is updated, also set extension_state_update_date, extension_state_update_user; and if Y, extension_state = 30, if N, extension_state = 10
    Get Extension Status For Plan ${planId} And Year ${planYear}
    should be equal as strings    ${resExtensionFiled}              ${extensionFiled}
    should be equal as strings    ${resExtensionState}              ${extensionState}
    should be equal as strings    ${resExtensionStateUpdateDate}    ${extensionStateUpdateDate}
    should be equal as strings    ${resExtensionStateUpdateUser}    ${userId}

Verify Form 5500 Filing Offline Settings Were Updated Correctly
    [Documentation]     When form_5500_filing.ar_indicates_offline_yn is updated, also set ar_offline_submitter__id, ar_indicates_offline_date
    Get Filing Offline Status For Plan ${planId} And Year ${planYear}
    should be equal as strings    ${resArFilingOffline}              ${filingOffline}
    should be equal as strings    ${resArOfflineSubmitter}           ${userId}
    should be equal as strings    ${resArOfflineDate}                ${arOfflineDate}
    should be equal as strings    ${resSubmitterUserId}              ${userId}

##  Teardown  ##

Delete Cookie File
    Delete Cookie File By Dir   ${CURDIR}

Data Cleanup
    Delete Form 5500 Filing Status For Plan ${planId} In Plan Year ${planYear}