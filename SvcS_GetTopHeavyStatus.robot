*** Settings ***
Documentation     Compliance Top Heavy Status post-login for Partner Gateway
Force Tags        svc-compliance
...               job-compliance    pp-CI   fullClone5-db  svcS-functional2     smoketest    #execution tags
...    
Test Setup        Run Keywords  Set Database Server  Delete Cookie File 
Test Teardown     Run Keywords  Log Test Run  Data Cleanup      Delete Cookie File

Resource          ../../../config/cEnvironmentUplift.txt
Resource          ../../../queries/qCompany.txt
Resource          ../../../queries/qPlanHistory.txt
Resource          ../../../queries/qComplianceTest.txt
Resource          ../../../services/sLoginAppAuthentication.txt
Resource          ../../../services/sCompliance.txt
Resource          ../../../utils/uCookies.txt
Resource          ../../../utils/uCompany.txt

*** Variables ***
${companyCleanup}           ${EMPTY}
${topHeavyYN}               ${EMPTY}
${complianceTestStateId}    ${EMPTY}
${planYear}                 2019            #used by svc to simulate calling the svc in 2019

*** Test Cases ***

Verify Plan Admin Receives Correct Status From Compliance Url When Plan Has Undetermined Top Heavy Status
    [Tags]  Sprint-20.13  Sprint-20.14  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated 1st Year Plan With Undetermined Top Heavy Status
     When Top Heavy Status Is Called Post Login For User ${userId} And Plan ${planId} And Plan Year ${planYear}
     Then The Service Returns Correct Top Heavy Status Info for Plan Year And Previous Years

Verify Plan Admin Receives Correct Status From Compliance Url When Plan Is Top Heavy
    [Tags]  Sprint-20.13  Sprint-20.14  BETA  user-compliance
     Given A Valid Plan Admin On A Terminated Plan With Top Heavy Status
     When Top Heavy Status Is Called Post Login For User ${userId} And Plan ${planId} And Plan Year ${planYear}
     Then The Service Returns Correct Top Heavy Status Info for Plan Year And Previous Years

*** Keywords ***

##  Data Setup  ##

Convert DB Top Heavy Status To Match Json Response
    Run Keyword If        '${complianceTestStateId}'=='0'                  Set Test Variable     ${expctdTopHeavyStatus}     U
    ...      ELSE IF      '${topHeavyYN}'=='1'                             Set Test Variable     ${expctdTopHeavyStatus}     Y
    ...      ELSE         '${topHeavyYN}'=='0'                             Set Test Variable     ${expctdTopHeavyStatus}     N

A Valid Plan Admin On A Terminated 1st Year Plan With Undetermined Top Heavy Status
    [Documentation]  Plan Admin from a Terminated 1st Year Plan with Undetermined Top Heavy Status (company.pay_start_date within plan year or future); hardcoded and unique for parallelization
    Set Test Variable   ${scenario}                         undetermined
    Set Test Variable   ${companyPayStartYear}              2018                                                #used for setting up company to be 1st year plan; calling svc in 2019, so setting company.pay_start_date year to 2018
    Set Test Variable   ${expctdAppliesToPreviousYear}      true                                                #plan_year >= company.pay_start_date year = true
    Set Test Variable   ${companyId}                        <value>
    Set Test Variable   ${planId}                           <value>
    Set Test Variable   ${userId}                           <value>
    Setup Company ${companyId} To Be First Year Plan In Year ${companyPayStartYear}
    Determine Compliance Test State For Top Heavy Status For Plan ${planId} And Year ${companyPayStartYear}     #plan year compliance_test.state_id < 90 or no records OR plan year compliance_test.state_id = 90 and current year plan_history = no records, topHeavyStatus = U (Undetermined)
    Convert DB Top Heavy Status To Match Json Response
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

A Valid Plan Admin On A Terminated Plan With Top Heavy Status
    [Documentation]  Plan Admin from a Terminated plan that's Top Heavy (plan_history.top_heavy_yn = Y); hardcoded and unique for parallelization
    Set Test Variable   ${scenario}                         topHeavy
    Set Test Variable   ${expctdAppliesToPreviousYear}      false                         #company.pay_start_date < 2019 = false
    Set Test Variable   ${planId}                           <value>
    Set Test Variable   ${userId}                           <value>
    Get Plan History Top Heavy Status For Plan ${planId} and Plan Year ${planYear}        #plan year compliance_test.state_id = 90 and current year plan_history.top_heavy_yn = Y/N
    Convert DB Top Heavy Status To Match Json Response
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username

