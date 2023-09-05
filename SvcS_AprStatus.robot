*** Settings ***
Documentation     Compliance APR Status post-login for Partner Gateway
Force Tags        svc-compliance
...               job-compliance    pp-CI   fullClone5-db  svcS-functional2     #execution tags
Test Setup        Run Keywords  Set Database Server  Delete Cookie File
Test Teardown     Run Keywords  Log Test Run  Delete Cookie File  Data Cleanup
Resource          ../../../config/cEnvironmentUplift.txt
Resource          ../../../queries/qCompany.txt
Resource          ../../../queries/qPlanParam.txt
Resource          ../../../services/sLoginAppAuthentication.txt
Resource          ../../../services/sCompliance.txt
Resource          ../../../utils/uCookies.txt
Resource          ../../../utils/uCompany.txt
Resource          ../../../utils/uManagePlanParam.txt

*** Variables ***
${gateway}              ${partnerGatewayUrlFront}
${companyCleanup}       ${EMPTY}
${TestDeadlineDate}     ${EMPTY}
${TestStartDate}        ${EMPTY}

*** Test Cases ***

Verify Plan Admin Receives No APR Due Status From Compliance Url When Plan Has No APR Due
    [Tags]  Sprint-20.09  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated 1st Year Plan With No APR Due
     When APR Status Info Is Returned Post Login For Partner Gateway
     Then The Correct APR Status Info Is Returned

Verify Plan Admin Receives Due Status From Compliance Url When Plan Has APR Due
    [Tags]  Sprint-20.08  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan With APR Due
     When APR Status Info Is Returned Post Login For Partner Gateway
     Then The Correct APR Status Info Is Returned

Verify Plan Admin Receives In Progress Status From Compliance Url When Plan Has APR In Progress
    [Tags]  Sprint-20.09  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan With APR In Progress
     When APR Status Info Is Returned Post Login For Partner Gateway
     Then The Correct APR Status Info Is Returned

Verify Plan Admin Receives In Progress Status From Compliance Url When Plan Has Compliance Test In Progress
    [Tags]  Sprint-20.09  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan With Compliance Test In Progress
     When APR Status Info Is Returned Post Login For Partner Gateway
     Then The Correct APR Status Info Is Returned

Verify Plan Admin Receives Complete Status From Compliance Url When Plan Has Compliance Test Complete
    [Tags]  Sprint-20.08  BETA  user-compliance
    Given A Valid Plan Admin On A Terminated Plan With Compliance Test Complete
    When APR Status Info Is Returned Post Login For Partner Gateway
    Then The Correct APR Status Info Is Returned


*** Keywords ***

##  Data Setup  ##

A Valid Plan Admin On A Terminated 1st Year Plan With No APR Due
    [Documentation]  Plan Admin from a Terminated 1st Year Plan with No APR Due (company.pay_start_date within plan year or future); hardcoded and unique for parallelization.
    Set Test Variable  ${userId}                    1048795
    Set Test Variable  ${planId}                    240149
    Set Test Variable  ${planYear}                  ${CURRENT_YEAR}       #company.pay_start_date > plan year (year passed in - 1 OR current year - 1)
    Set Test Variable  ${TestMode}                  N                     #plan_tpa_firm.tpa_compliance_test_mode; default of N returned if no TPA.
    Set Test Variable  ${APRStatus}                 No APR Due
    Set Test Variable  ${companyId}                 209694
    Update Company Pay Start Date
    Update Plan Param Test Start And Deadline Dates To Avoid Collision With TaskList Compliance Suite
    Get APR Blocker Dates
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

