*** Settings ***
Documentation     Compliance Get Form 5500 Filing Status post-login for Partner Gateway
...
Force Tags        svc-compliance
...               job-compliance    pp-CI   fullClone5-db  svcS-functional2     #execution tags
Test Setup        Run Keywords  Set Database Server  Delete Cookie File
Test Teardown     Run Keywords  Log Test Run  Delete Cookie File  Data Cleanup
Resource          ../../../config/cEnvironmentUplift.txt
Resource          ../../../queries/qPlan.txt
Resource          ../../../queries/qPlanParam.txt
Resource          ../../../queries/qPlanTPAFirm.txt
Resource          ../../../services/sCompliance.txt
Resource          ../../../services/sLoginAppAuthentication.txt
Resource          ../../../utils/uCookies.txt
Resource          ../../../utils/uManagePlanParam.txt
Resource          ../../../utils/uManageForm5500Filing.txt
Resource          ../../../utils/uPlan.txt
Resource          ../../../utils/uPlanTPAFirm.txt


*** Variables ***
${gateway}          ${partnerGatewayUrlFront}

*** Test Cases ***

Verify Plan Admin Receives Correct Status Info From Compliance Url
    [Tags]  Sprint-20.09  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan With Form 5500 Filing Status of Filing Received
     When Form 5500 Filing Status Service Is Called Post Login For Partner Gateway
     Then The Correct Form 5500 Filing Status Info Is Returned

*** Keywords ***

##  Data Setup  ##

A Valid Plan Admin On A Terminated Plan With Form 5500 Filing Status of Filing Received
    [Documentation]  Plan admin on a terminated plan with no records in form_5500_filing; record is created and then deleted; hardcoded and unique for parallelization.
    ...              if form_5500_filing.filing_status
    ...              = No Records and company.pay_start_date > plan year, form5500FilingStatus = Nothing Due
    ...              = NULL or no record, form5500FilingStatus = Not Ready
    ...             != Filing Received, form5500FilingStatus = Due
    ...              = Filing Received, form5500FilingStatus = Complete

    Set Test Variable  ${userId}                                          <value>
    Set Test Variable  ${planId}                                          <value>
    Set Test Variable  ${form5500FilingStatus}                            Complete
    Set Test Variable  ${nextFilingDue}                                   ${CURRENT_YEAR}

    Get Current Date in DD-MON-YY Format
    Query For Plan 208673 Status Date      #for cleanup
    Set Plan <value> Status Date To 01-JAN-${NEXT_YEAR}  #setup future plan status date; for plan.state_id in (97, 98): if year ≤ plan.status_date (98) or plan.status_date year (97), form5500FilingStatus = Complete
    Set Form 5500 Filing For Plan Year ${previousYear_gvar} And Plan 208673 With Filing Type S Filing Status Filing Received And Filing Status Date ${CurrDt_DD-MON-YY}
    Modify Form 5500 Filing For Plan <value> And Plan Year ${previousYear_gvar} Set AR Filing Offline Y And Submitter ID 770965 And Date ${CurrDt_DD-MON-YY}
    Get Form 5500 Filing Record For Plan <value> And Plan Year ${previousYear_gvar}
    Add TPA Firm <value> With TPA 5500 Prep Mode ONL For Plan <value>
    Get Plan Form 5500 TPA Prep Mode For Plan <value>
    Get Form 5500 Plan Param Dates For ${previousYear_gvar}
    Update Form 5500 Plan Params To Be Started Within 10 Days And Not Past Deadlines For Plan Year ${previousYear_gvar}
    Get New Form 5500 Plan Param Dates For ${previousYear_gvar} After Update
    Reset Password For User ID, Unlock Account And Get Username  ${userId}  ${userPwd}

##  Action  ##

Form 5500 Filing Status Service Is Called Post Login For Partner Gateway
    The User Successfully Logs In Via Service
    Call Get Form 5500 Filing Status Service For User ${userId} And Plan ${planId} On Gateway ${gateway}

##  Verification  ##

The Correct Form 5500 Filing Status Info Is Returned
    Verify Form 5500 Filing Status Info In Json Response