##  Action  ##

Top Heavy Status Is Called Post Login For User ${userId} And Plan ${planId} And Plan Year ${planYear}
    [Documentation]     for topHeavyStatus = Y/N, the data and svc call need to be a specific year. if we used current year to call the svc,
    ...                 it would look at compliance_test for previous year and plan_history for current year and if there aren't records in both places, topHeavyStatus = U
    User Successfully Logs In Via Service Using ${userName} And ${userPwd} For UserId ${userId}    
    Call Get Top Heavy Status Service For User ${userId} And Plan ${planId} And Plan Year ${planYear} On Gateway ${partnerGatewayUrlFront}

##  Verification  ##

The Service Returns Correct Top Heavy Status Info for Plan Year And Previous Years
    Run Keyword If  '${scenario}'=='undetermined'     Verify Service Returns Correct Info for Undetermined Top Heavy Status
    ...                                   ELSE        Verify Service Returns Correct Info for Top Heavy Y Status

Verify Service Returns Correct Info for Undetermined Top Heavy Status
    Should Contain       ${serviceResponse}   "topHeavyStatus":"${expctdTopHeavyStatus}"
    Should Contain       ${serviceResponse}   "appliesToPreviousYear":${expctdAppliesToPreviousYear}
    Should Contain       ${serviceResponse}   {"planYear":2018,"correctionAmountRequired":null,"isCorrected":null,"topHeavyCorrectionStatus":"U"}

Verify Service Returns Correct Info for Top Heavy Y Status
    Should Contain       ${serviceResponse}   "topHeavyStatus":"${expctdTopHeavyStatus}"
    Should Contain       ${serviceResponse}   "appliesToPreviousYear":${expctdAppliesToPreviousYear}
    Should Contain       ${serviceResponse}   {"planYear":2018,"correctionAmountRequired":"2926.68","isCorrected":false,"topHeavyCorrectionStatus":"Y"}
    Should Contain       ${serviceResponse}   {"planYear":2017,"correctionAmountRequired":"10109.99","isCorrected":false,"topHeavyCorrectionStatus":"Y"}
    Should Contain       ${serviceResponse}   {"planYear":2016,"correctionAmountRequired":"55236.95","isCorrected":false,"topHeavyCorrectionStatus":"Y"}
    Should Contain       ${serviceResponse}   {"planYear":2015,"correctionAmountRequired":"60030.28","isCorrected":false,"topHeavyCorrectionStatus":"Y"}
    Should Contain       ${serviceResponse}   {"planYear":2014,"correctionAmountRequired":"44309.43","isCorrected":false,"topHeavyCorrectionStatus":"Y"}

##  Teardown  ##

Delete Cookie File
    Delete Cookie File By Dir   ${CURDIR}

Data Cleanup
    Run Keyword Unless  '${companyCleanup}' == '${EMPTY}'   Company Cleanup

Company Cleanup
    Set Company ${companyId} Pay Start Date To ${currentCompanyPayStartDate}

#Useful query; p.status_date > 2015 because we may start purging terminated/transferred plans older than 7 years
#SELECT p.plan_id, p.status_date, ct.plan_year, p.authorized_rep_id, au.active_yn
#FROM plan p, compliance_test ct, app_user au
#where p.plan_id = ct.plan_id
#and p.authorized_rep_id = au.user_id
#and p.state_id = 98
#and ct.plan_year < 2018
#and au.active_yn = 1
#--and ct.state_id = 90
#and p.status_date > '01-JAN-2015';

#this query is useful for determining which years should be returned in previousYears, but it will still also depend on which years fit the below.
#plan year compliance_test.state_id < 90 or no records OR plan year compliance_test.state_id = 90 and current year plan_history = no records, topHeavyStatus = U (Undetermined)
#plan year compliance_test.state_id = 90 and current year plan_history.top_heavy_yn = Y
#if plan year compliance_test.state_id = 90 and current year plan_history.top_heavy_yn = N, it is not returned.
#
#select ct.state_id, ph.plan_year, ph.top_heavy_yn, ph.top_heavy_corrected_yn from plan_history ph, compliance_test ct
#where ph.plan_id = ct.plan_id and ph.plan_id = {planId} and ph.plan_year >= {payStartDateYear} and ph.plan_year <= {yearPassedIn-1} order by ph.plan_year desc;