A Valid Plan Admin On A Terminated Plan With APR Due
    [Documentation]  Plan Admin from a Terminated plan with APR Due (plan_review_item exists, but review_date is NULL); hardcoded and unique for parallelization.
    Set Test Variable  ${userId}                    1030087
    Set Test Variable  ${planId}                    239512
    Set Test Variable  ${planYear}                  ${CURRENT_YEAR}       #plan year (year passed in - 1 OR current year - 1)
    Set Test Variable  ${TestMode}                  N                     #plan_tpa_firm.tpa_compliance_test_mode; default of N returned if no TPA.
    Set Test Variable  ${APRStatus}                 Due
    Update Plan Param Test Start And Deadline Dates To Avoid Collision With TaskList Compliance Suite
    Get APR Blocker Dates
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

A Valid Plan Admin On A Terminated Plan With APR In Progress
    [Documentation]  Plan Admin from a Terminated plan with no Compliance Test, but APR In Progress (plan_review_item exists with at least 1 review_date not NULL); hardcoded and unique for parallelization.
    Set Test Variable  ${userId}                    <value>
    Set Test Variable  ${planId}                    <value>
    Set Test Variable  ${planYear}                  ${CURRENT_YEAR}       #plan year (year passed in - 1 OR current year - 1)
    Set Test Variable  ${testMode}                  N                     #plan_tpa_firm.tpa_compliance_test_mode; default of N returned if no TPA.
    Set Test Variable  ${aprStatus}                 In Progress
    Update Plan Param Test Start And Deadline Dates To Avoid Collision With TaskList Compliance Suite
    Get APR Blocker Dates
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

A Valid Plan Admin On A Terminated Plan With Compliance Test In Progress
    [Documentation]  Plan Admin from a Terminated plan with Compliance Test In Progress (compliance_test.state_id < 90); hardcoded and unique for parallelization.
    Set Test Variable  ${userId}                    <value>
    Set Test Variable  ${planId}                    <value>
    Set Test Variable  ${planYear}                  ${CURRENT_YEAR}       #plan year (year passed in - 1 OR current year - 1)
    Set Test Variable  ${TestMode}                  N                     #plan_tpa_firm.tpa_compliance_test_mode; default of N returned if no TPA.
    Set Test Variable  ${APRStatus}                 In Progress
    Update Plan Param Test Start And Deadline Dates To Avoid Collision With TaskList Compliance Suite
    Get APR Blocker Dates
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

A Valid Plan Admin On A Terminated Plan With Compliance Test Complete
    [Documentation]  Plan Admin from a Terminated plan with Compliance Test Complete (compliance_test.state_id = 90); hardcoded and unique for parallelization.
    Set Test Variable  ${userId}                    <value>
    Set Test Variable  ${planId}                    <value>
    Set Test Variable  ${planYear}                  ${CURRENT_YEAR}       #plan year (year passed in - 1 OR current year - 1)
    Set Test Variable  ${TestMode}                  N                     #plan_tpa_firm.tpa_compliance_test_mode; default of N returned if no TPA.
    Set Test Variable  ${APRStatus}                 Complete
    Update Plan Param Test Start And Deadline Dates To Avoid Collision With TaskList Compliance Suite
    Get APR Blocker Dates
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

Update Plan Param Test Start And Deadline Dates To Avoid Collision With TaskList Compliance Suite
    [Documentation]     this svc suite does not care what the plan_param apr blocker dates are.  it (used to) just get them from the db and verify the svc returns the correct values.
    ...                 the ui TaskList_Compliance suite has to update the blocker dates bc the card won't display if they're not set correctly.  bc this svc suite is running at the same
    ...                 time as the ui suite, it was failing sometimes bc the svc suite got the dates and ui suite updated the dates and then the svc suite verified the dates and failed
    ...                 bc they'd changed.  the ui suite adjusts plan_param.test_start_date to current + 1 day in 5 scns and current - 1 day in 1 scn and it always sets test_deadline_date
    ...                 to last day of year if current date >= current plan_param.test_deadline_date.  adding this keyword to the svc suite to cover the majority of the failure potential.
    ...                 noting this bc if the jenkins run configuration changes in the future, this keyword might be unnecessary and could be removed.
    Check If End Of The Year And Adjust Dates
    Set Test Start Date To This Many Days Ago For Year              1   ${previousYear_gvar}

