*** Settings ***
Documentation     Plan Latest APR Status Service Tests for -which users are allowed to access plan APR Status requests
...    I've set this up with hardcoded data for plans that are terminated/transferred out so that the data should be stable
...    
Force Tags        svc-Security  Sprint-20.08   svc-compliance  apr
...               pp-CI  fullClone5-db  job-svcS-applicationSecurity1  job-compliance  svcs-functional   #execution tags
...    
Test Setup        Run Keywords  Set Database Server
Test Teardown     Run Keywords   Log Test Run   Delete Cookie File

Test Template     Verify User ${userId} Receives Valid Response ${expctdResponse} When APR Status Endpoint Is Called For Plan ${planId} Via Gateway ${gateway}

Resource          ../../../config/cEnvironmentUplift.txt
Resource          ../../../services/sPlan.txt
Resource          ../../../services/sServiceMessages.txt
Resource          ../../../services/sCompliance.txt
Resource          ../../../utils/uCookies.txt

*** Variables ***
${userID}    ${EMPTY}


*** Test Cases ***                                                                                        userId       expctdResponse      planId      gateway
Participant Cannot Get APR Status For Their Plan                                                          <value>        404                 <value>        ${participantGatewayUrlFront}
Participant Cannot Get APR Status For Another Plan                                                        <value>        404                 <value>       ${participantGatewayUrlFront}

Plan Admin Can Access APR Status For A Plan They Are In                                                   <value>         Success             <value>        ${partnerGatewayURLFront}
Plan Admin Cannot Access APR Status For A Plan They Are Not In                                            <value>         E004                <value>        ${partnerGatewayURLFront}

#    [Tags]  run  #wip - this one is most consistently getting the connection reset, turning off while I dig for a solution

*** Keywords ***
## Template ##
Verify User ${userId} Receives Valid Response ${expctdResponse} When APR Status Endpoint Is Called For Plan ${planId} Via Gateway ${gateway}
    Given A User With UserId ${userId}
    When The APR Status Service Is Called For Authenticated User ${userId} And Plan ${planId} In Gateway ${gateway}
    Then The APR Status Is Available ${expctdResponse}

## GIVEN ##
A User With UserId ${userId}
    Reset Password ${userPwd} For User ID ${userId}, Unlock Account And Get Username    #using unlock since this user is hardcoded and if they get changed somewhere else and get locked we need to resolve

## Actions ##
The APR Status Service Is Called For Authenticated User ${userId} And Plan ${planId} In Gateway ${gateway}
    User Successfully Logs In Via Service Using ${userName} And ${userPwd} For UserId ${userId}     
    Call Get APR Status Service For User ${userId} And Plan ${planId} On Gateway ${gateway}

##  THEN  ##

The APR Status Is Available ${expctdResponse}
    Run Keyword If  '${expctdResponse}'=='Success'  System Responds With Status Success
    ...      ELSE IF   '${expctdResponse}'=='403'   A Failure Is Returned   403    Access is denied     ${serviceResponse}
    ...      ELSE IF   '${expctdResponse}'=='404'   A Failure Is Returned   404    Not Found            ${serviceResponse}    #This is actually a service error, the user is allowed access to the endpoint and the service is throwing the error
    ...      ELSE IF   '${expctdResponse}'=='E004'  A Failure Is Returned   E004   Authorization Error  ${serviceResponse}
    ...      ELSE        Fail  Unexpected error returned   ${serviceResponse}

## CLEANUP ##
Delete Cookie File
    Delete Cookie File By Dir   ${CURDIR}