Verify Form 5500 Filing Status Info In Json Response
    Get Json Response  ${serviceResponse}
    ${respForm5500PublishDate}=         get json value   ${jsonResponse}    /data/form5500PublishDate
    ${respTpa5500Mode}=                 get json value   ${jsonResponse}    /data/tpa5500Mode                           #plan_tpa_firm.tpa_5500_prep_mode; default of N returned if no TPA
    ${respNextFilingDue}=               get json value   ${jsonResponse}    /data/nextFilingDue
    ${respOfflineFiling}=               get json value   ${jsonResponse}    /data/offlineFiling                         #form_5500_filing.ar_indicates_offline_yn
    ${respFilingType}=                  get json value   ${jsonResponse}    /data/filingType                            #plan_compliance.form5500_filing_type_override if E, S or L; if plan_compliance.form5500_filing_type_override = U, then form_5500_filing.filing_type
    ${respExtendedDeadlineDate}=        get json value   ${jsonResponse}    /data/extendedDeadlineDate
    ${respArIndicatesOfflineDate}=      get json value   ${jsonResponse}    /data/arIndicatesOfflineDate
    ${respExtendedFilingDueDate}=       get json value   ${jsonResponse}    /data/extendedFilingDueDate
    ${respArOfflineSubmitterId}=        get json value   ${jsonResponse}    /data/arOfflineSubmitterId
    ${respFilingStatusDate}=            get json value   ${jsonResponse}    /data/filingStatusDate                      #only populated if form_5500_filing.filing_status = Filing Received
    ${respForm5500FilingStatus}=        get json value   ${jsonResponse}    /data/form5500FilingStatus

    ${respExtendedDeadlineDate}=        Change Date Format Of Json Response And Convert To Uppercase   ${respExtendedDeadlineDate}       %m/%d/%Y    %d-%b-%y
    ${respArIndicatesOfflineDate}=      Change Date Format Of Json Response And Convert To Uppercase   ${respArIndicatesOfflineDate}     %m/%d/%Y    %d-%b-%y
    ${respExtendedFilingDueDate}=       Change Date Format Of Json Response And Convert To Uppercase   ${respExtendedFilingDueDate}      %m/%d/%Y    %d-%b-%y
    ${respFilingStatusDate}=            Change Date Format Of Json Response And Convert To Uppercase   ${respFilingStatusDate}           %m/%d/%Y    %d-%b-%y
    ${respForm5500PublishDate}=         Change Date Format Of Json Response And Convert To Uppercase   ${respForm5500PublishDate}        %m/%d/%Y    %d-%b-%y

    should be equal                 ${respTpa5500Mode}               "${tpa5500PrepMode}"
    should be equal as strings      ${respNextFilingDue}             ${nextFilingDue}
    should be equal                 ${respOfflineFiling}             "${arIndicatesOfflineYN}"
    should be equal                 ${respFilingType}                "${filingType}"
    should be equal                 ${respExtendedDeadlineDate}      ${new5500ExtDeadlineDate}
    should be equal                 ${respArIndicatesOfflineDate}    ${arIndicatesOfflineDate}
    should be equal                 ${respExtendedFilingDueDate}     ${new5500ExtFilingDate}
    should be equal as strings      ${respArOfflineSubmitterId}      ${arOfflineSubmitterId}
    should be equal                 ${respFilingStatusDate}          ${filingStatusDate}
    should be equal                 ${respForm5500FilingStatus}      "${form5500FilingStatus}"
    should be equal                 ${respForm5500PublishDate}       ${new5500PublishDate}

##  Teardown  ##

Delete Cookie File
    Delete Cookie File By Dir   ${CURDIR}

Data Cleanup
    Set Plan 208673 Status Date To ${currentPlanStatusDate}
    Delete Form 5500 Filing Status For Plan 208673 In Plan Year ${previousYear_gvar}
    Remove TPA Firm For Plan 208673
    Set 5500 Publish Date To               ${5500PublishDate}                    ${previousYear_gvar}
    Set 5500 Extended Deadline Date To     ${5500ExtDeadlineDate}                ${previousYear_gvar}
    Set 5500 Extended Filing Due Date To   ${5500ExtFilingDate}                  ${previousYear_gvar}