Check If End Of The Year And Adjust Dates
    Get Current Date in DD-MON-YY Format
    ${currentDayGreaterThanOrEqual}=    Run Keyword And Return Status    Should Be True    '${CurrDt_DD-MON-YY}' >= '${TestDeadlineDate}'
    run keyword if  ${currentDayGreaterThanOrEqual} == 'True'   Set APR Deadline Date To Last Day Of Year  ${previousYear_gvar}

##  Action  ##

APR Status Info Is Returned Post Login For Partner Gateway
    The User Successfully Logs In Via Service
    Call Get APR Status Service For ${userId} And Plan ${planId} And Year ${planYear} On Gateway ${gateway}

Update Company Pay Start Date
    [Documentation]  setup as a 1st year plan; company.pay_start_date = future date
    Set Test Variable  ${companyCleanup}    TRUE
    Query For Company Pay Start Date For ${companyId}
    Set Company ${companyId} Pay Start Date To 01-JAN-${NEXT_YEAR}

##  Verification  ##

The Correct APR Status Info Is Returned
    Verify APR Status Info In Json Response

Verify APR Status Info In Json Response
    Get Json Response  ${serviceResponse}
    ${respTestStartDate}=               get json value   ${jsonResponse}    /data/testStartDate
    ${respTestMode}=                    get json value   ${jsonResponse}    /data/testMode
    ${respCorrectionsDeadline}=         get json value   ${jsonResponse}    /data/correctionsDeadline
    ${respTestPenaltyDate}=             get json value   ${jsonResponse}    /data/testPenaltyDate
    ${respTestDeadlineDate}=            get json value   ${jsonResponse}    /data/testDeadlineDate
    ${respTestDistDate}=                get json value   ${jsonResponse}    /data/testDistDate
    ${respAprStatus}=                   get json value   ${jsonResponse}    /data/aprStatus

    ${respTestStartDate}=               Change Date Format Of Json Response And Convert To Uppercase   ${respTestStartDate}            %m/%d/%Y    %d-%b-%y
    ${respCorrectionsDeadline}=         Change Date Format Of Json Response And Convert To Uppercase   ${respCorrectionsDeadline}      %m/%d/%Y    %d-%b-%y
    ${respTestPenaltyDate}=             Change Date Format Of Json Response And Convert To Uppercase   ${respTestPenaltyDate}          %m/%d/%Y    %d-%b-%y
    ${respTestDeadlineDate}=            Change Date Format Of Json Response And Convert To Uppercase   ${respTestDeadlineDate}         %m/%d/%Y    %d-%b-%y
    ${respTestDistDate}=                Change Date Format Of Json Response And Convert To Uppercase   ${respTestDistDate}             %m/%d/%Y    %d-%b-%y

    should be equal    ${respTestStartDate}             ${TestStartDate}
    should be equal    ${respTestMode}                  "${TestMode}"
    should be equal    ${respCorrectionsDeadline}       ${APRCorrectionsDate}
    should be equal    ${respTestPenaltyDate}           ${APRPenaltyDate}
    should be equal    ${respTestDeadlineDate}          ${TestDeadlineDate}
    should be equal    ${respTestDistDate}              ${APRDistDate}
    should be equal    ${respAprStatus}                 "${APRStatus}"

##  Teardown  ##

Delete Cookie File
    Delete Cookie File By Dir   ${CURDIR}

Data Cleanup
    Run Keyword Unless  '${companyCleanup}' == '${EMPTY}'   Company Cleanup
    Reset Plan Params Back To Original Dates For APR Blocker

Reset Plan Params Back To Original Dates For APR Blocker
    Set Test Start Date To                                      ${TestStartDate}            ${previousYear_gvar}
    Set APR Deadline Date To                                    ${TestDeadlineDate}         ${previousYear_gvar}

Company Cleanup
    Set Company ${companyId} Pay Start Date To ${currentCompanyPayStartDate}